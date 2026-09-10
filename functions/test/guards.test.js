'use strict';

const { assertConfigured, newCorrelationId } = require('../src/util/guards');

describe('assertConfigured', () => {
  it('returns the value when set', () => {
    expect(assertConfigured('rzp_live_x', 'Payments')).toBe('rzp_live_x');
    expect(assertConfigured(0, 'X')).toBe(0);
    expect(assertConfigured(false, 'X')).toBe(false);
  });

  it('throws a failed-precondition (no vendor detail) when unset', () => {
    for (const bad of [undefined, null, '']) {
      expect(() => assertConfigured(bad, 'Payments')).toThrow(
        /temporarily unavailable/i,
      );
      try {
        assertConfigured(bad, 'Payments');
      } catch (e) {
        expect(e.code).toBe('failed-precondition');
        expect(e.message).not.toMatch(/secret|key|env|manager/i);
      }
    }
  });
});

describe('newCorrelationId', () => {
  it('is short, url-safe, and unique per call', () => {
    const a = newCorrelationId();
    const b = newCorrelationId();
    expect(a).toMatch(/^[A-Za-z0-9_-]{8,16}$/);
    expect(a).not.toBe(b);
  });
});
