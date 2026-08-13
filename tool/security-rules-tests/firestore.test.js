import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-college-reality';
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

let testEnv;

async function seed(data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [path, value] of Object.entries(data)) {
      await setDoc(doc(db, path), value);
    }
  });
}

function authDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

const safeUser = {
  uid: 'student1',
  email: 'student1@example.com',
  userType: 'student',
  verificationBadge: 'none',
  verificationStatus: 'incomplete',
  isVerified: false,
  collegeId: 'college-a',
  guideStats: {
    totalRatings: 0,
    overallRating: 0,
    badgeTier: 'none',
    totalCalls: 0,
    totalChats: 0,
    helpfulPercent: 0,
    respectfulPercent: 0,
    recommendPercent: 0,
  },
  communicationSettings: {
    isGuideAvailable: false,
    allowPublicProfile: false,
  },
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('C1 user create privilege escalation', () => {
  it('allows safe student create', async () => {
    await assertSucceeds(setDoc(doc(authDb('student1'), 'users/student1'), safeUser));
  });

  it('denies self-granting verified badge on create', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'users/student1'), {
        ...safeUser,
        verificationBadge: 'verified_student',
        verificationStatus: 'approved',
        isVerified: true,
      }),
    );
  });

  it('denies creating admin userType', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'users/student1'), {
        ...safeUser,
        userType: 'admin',
      }),
    );
  });
});

