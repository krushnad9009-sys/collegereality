'use strict';

const {
  assertOwnedStoragePath,
  assertPublicHttpUrl,
  isPrivateIpv4,
} = require('../src/util/safeFetch');

describe('assertOwnedStoragePath', () => {
  const roots = ['verification_documents'];

  it('accepts a path under the owner’s own folder', () => {
    expect(
      assertOwnedStoragePath('verification_documents/userA/doc.jpg', 'userA', roots),
    ).toBe('verification_documents/userA/doc.jpg');
    // leading slash tolerated
    expect(
      assertOwnedStoragePath('/verification_documents/userA/doc.jpg', 'userA', roots),
    ).toBe('verification_documents/userA/doc.jpg');
  });

  it('rejects another user’s folder (the IDOR)', () => {
    expect(() =>
      assertOwnedStoragePath('verification_documents/victimB/id.jpg', 'userA', roots),
    ).toThrow(/does not belong/i);
  });

  it('rejects a different root, traversal, and junk', () => {
    expect(() =>
      assertOwnedStoragePath('resumes/userA/cv.pdf', 'userA', roots),
    ).toThrow();
    expect(() =>
      assertOwnedStoragePath('verification_documents/userA/../victimB/x', 'userA', roots),
    ).toThrow(/invalid/i);
    expect(() => assertOwnedStoragePath('', 'userA', roots)).toThrow();
    expect(() => assertOwnedStoragePath('verification_documents', 'userA', roots)).toThrow();
  });
});

describe('assertPublicHttpUrl', () => {
  it('accepts a normal public https URL and adds a scheme', () => {
    expect(assertPublicHttpUrl('https://www.iitb.ac.in/').hostname).toBe('www.iitb.ac.in');
    expect(assertPublicHttpUrl('iitb.ac.in').protocol).toBe('https:');
  });

  it('blocks SSRF targets', () => {
    for (const bad of [
      'http://localhost/',
      'http://127.0.0.1/',
      'http://127.0.0.1:8080/admin',
      'http://169.254.169.254/computeMetadata/v1/',
      'http://metadata.google.internal/',
      'http://10.0.0.5/',
      'http://192.168.1.1/',
      'http://172.16.0.9/',
      'http://internal-api.internal/',
      'http://[::1]/',
      'ftp://example.com/',
      'file:///etc/passwd',
      'gopher://x',
    ]) {
      expect(() => assertPublicHttpUrl(bad)).toThrow();
    }
  });
});

describe('isPrivateIpv4', () => {
  it('classifies ranges', () => {
    for (const ip of ['10.1.2.3', '127.0.0.1', '169.254.1.1', '172.31.255.1', '192.168.0.1', '0.0.0.0', '100.64.0.1']) {
      expect(isPrivateIpv4(ip)).toBe(true);
    }
    for (const ip of ['8.8.8.8', '1.1.1.1', '172.32.0.1', '11.0.0.1', 'not-an-ip']) {
      expect(isPrivateIpv4(ip)).toBe(false);
    }
  });
});
