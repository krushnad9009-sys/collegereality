'use strict';

const crypto = require('crypto');
const {
  REWARD_PAISE,
  DAILY_CAP,
  parseSsvQuery,
  verifySsvSignature,
  pemForKeyId,
  decideReward,
} = require('../src/adRewardLogic');

// A throwaway P-256 key pair standing in for Google's signing key.
const { privateKey, publicKey } = crypto.generateKeyPairSync('ec', {
  namedCurve: 'prime256v1',
});
const pem = publicKey.export({ type: 'spki', format: 'pem' });

function webSafe(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Builds a query string exactly the way AdMob does: signed part first. */
function signedQuery(fields) {
  const message = new URLSearchParams(fields).toString();
  const sig = crypto.sign('sha256', Buffer.from(message), { key: privateKey, dsaEncoding: 'der' });
  return `${message}&signature=${webSafe(sig)}&key_id=1234`;
}

const fields = {
  ad_network: '5450213213286189855',
  ad_unit: '1234567890',
  reward_amount: '1',
  reward_item: 'Reward',
  timestamp: '1790000000000',
  transaction_id: 'tx-abc',
  user_id: 'uid-1',
};

describe('SSV parsing + signature', () => {
  it('parses the signed message, signature, key and params', () => {
    const parsed = parseSsvQuery(signedQuery(fields));
    expect(parsed.keyId).toBe('1234');
    expect(parsed.params.userId).toBe('uid-1');
    expect(parsed.params.transactionId).toBe('tx-abc');
    expect(parsed.message).not.toContain('signature=');
  });

  it('accepts a genuine Google-style signature', () => {
    const parsed = parseSsvQuery(signedQuery(fields));
    expect(verifySsvSignature(parsed.message, parsed.signature, pem)).toBe(true);
  });

  it('rejects a callback whose user_id was tampered with', () => {
    const tampered = signedQuery(fields).replace('user_id=uid-1', 'user_id=attacker');
    const parsed = parseSsvQuery(tampered);
    expect(verifySsvSignature(parsed.message, parsed.signature, pem)).toBe(false);
  });

  it('rejects a signature from a different key', () => {
    const other = crypto.generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const otherPem = other.publicKey.export({ type: 'spki', format: 'pem' });
    const parsed = parseSsvQuery(signedQuery(fields));
    expect(verifySsvSignature(parsed.message, parsed.signature, otherPem)).toBe(false);
  });

  it('rejects malformed input without throwing', () => {
    expect(parseSsvQuery('user_id=x')).toBeNull();
    expect(parseSsvQuery(undefined)).toBeNull();
    expect(verifySsvSignature('m', '!!!not-base64!!!', pem)).toBe(false);
  });

  it('finds the PEM for a key id', () => {
    const keysJson = { keys: [{ keyId: 1234, pem }, { keyId: 99, pem: 'x' }] };
    expect(pemForKeyId(keysJson, '1234')).toBe(pem);
    expect(pemForKeyId(keysJson, '5')).toBeNull();
  });
});

describe('decideReward', () => {
  const base = { userId: 'u', transactionId: 't', alreadyProcessed: false, rewardsToday: 0 };

  it('credits a fresh, verified reward', () => {
    expect(decideReward(base)).toEqual({ credit: true, amountPaise: REWARD_PAISE });
  });

  it('never credits the same ad view twice (AdMob retries callbacks)', () => {
    expect(decideReward({ ...base, alreadyProcessed: true }).reason).toBe('duplicate');
  });

  it('stops at the daily cap', () => {
    expect(decideReward({ ...base, rewardsToday: DAILY_CAP - 1 }).credit).toBe(true);
    expect(decideReward({ ...base, rewardsToday: DAILY_CAP }).reason).toBe('daily_cap');
  });

  it('needs a user and a transaction id', () => {
    expect(decideReward({ ...base, userId: '' }).reason).toBe('no_user');
    expect(decideReward({ ...base, transactionId: '' }).reason).toBe('no_transaction');
  });
});
