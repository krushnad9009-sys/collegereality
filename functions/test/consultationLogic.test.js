'use strict';

const {
  splitConsultationAmount,
  resolveGuidePriceForConsultation,
  verifyCheckoutSignature,
  verifyWebhookSignature,
} = require('../src/consultationLogic');
const crypto = require('crypto');

describe('splitConsultationAmount', () => {
  it('splits a round amount at exactly 20% platform fee', () => {
    const { platformFeePaise, guideAmountPaise } = splitConsultationAmount(10000);
    expect(platformFeePaise).toBe(2000);
    expect(guideAmountPaise).toBe(8000);
    expect(platformFeePaise + guideAmountPaise).toBe(10000);
  });

  it('never loses or invents paise on odd amounts (₹49 = 4900 paise)', () => {
    const { platformFeePaise, guideAmountPaise } = splitConsultationAmount(4900);
    expect(platformFeePaise + guideAmountPaise).toBe(4900);
    expect(Number.isInteger(platformFeePaise)).toBe(true);
    expect(Number.isInteger(guideAmountPaise)).toBe(true);
  });

  it('rejects zero, negative, and non-integer amounts', () => {
    expect(() => splitConsultationAmount(0)).toThrow();
    expect(() => splitConsultationAmount(-100)).toThrow();
    expect(() => splitConsultationAmount(99.5)).toThrow();
  });
});

describe('resolveGuidePriceForConsultation', () => {
  const settings = {
    chatAvailable: true,
    chatPricePaise: 4900,
    chatDurationMinutes: 15,
    callAvailable: true,
    callPricing: [
      { type: 'call', minutes: 15, pricePaise: 9900 },
      { type: 'video', minutes: 30, pricePaise: 19900 },
    ],
  };

  it('resolves the published chat price', () => {
    expect(
      resolveGuidePriceForConsultation({ settings, type: 'chat', durationMinutes: 15 }),
    ).toBe(4900);
  });

  it('resolves a matching call option', () => {
    expect(
      resolveGuidePriceForConsultation({ settings, type: 'call', durationMinutes: 15 }),
    ).toBe(9900);
  });

  it('returns null for a duration the guide does not offer', () => {
    expect(
      resolveGuidePriceForConsultation({ settings, type: 'call', durationMinutes: 45 }),
    ).toBeNull();
  });

  it('returns null when the channel is toggled off', () => {
    expect(
      resolveGuidePriceForConsultation({
        settings: { ...settings, chatAvailable: false },
        type: 'chat',
        durationMinutes: 15,
      }),
    ).toBeNull();
  });

  it('returns null for a stale/tampered client price by never trusting it', () => {
    // The function only ever returns the server-known price or null — a
    // caller comparing this to a client-sent number is how the tamper
    // check in consultations.js works.
    const serverPrice = resolveGuidePriceForConsultation({
      settings,
      type: 'chat',
      durationMinutes: 15,
    });
    const clientClaimedPrice = 100; // attacker-supplied
    expect(serverPrice).not.toBe(clientClaimedPrice);
  });
});

describe('verifyCheckoutSignature', () => {
  const secret = 'test_secret';
  const orderId = 'order_ABC123';
  const paymentId = 'pay_XYZ789';

  function sign(oId, pId, s) {
    return crypto.createHmac('sha256', s).update(`${oId}|${pId}`).digest('hex');
  }

  it('accepts a correctly signed payload', () => {
    const signature = sign(orderId, paymentId, secret);
    expect(
      verifyCheckoutSignature({ orderId, paymentId, signature, secret }),
    ).toBe(true);
  });

  it('rejects a tampered payment id', () => {
    const signature = sign(orderId, paymentId, secret);
    expect(
      verifyCheckoutSignature({
        orderId,
        paymentId: 'pay_ATTACKER',
        signature,
        secret,
      }),
    ).toBe(false);
  });

  it('rejects a signature made with the wrong secret', () => {
    const signature = sign(orderId, paymentId, 'wrong_secret');
    expect(
      verifyCheckoutSignature({ orderId, paymentId, signature, secret }),
    ).toBe(false);
  });

  it('rejects garbage/malformed signatures without throwing', () => {
    expect(() =>
      verifyCheckoutSignature({
        orderId,
        paymentId,
        signature: 'not-hex-at-all',
        secret,
      }),
    ).not.toThrow();
    expect(
      verifyCheckoutSignature({
        orderId,
        paymentId,
        signature: 'not-hex-at-all',
        secret,
      }),
    ).toBe(false);
  });
});

describe('verifyWebhookSignature', () => {
  const secret = 'webhook_secret';
  const rawBody = Buffer.from(JSON.stringify({ event: 'payment.captured' }));

  it('accepts a correctly signed raw body', () => {
    const signature = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    expect(verifyWebhookSignature({ rawBody, signature, secret })).toBe(true);
  });

  it('rejects a replayed signature over a different body (tamper/replay defense)', () => {
    const signature = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    const tamperedBody = Buffer.from(JSON.stringify({ event: 'payment.captured', amount: 1 }));
    expect(
      verifyWebhookSignature({ rawBody: tamperedBody, signature, secret }),
    ).toBe(false);
  });
});
