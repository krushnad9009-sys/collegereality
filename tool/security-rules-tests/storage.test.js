import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-college-reality';
const firestoreRules = readFileSync(
  resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const storageRules = readFileSync(
  resolve(__dirname, '../../storage.rules'),
  'utf8',
);

let testEnv;

async function seedUsers() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/student1'), {
      uid: 'student1',
      userType: 'student',
      verificationBadge: 'none',
      verificationStatus: 'incomplete',
    });
    await setDoc(doc(db, 'users/admin1'), {
      uid: 'admin1',
      userType: 'admin',
      verificationBadge: 'none',
      verificationStatus: 'incomplete',
    });
    await setDoc(doc(db, 'college_accounts/official1'), {
      collegeId: 'college-a',
      isVerified: true,
    });
    await setDoc(doc(db, 'users/official1'), {
      uid: 'official1',
      userType: 'student',
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: firestoreRules, host: '127.0.0.1', port: 8080 },
    storage: { rules: storageRules, host: '127.0.0.1', port: 9199 },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
  await seedUsers();
});

describe('C5 college_media storage lockdown', () => {
  const pngBytes = Uint8Array.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  ]);

  it('denies arbitrary authenticated uploads to college_media', async () => {
    const storage = testEnv.authenticatedContext('student1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'college_media/college-a/logo.png'), pngBytes, {
        contentType: 'image/png',
      }),
    );
  });

  it('allows admin uploads to college_media', async () => {
    const storage = testEnv.authenticatedContext('admin1').storage();
    await assertSucceeds(
      uploadBytes(ref(storage, 'college_media/college-a/logo.png'), pngBytes, {
        contentType: 'image/png',
      }),
    );
  });

  it('allows verified college official uploads', async () => {
    const storage = testEnv.authenticatedContext('official1').storage();
    await assertSucceeds(
      uploadBytes(
        ref(storage, 'college_media/college-a/gallery/photo.png'),
        pngBytes,
        { contentType: 'image/png' },
      ),
    );
  });

  it('allows owner college_requests uploads', async () => {
    const storage = testEnv.authenticatedContext('student1').storage();
    await assertSucceeds(
      uploadBytes(
        ref(storage, 'college_requests/student1/photo.png'),
        pngBytes,
        { contentType: 'image/png' },
      ),
    );
  });

  it('denies non-image college_requests uploads', async () => {
    const storage = testEnv.authenticatedContext('student1').storage();
    await assertFails(
      uploadBytes(
        ref(storage, 'college_requests/student1/payload.exe'),
        pngBytes,
        { contentType: 'application/octet-stream' },
      ),
    );
  });
});
