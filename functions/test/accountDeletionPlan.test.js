'use strict';

const plan = require('../src/accountDeletionPlan');

// The executor (accountDeletion.js) is thin glue over the Firestore/
// Storage/Auth SDKs and is exercised end-to-end against the emulator in
// tool/security-rules-tests. These tests lock down the *policy* — the one
// thing that is easy to get subtly wrong on a later edit.

describe('account deletion plan — coverage & policy', () => {
  const allDeleteTargets = [
    ...plan.DELETE_DOC_BY_UID,
    ...plan.DELETE_RECURSIVE_DOC_BY_UID,
    ...plan.DELETE_BY_FIELD.map((e) => e.collection),
    ...plan.DELETE_RECURSIVE_BY_FIELD.map((e) => e.collection),
  ];
  const allAnonTargets = [
    ...plan.ANONYMISE_BY_FIELD.map((e) => e.collection),
    ...plan.ANONYMISE_GROUP_BY_FIELD.map((e) => e.group),
  ];

  it('deletes the primary identity documents', () => {
    for (const c of ['users', 'public_profiles', 'email_otps']) {
      expect(plan.DELETE_DOC_BY_UID).toContain(c);
    }
  });

  it('deletes uploaded verification data (docs + hashes) recursively', () => {
    expect(
      plan.DELETE_RECURSIVE_BY_FIELD.some((e) => e.collection === 'verification_requests'),
    ).toBe(true);
    expect(
      plan.DELETE_BY_FIELD.some((e) => e.collection === 'verification_document_hashes'),
    ).toBe(true);
  });

  it('recurses into fan-out collections so subcollections cannot orphan', () => {
    const recursive = plan.DELETE_RECURSIVE_BY_FIELD.map((e) => e.collection);
    expect(recursive).toEqual(
      expect.arrayContaining(['college_questions', 'placement_submissions']),
    );
  });

  it('anonymises rather than deletes reviews (keeps the college score)', () => {
    const reviews = plan.ANONYMISE_BY_FIELD.find((e) => e.collection === 'reviews');
    expect(reviews).toBeDefined();
    expect(reviews.field).toBe('userId');
    expect(reviews.patch.userId).toBe(plan.ANON.uid);
    expect(reviews.patch.isAnonymous).toBe(true);
    // textReview / pros / cons are NOT in the patch — the college feedback
    // itself is retained, only the author identity is scrubbed.
    expect(reviews.patch).not.toHaveProperty('textReview');
  });

  it('anonymises consultation ratings but blanks the free-text comment', () => {
    const r = plan.ANONYMISE_BY_FIELD.find((e) => e.collection === 'consultation_ratings');
    expect(r.patch.comment).toBe('');
    expect(r.patch.raterId).toBe(plan.ANON.uid);
    // The numeric scores are left untouched (they feed the guide average).
    expect(r.patch).not.toHaveProperty('overall');
  });

  it('anonymises answers and replies on other users’ questions', () => {
    const groups = plan.ANONYMISE_GROUP_BY_FIELD.map((e) => e.group);
    expect(groups).toEqual(expect.arrayContaining(['answers', 'replies']));
    for (const g of plan.ANONYMISE_GROUP_BY_FIELD) {
      expect(g.field).toBe('authorId');
      expect(g.patch.authorDisplayName).toBe(plan.ANON.name);
    }
  });

  it('NEVER deletes or anonymises financial source-of-truth', () => {
    for (const retained of ['consultations', 'payments']) {
      expect(allDeleteTargets).not.toContain(retained);
      expect(allAnonTargets).not.toContain(retained);
    }
  });

  it('a collection is never both deleted and anonymised', () => {
    const overlap = allDeleteTargets.filter((c) => allAnonTargets.includes(c));
    expect(overlap).toEqual([]);
  });

  it('storage prefixes cover every per-user tree and are uid-scoped', () => {
    const prefixes = plan.storagePrefixesForUid('user123');
    expect(prefixes).toEqual(
      expect.arrayContaining([
        'verification_documents/user123/',
        'profile_images/user123/',
        'review_media/user123/',
      ]),
    );
    for (const p of prefixes) {
      expect(p.endsWith('/')).toBe(true);
      expect(p).toContain('user123/');
    }
    expect(() => plan.storagePrefixesForUid('')).toThrow();
  });

  it('aiUsage range is a documentId prefix scan for `${uid}_`', () => {
    const { start, end } = plan.aiUsageIdRange('user123');
    expect(start).toBe('user123_');
    expect(end.startsWith('user123_')).toBe(true);
    expect(end > start).toBe(true); // high sentinel sorts after any date
    expect(() => plan.aiUsageIdRange('')).toThrow();
  });

  it('every DELETE_BY_FIELD / *_BY_FIELD entry names a collection and field', () => {
    for (const e of [...plan.DELETE_BY_FIELD, ...plan.DELETE_RECURSIVE_BY_FIELD]) {
      expect(typeof e.collection).toBe('string');
      expect(e.collection.length).toBeGreaterThan(0);
      expect(typeof e.field).toBe('string');
      expect(e.field.length).toBeGreaterThan(0);
    }
    for (const e of plan.ANONYMISE_BY_FIELD) {
      expect(typeof e.collection).toBe('string');
      expect(typeof e.field).toBe('string');
      expect(e.patch && typeof e.patch).toBe('object');
    }
  });
});