describe('C2 college aggregate updates', () => {
  beforeEach(async () => {
    await seed({
      'users/verified1': {
        ...safeUser,
        uid: 'verified1',
        verificationBadge: 'verified_student',
        verificationStatus: 'approved',
        isVerified: true,
      },
      'users/attacker': { ...safeUser, uid: 'attacker' },
      'colleges/college-a': { name: 'A', reviewCount: 2 },
    });
  });

  it('allows verified student ±1 reviewCount aggregate update', async () => {
    await assertSucceeds(
      updateDoc(doc(authDb('verified1'), 'colleges/college-a'), {
        reviewCount: 3,
        aggregatedRatings: { academics: 4 },
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies arbitrary reviewCount jumps', async () => {
    await assertFails(
      updateDoc(doc(authDb('verified1'), 'colleges/college-a'), {
        reviewCount: 999,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies unverified aggregate updates', async () => {
    await assertFails(
      updateDoc(doc(authDb('attacker'), 'colleges/college-a'), {
        reviewCount: 3,
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('C3 guideStats updates', () => {
  beforeEach(async () => {
    await seed({
      'users/guide1': {
        ...safeUser,
        uid: 'guide1',
        guideStats: {
          totalRatings: 1,
          overallRating: 4,
          badgeTier: 'none',
          totalCalls: 1,
          totalChats: 0,
          helpfulPercent: 100,
          respectfulPercent: 100,
          recommendPercent: 100,
        },
      },
      'users/rater1': { ...safeUser, uid: 'rater1' },
    });
  });

  it('allows bounded +1 ratings update by another user', async () => {
    await assertSucceeds(
      updateDoc(doc(authDb('rater1'), 'users/guide1'), {
        guideStats: {
          totalRatings: 2,
          overallRating: 4.5,
          badgeTier: 'bronze',
          totalCalls: 2,
          totalChats: 0,
          helpfulPercent: 100,
          respectfulPercent: 100,
          recommendPercent: 100,
          lastActiveAt: new Date().toISOString(),
        },
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies arbitrary guideStats inflation', async () => {
    await assertFails(
      updateDoc(doc(authDb('rater1'), 'users/guide1'), {
        guideStats: {
          totalRatings: 500,
          overallRating: 5,
          badgeTier: 'gold',
          totalCalls: 500,
          totalChats: 500,
          helpfulPercent: 100,
          respectfulPercent: 100,
          recommendPercent: 100,
        },
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies self rating inflation via guideStats', async () => {
    await assertFails(
      updateDoc(doc(authDb('guide1'), 'users/guide1'), {
        guideStats: {
          totalRatings: 2,
          overallRating: 5,
          badgeTier: 'gold',
          totalCalls: 2,
          totalChats: 0,
          helpfulPercent: 100,
          respectfulPercent: 100,
          recommendPercent: 100,
        },
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('C4 helpfulCount updates', () => {
  beforeEach(async () => {
    await seed({
      'users/voter1': { ...safeUser, uid: 'voter1' },
      'reviews/review1': {
        userId: 'author1',
        helpfulCount: 1,
        isVerifiedStudent: true,
      },
    });
  });

  it('allows +1 helpfulCount when creating helpful vote in same batch', async () => {
    const db = authDb('voter1');
    const batch = writeBatch(db);
    batch.set(doc(db, 'reviews/review1/helpful/voter1'), {
      userId: 'voter1',
      createdAt: new Date().toISOString(),
    });
    batch.update(doc(db, 'reviews/review1'), {
      helpfulCount: 2,
      updatedAt: new Date().toISOString(),
    });
    await assertSucceeds(batch.commit());
  });

  it('denies helpfulCount update without coupled helpful vote create', async () => {
    await assertFails(
      updateDoc(doc(authDb('voter1'), 'reviews/review1'), {
        helpfulCount: 2,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies large helpfulCount jumps', async () => {
    const db = authDb('voter1');
    const batch = writeBatch(db);
    batch.set(doc(db, 'reviews/review1/helpful/voter1'), {
      userId: 'voter1',
      createdAt: new Date().toISOString(),
    });
    batch.update(doc(db, 'reviews/review1'), {
      helpfulCount: 999,
      updatedAt: new Date().toISOString(),
    });
    await assertFails(batch.commit());
  });
});

describe('C6 bootstrap / seed lockdown', () => {
  beforeEach(async () => {
    await seed({
      'users/student1': safeUser,
    });
  });

  it('denies authenticated college create', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'colleges/new-college'), {
        name: 'Injected',
      }),
    );
  });

  it('denies authenticated _meta create', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), '_meta/collegesSeeded'), {
        seededAt: new Date().toISOString(),
      }),
    );
  });

  it('denies authenticated scholarship seed create', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'scholarships/s1'), { title: 'x' }),
    );
  });
});

describe('H1 collegeId lock while approved', () => {
  beforeEach(async () => {
    await seed({
      'users/verified1': {
        ...safeUser,
        uid: 'verified1',
        verificationBadge: 'verified_student',
        verificationStatus: 'approved',
        isVerified: true,
        collegeId: 'college-a',
      },
    });
  });

  it('denies approved user changing collegeId', async () => {
    await assertFails(
      updateDoc(doc(authDb('verified1'), 'users/verified1'), {
        collegeId: 'college-b',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies self-granting admin role', async () => {
    await assertFails(
      updateDoc(doc(authDb('verified1'), 'users/verified1'), {
        userType: 'admin',
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('H2 question moderation / vote forgery', () => {
  beforeEach(async () => {
    await seed({
      'users/author1': { ...safeUser, uid: 'author1' },
      'users/attacker': { ...safeUser, uid: 'attacker' },
      'college_questions/q1': {
        authorId: 'author1',
        collegeId: 'college-a',
        answerCount: 1,
        status: 'published',
        reportCount: 0,
      },
      'college_questions/q1/answers/a1': {
        authorId: 'author1',
        upvoteCount: 1,
        downvoteCount: 0,
        score: 1,
        isMostHelpful: false,
        isAccepted: false,
      },
    });
  });

  it('denies attacker hiding a question', async () => {
    await assertFails(
      updateDoc(doc(authDb('attacker'), 'college_questions/q1'), {
        status: 'hidden',
        moderationFlag: 'spam',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies attacker forging answer vote totals', async () => {
    await assertFails(
      updateDoc(doc(authDb('attacker'), 'college_questions/q1/answers/a1'), {
        upvoteCount: 500,
        downvoteCount: 0,
        score: 500,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies attacker marking most helpful', async () => {
    await assertFails(
      updateDoc(doc(authDb('attacker'), 'college_questions/q1/answers/a1'), {
        isMostHelpful: true,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('allows question author to accept an answer', async () => {
    await assertSucceeds(
      updateDoc(doc(authDb('author1'), 'college_questions/q1'), {
        acceptedAnswerId: 'a1',
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('H3 community conversation/message updates', () => {
  beforeEach(async () => {
    await seed({
      'users/u1': { ...safeUser, uid: 'u1' },
      'users/u2': { ...safeUser, uid: 'u2' },
      'community_conversations/c1': {
        type: 'college',
        participantIds: ['u1', 'u2'],
      },
      'community_messages/m1': {
        conversationId: 'c1',
        senderId: 'u1',
        likeCount: 0,
        likedBy: [],
        reportCount: 0,
        status: 'visible',
        readBy: ['u1'],
      },
    });
  });

  it('allows participant lastMessage update', async () => {
    await assertSucceeds(
      updateDoc(doc(authDb('u1'), 'community_conversations/c1'), {
        lastMessageText: 'hello',
        lastMessageSenderId: 'u1',
        lastMessageAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies arbitrary conversation field mutation', async () => {
    await assertFails(
      updateDoc(doc(authDb('u1'), 'community_conversations/c1'), {
        type: 'private',
        participantIds: ['u1'],
      }),
    );
  });

  it('allows like +1 when likedBy includes voter', async () => {
    await assertSucceeds(
      updateDoc(doc(authDb('u2'), 'community_messages/m1'), {
        likedBy: ['u2'],
        likeCount: 1,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('denies forging likeCount jumps', async () => {
    await assertFails(
      updateDoc(doc(authDb('u2'), 'community_messages/m1'), {
        likedBy: ['u2'],
        likeCount: 99,
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('H4 users read least privilege', () => {
  beforeEach(async () => {
    await seed({
      'users/viewer': {
        ...safeUser,
        uid: 'viewer',
        collegeId: 'college-a',
      },
      'users/privateOtherCollege': {
        ...safeUser,
        uid: 'privateOtherCollege',
        email: 'secret@example.com',
        phone: '9999999999',
        collegeId: 'college-b',
        communicationSettings: {
          isGuideAvailable: false,
          allowPublicProfile: false,
        },
      },
      'users/guidePublic': {
        ...safeUser,
        uid: 'guidePublic',
        collegeId: 'college-c',
        communicationSettings: {
          isGuideAvailable: true,
          allowPublicProfile: false,
        },
      },
      // PII-free mirror `syncPublicProfile` maintains for `users/guidePublic`
      // — this, not the `users` doc, is what other viewers read for guide
      // discovery. See match /public_profiles/{userId} in firestore.rules.
      'public_profiles/guidePublic': {
        uid: 'guidePublic',
        userType: safeUser.userType,
        verificationBadge: safeUser.verificationBadge,
        verificationStatus: safeUser.verificationStatus,
        isVerified: safeUser.isVerified,
        collegeId: 'college-c',
        guideStats: safeUser.guideStats,
        communicationSettings: {
          isGuideAvailable: true,
          allowPublicProfile: false,
        },
      },
    });
  });

  it('allows reading discoverable guide profiles', async () => {
    await assertSucceeds(
      getDoc(doc(authDb('viewer'), 'public_profiles/guidePublic')),
    );
  });

  it('denies reading private users from other colleges', async () => {
    await assertFails(
      getDoc(doc(authDb('viewer'), 'users/privateOtherCollege')),
    );
  });

  it('allows owner to read own profile', async () => {
    await assertSucceeds(
      getDoc(doc(authDb('privateOtherCollege'), 'users/privateOtherCollege')),
    );
  });
});

describe('H5 college_requests duplicate index', () => {
  beforeEach(async () => {
    await seed({
      'users/student1': safeUser,
      'users/student2': { ...safeUser, uid: 'student2' },
      'college_requests/req1': {
        userId: 'student1',
        status: 'pending_review',
        nameLower: 'alpha college',
        cityLower: 'pune',
      },
    });
  });

  it('denies other users reading pending college requests', async () => {
    await assertFails(getDoc(doc(authDb('student2'), 'college_requests/req1')));
  });

  it('allows authenticated users to read duplicate index docs', async () => {
    await seed({
      'college_request_duplicates/alpha college_pune': {
        nameLower: 'alpha college',
        cityLower: 'pune',
        requestId: 'req1',
        createdAt: new Date().toISOString(),
      },
    });
    await assertSucceeds(
      getDoc(doc(authDb('student2'), 'college_request_duplicates/alpha college_pune')),
    );
  });

  it('allows creating duplicate index with allowlisted fields', async () => {
    await assertSucceeds(
      setDoc(doc(authDb('student1'), 'college_request_duplicates/beta_mumbai'), {
        nameLower: 'beta',
        cityLower: 'mumbai',
        requestId: 'req-new',
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies creating duplicate index with extra PII fields', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'college_request_duplicates/gamma_delhi'), {
        nameLower: 'gamma',
        cityLower: 'delhi',
        requestId: 'req-x',
        createdAt: new Date().toISOString(),
        userEmail: 'leak@example.com',
      }),
    );
  });
});

describe('H6 paid consultations', () => {
  const eligibleGuide = {
    uid: 'guide1',
    userType: 'student',
    verificationBadge: 'verified_student',
    verificationStatus: 'approved',
    isVerified: true,
    collegeId: 'college-a',
    guideStats: { totalRatings: 0, overallRating: 0, badgeTier: 'none' },
    communicationSettings: {
      isGuideAvailable: true,
      chatAvailable: true,
      callAvailable: true,
      chatPricePaise: 4900,
      chatDurationMinutes: 15,
      callPricing: [{ type: 'call', minutes: 15, pricePaise: 9900 }],
      allowPublicProfile: false,
    },
  };
  const unverifiedGuide = {
    uid: 'guide2',
    userType: 'student',
    verificationBadge: 'none',
    verificationStatus: 'incomplete',
    isVerified: false,
    guideStats: {},
    communicationSettings: {
      isGuideAvailable: true,
      chatAvailable: true,
      chatPricePaise: 4900,
      chatDurationMinutes: 15,
    },
  };

  function requestPayload(overrides = {}) {
    return {
      studentId: 'student1',
      guideId: 'guide1',
      type: 'chat',
      status: 'requested',
      priceInfo: { grossPaise: 4900, platformFeePaise: 0, guideAmountPaise: 0, currency: 'INR' },
      durationMinutes: 15,
      createdAt: new Date().toISOString(),
      ...overrides,
    };
  }

  beforeEach(async () => {
    await seed({
      'public_profiles/guide1': eligibleGuide,
      'public_profiles/guide2': unverifiedGuide,
    });
  });

  it('allows booking a consultation with an eligible verified guide', async () => {
    await assertSucceeds(
      setDoc(doc(authDb('student1'), 'consultations/c1'), requestPayload()),
    );
  });

  it('denies booking with an unverified guide', async () => {
    await assertFails(
      setDoc(
        doc(authDb('student1'), 'consultations/c2'),
        requestPayload({ guideId: 'guide2' }),
      ),
    );
  });

  it('denies impersonating another student as the requester', async () => {
    await assertFails(
      setDoc(
        doc(authDb('attacker'), 'consultations/c3'),
        requestPayload({ studentId: 'student1' }),
      ),
    );
  });

  it('denies pre-setting platform fee / guide amount at create', async () => {
    await assertFails(
      setDoc(
        doc(authDb('student1'), 'consultations/c4'),
        requestPayload({
          priceInfo: {
            grossPaise: 4900,
            platformFeePaise: 1,
            guideAmountPaise: 4899,
            currency: 'INR',
          },
        }),
      ),
    );
  });

  it('denies a student marking their own consultation paid', async () => {
    await seed({ 'consultations/c5': requestPayload() });
    await assertFails(
      updateDoc(doc(authDb('student1'), 'consultations/c5'), {
        status: 'paid',
        paidAt: new Date().toISOString(),
      }),
    );
  });

  it('denies forging guideAmountPaise via an unrelated-looking update', async () => {
    await seed({
      'consultations/c6': requestPayload({ status: 'paid', paidAt: new Date().toISOString() }),
    });
    await assertFails(
      updateDoc(doc(authDb('guide1'), 'consultations/c6'), {
        status: 'waiting_for_guide',
        'priceInfo.guideAmountPaise': 4900,
      }),
    );
  });

  it('allows the student to cancel before payment', async () => {
    await seed({ 'consultations/c7': requestPayload() });
    await assertSucceeds(
      updateDoc(doc(authDb('student1'), 'consultations/c7'), {
        status: 'cancelled',
        cancelledAt: new Date().toISOString(),
        cancelReason: 'changed my mind',
      }),
    );
  });

  it('denies the guide cancelling before payment (not their call yet)', async () => {
    await seed({ 'consultations/c8': requestPayload() });
    await assertFails(
      updateDoc(doc(authDb('guide1'), 'consultations/c8'), {
        status: 'cancelled',
        cancelledAt: new Date().toISOString(),
      }),
    );
  });

  it('denies rating before the consultation is completed', async () => {
    await seed({
      'consultations/c9': requestPayload({ status: 'active', startedAt: new Date().toISOString() }),
    });
    await assertFails(
      setDoc(doc(authDb('student1'), 'consultation_ratings/c9_student'), {
        consultationId: 'c9',
        raterId: 'student1',
        raterRole: 'student',
        rateeId: 'guide1',
        overall: 5,
        criteria: { communication: 5, criterion2: 5, criterion3: 5, criterion4: 5 },
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('allows rating once completed, then denies a duplicate rating', async () => {
    await seed({
      'consultations/c10': requestPayload({
        status: 'completed',
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }),
    });
    const ratingDoc = doc(authDb('student1'), 'consultation_ratings/c10_student');
    await assertSucceeds(
      setDoc(ratingDoc, {
        consultationId: 'c10',
        raterId: 'student1',
        raterRole: 'student',
        rateeId: 'guide1',
        overall: 5,
        criteria: { communication: 5, criterion2: 5, criterion3: 5, criterion4: 5 },
        createdAt: new Date().toISOString(),
      }),
    );
    // Duplicate write to the same deterministic doc ID is an update, and
    // no update branch on consultation_ratings is ever allowed.
    await assertFails(
      setDoc(ratingDoc, {
        consultationId: 'c10',
        raterId: 'student1',
        raterRole: 'student',
        rateeId: 'guide1',
        overall: 1,
        criteria: { communication: 1, criterion2: 1, criterion3: 1, criterion4: 1 },
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies a guide rating themself', async () => {
    await seed({
      'consultations/c11': requestPayload({
        studentId: 'guide1',
        guideId: 'guide1',
        status: 'completed',
        completedAt: new Date().toISOString(),
      }),
    });
    await assertFails(
      setDoc(doc(authDb('guide1'), 'consultation_ratings/c11_student'), {
        consultationId: 'c11',
        raterId: 'guide1',
        raterRole: 'student',
        rateeId: 'guide1',
        overall: 5,
        criteria: { communication: 5, criterion2: 5, criterion3: 5, criterion4: 5 },
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies any client write to payments', async () => {
    await assertFails(
      setDoc(doc(authDb('student1'), 'payments/pay1'), {
        consultationId: 'c1',
        studentId: 'student1',
        guideId: 'guide1',
        grossAmountPaise: 4900,
        platformFeePaise: 0,
        guideAmountPaise: 0,
        currency: 'INR',
        gateway: 'razorpay',
        status: 'pending',
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies a guide reading another guide\'s earnings', async () => {
    await seed({
      'guide_earnings/guide1/entries/c1': { consultationId: 'c1', amountPaise: 3920, status: 'pending' },
    });
    await assertFails(
      getDoc(doc(authDb('guide2'), 'guide_earnings/guide1/entries/c1')),
    );
  });

  it('allows a guide reading their own earnings', async () => {
    await seed({
      'guide_earnings/guide1/entries/c1': { consultationId: 'c1', amountPaise: 3920, status: 'pending' },
    });
    await assertSucceeds(
      getDoc(doc(authDb('guide1'), 'guide_earnings/guide1/entries/c1')),
    );
  });

  it('denies a client writing guide_earnings directly', async () => {
    await assertFails(
      setDoc(doc(authDb('guide1'), 'guide_earnings/guide1/entries/fake'), {
        consultationId: 'fake',
        amountPaise: 999999,
        status: 'payable',
      }),
    );
  });
});

describe('Unauthenticated baseline', () => {
  it('denies anonymous user create', async () => {
    await assertFails(setDoc(doc(anonDb(), 'users/student1'), safeUser));
  });
});
