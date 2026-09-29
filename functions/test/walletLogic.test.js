'use strict';

const {
  DEFAULT_RATE_PAISE_PER_MINUTE,
  MAX_PAID_CALL_SECONDS,
  resolvePerMinuteRatePaise,
  effectiveCallPackages,
  maxCallSecondsFor,
  chargeForSeconds,
  settleCall,
  validateRechargeAmount,
} = require('../src/walletLogic');

describe('resolvePerMinuteRatePaise', () => {
  it('falls back to ₹10/min for a guide with no pricing at all', () => {
    expect(resolvePerMinuteRatePaise(undefined)).toBe(1000);
    expect(resolvePerMinuteRatePaise({})).toBe(DEFAULT_RATE_PAISE_PER_MINUTE);
    expect(resolvePerMinuteRatePaise({ callPricing: [{ minutes: 15, pricePaise: 0 }] }))
      .toBe(1000);
  });

  it("uses the guide's explicit per-minute rate first", () => {
    expect(resolvePerMinuteRatePaise({
      perMinuteRatePaise: 1500,
      callPricing: [{ minutes: 15, pricePaise: 9900 }],
    })).toBe(1500);
  });

  it('derives from the cheapest priced call package otherwise', () => {
    // ₹99 / 15 min = 660 paise/min; ₹249 / 30 min = 830.
    expect(resolvePerMinuteRatePaise({
      callPricing: [
        { minutes: 30, pricePaise: 24900 },
        { minutes: 15, pricePaise: 9900 },
      ],
    })).toBe(660);
  });
});

describe('effectiveCallPackages (consultation checkout fallback)', () => {
  it('offers default packages when the guide never priced calls', () => {
    expect(effectiveCallPackages({})).toEqual([
      { type: 'call', minutes: 15, pricePaise: 15000, isDefault: true },
      { type: 'call', minutes: 30, pricePaise: 30000, isDefault: true },
    ]);
  });

  it("uses the guide's own packages when calls are on", () => {
    const own = [{ type: 'call', minutes: 15, pricePaise: 9900 }];
    expect(effectiveCallPackages({ callAvailable: true, callPricing: own })).toEqual(own);
  });

  it('respects a guide who priced calls but switched them off', () => {
    expect(effectiveCallPackages({
      callAvailable: false,
      callPricing: [{ type: 'call', minutes: 15, pricePaise: 9900 }],
    })).toEqual([]);
  });
});

describe('shared wallet across guides', () => {
  it('15 minutes of balance, 5 with guide A, leaves 10 for guide B', () => {
    const rate = 1000; // both guides at ₹10/min
    const recharge = 15000; // ₹150

    const callA = settleCall({ balancePaise: recharge, billedSeconds: 5 * 60, ratePaisePerMinute: rate });
    expect(callA.chargePaise).toBe(5000);
    expect(callA.balanceAfterPaise).toBe(10000);

    // What's left funds exactly 10 more minutes with a different guide.
    expect(maxCallSecondsFor(callA.balanceAfterPaise, rate)).toBe(10 * 60);
    const callB = settleCall({
      balancePaise: callA.balanceAfterPaise,
      billedSeconds: 10 * 60,
      ratePaisePerMinute: rate,
    });
    expect(callB.balanceAfterPaise).toBe(0);
  });

  it("the same balance buys more time with a cheaper guide", () => {
    expect(maxCallSecondsFor(10000, 500)).toBe(20 * 60); // ₹100 at ₹5/min
    expect(maxCallSecondsFor(10000, 2000)).toBe(5 * 60); // ₹100 at ₹20/min
  });
});

describe('billing', () => {
  it('bills per second, rounding up to the paisa', () => {
    expect(chargeForSeconds(1, 1000)).toBe(17); // 16.67 -> 17
    expect(chargeForSeconds(90, 1000)).toBe(1500);
    expect(chargeForSeconds(0, 1000)).toBe(0);
  });

  it('never charges more than the balance', () => {
    const s = settleCall({ balancePaise: 3000, billedSeconds: 600, ratePaisePerMinute: 1000 });
    expect(s.chargePaise).toBe(3000);
    expect(s.balanceAfterPaise).toBe(0);
  });

  it('splits every charge 80/20 without losing paise', () => {
    const s = settleCall({ balancePaise: 100000, billedSeconds: 77, ratePaisePerMinute: 1000 });
    expect(s.guideAmountPaise + s.platformFeePaise).toBe(s.chargePaise);
  });

  it('a call that never connected costs nothing', () => {
    expect(settleCall({ balancePaise: 5000, billedSeconds: 0, ratePaisePerMinute: 1000 }))
      .toEqual({ chargePaise: 0, guideAmountPaise: 0, platformFeePaise: 0, balanceAfterPaise: 5000 });
  });

  it('caps a single call at one hour', () => {
    expect(maxCallSecondsFor(10000000, 1000)).toBe(MAX_PAID_CALL_SECONDS);
  });
});

describe('validateRechargeAmount', () => {
  it('accepts whole rupees between ₹50 and ₹10,000', () => {
    expect(validateRechargeAmount(5000)).toBe(true);
    expect(validateRechargeAmount(15000)).toBe(true);
    expect(validateRechargeAmount(1000000)).toBe(true);
  });

  it('rejects out-of-range, fractional-rupee and non-integer amounts', () => {
    for (const bad of [4900, 1000100, 15050, 150.5, -5000, '15000', null]) {
      expect(validateRechargeAmount(bad)).toBe(false);
    }
  });
});
