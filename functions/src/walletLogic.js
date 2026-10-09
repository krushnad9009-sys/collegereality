'use strict';

// Pure money rules for the shared call wallet and guide call pricing -- no
// Firestore handles, so every rupee calculation is unit-tested
// (test/walletLogic.test.js). All amounts are integer PAISE.
//
// Model: the student's wallet holds rupees. A paid call to ANY guide is
// billed per second at THAT guide's per-minute rate, and only for the time
// actually talked -- whatever isn't used stays in the wallet for the next
// call, with this guide or another. Mirrored for display in
// lib/core/constants/wallet_constants.dart.

const { splitConsultationAmount } = require('./consultationLogic');

// Applies to every guide who hasn't published their own call pricing.
const DEFAULT_RATE_PAISE_PER_MINUTE = 1000; // ₹10/min

const MIN_RECHARGE_PAISE = 5000; // ₹50
const MAX_RECHARGE_PAISE = 1000000; // ₹10,000

// A paid call needs at least this much talk time in the wallet to start.
const MIN_CALL_SECONDS = 60;
// Hard cap on one paid call regardless of balance.
const MAX_PAID_CALL_SECONDS = 60 * 60;

function isPositiveInt(n) {
  return Number.isInteger(n) && n > 0;
}

/**
 * The per-minute rate for calling a guide:
 *   1. their explicit per-minute rate, if set;
 *   2. otherwise derived from their cheapest priced voice call package
 *      (price / minutes, rounded up to whole paise);
 *   3. otherwise the platform default (₹10/min).
 */
/**
 * A guide's priced call packages, voice only. Video calling isn't offered
 * (no live video stream exists), so video packages some guides saved
 * earlier are ignored everywhere. Mirrored in the app's
 * GuideCommunicationSettings.fromJson.
 */
function pricedVoicePackages(s) {
  return (Array.isArray(s.callPricing) ? s.callPricing : []).filter(
    (p) =>
      p &&
      p.type !== 'video' &&
      isPositiveInt(p.pricePaise) &&
      isPositiveInt(p.minutes),
  );
}

function resolvePerMinuteRatePaise(settings) {
  const s = settings || {};
  if (isPositiveInt(s.perMinuteRatePaise)) return s.perMinuteRatePaise;
  const perMinute = pricedVoicePackages(s)
    .map((p) => Math.ceil(p.pricePaise / p.minutes));
  if (perMinute.length > 0) return Math.min(...perMinute);
  return DEFAULT_RATE_PAISE_PER_MINUTE;
}

/**
 * Consultation (fixed-package) call options a guide offers. A guide with
 * no priced call packages gets default packages at the default rate
 * instead of a dead-end "not taking consultations" screen.
 */
const DEFAULT_PACKAGE_MINUTES = Object.freeze([15, 30]);

function effectiveCallPackages(settings) {
  const s = settings || {};
  const packs = pricedVoicePackages(s);
  if (s.callAvailable && packs.length > 0) return packs;
  if (packs.length > 0) return []; // guide priced calls but switched them off
  return DEFAULT_PACKAGE_MINUTES.map((minutes) => ({
    type: 'call',
    minutes,
    pricePaise: minutes * DEFAULT_RATE_PAISE_PER_MINUTE,
    isDefault: true,
  }));
}

/** Longest call the balance can pay for, in whole seconds (capped). */
function maxCallSecondsFor(balancePaise, ratePaisePerMinute) {
  if (!isPositiveInt(ratePaisePerMinute) || !(balancePaise > 0)) return 0;
  const seconds = Math.floor((balancePaise * 60) / ratePaisePerMinute);
  return Math.min(seconds, MAX_PAID_CALL_SECONDS);
}

/** Charge for `seconds` of talk, per-second billing, rounded up to 1 paisa. */
function chargeForSeconds(seconds, ratePaisePerMinute) {
  if (!(seconds > 0) || !isPositiveInt(ratePaisePerMinute)) return 0;
  return Math.ceil((seconds * ratePaisePerMinute) / 60);
}

/**
 * Settles one finished paid call.
 * @returns {{chargePaise, guideAmountPaise, platformFeePaise, balanceAfterPaise}}
 */
function settleCall({ balancePaise, billedSeconds, ratePaisePerMinute }) {
  const balance = Math.max(0, Math.floor(balancePaise || 0));
  const chargePaise = Math.min(chargeForSeconds(billedSeconds, ratePaisePerMinute), balance);
  if (chargePaise <= 0) {
    return { chargePaise: 0, guideAmountPaise: 0, platformFeePaise: 0, balanceAfterPaise: balance };
  }
  const { platformFeePaise, guideAmountPaise } = splitConsultationAmount(chargePaise);
  return {
    chargePaise,
    guideAmountPaise,
    platformFeePaise,
    balanceAfterPaise: balance - chargePaise,
  };
}

/** Recharge amounts: whole rupees within [₹50, ₹10,000]. */
function validateRechargeAmount(amountPaise) {
  return (
    Number.isInteger(amountPaise) &&
    amountPaise % 100 === 0 &&
    amountPaise >= MIN_RECHARGE_PAISE &&
    amountPaise <= MAX_RECHARGE_PAISE
  );
}

module.exports = {
  DEFAULT_RATE_PAISE_PER_MINUTE,
  MIN_RECHARGE_PAISE,
  MAX_RECHARGE_PAISE,
  MIN_CALL_SECONDS,
  MAX_PAID_CALL_SECONDS,
  resolvePerMinuteRatePaise,
  effectiveCallPackages,
  maxCallSecondsFor,
  chargeForSeconds,
  settleCall,
  validateRechargeAmount,
};
