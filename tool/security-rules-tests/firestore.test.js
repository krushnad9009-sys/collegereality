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

describe('Unauthenticated baseline', () => {
  it('denies anonymous user create', async () => {
    await assertFails(setDoc(doc(anonDb(), 'users/student1'), safeUser));
  });
});
