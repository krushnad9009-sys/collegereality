'use strict';

const { AI_CHAT_CONFIG } = require('./config');

const SYSTEM_PROMPT = `You are the College Reality assistant, helping Indian students research colleges.

Rules:
- For specific facts about a college (fees, placements, hostel, ratings, reviews, courses), use ONLY the "VERIFIED COLLEGE REALITY DATA" given below. Never invent or guess a number, review, or fact that isn't there.
- If the verified data needed to answer isn't present, say so plainly — e.g. "Not enough verified College Reality data is available for this yet." Do not fill the gap with a plausible-sounding guess.
- You may give general educational/career guidance (how placements typically work, what to consider on a budget, etc.) using your own knowledge, but you MUST make clear when you're doing that rather than citing College Reality data, e.g. "As general guidance (not College Reality data):".
- Never mention colleges, cities, or states that are not present in the verified data given to you, even if they seem relevant.
- Be concise and conversational — a few short sentences or a short list, not an essay. No markdown headers.
- If comparing or ranking colleges, briefly say why, using the verified metrics given.`;

function clip(text, maxLen) {
  if (!text) return '';
  const s = String(text);
  return s.length > maxLen ? `${s.slice(0, maxLen)}…` : s;
}

function formatCollegeContext(college) {
  if (!college) return '';
  const lines = [`College: ${clip(college.name, 120)} (${clip(college.city, 60)}, ${clip(college.state, 60)}) — ${clip(college.category, 40)}`];
  if (college.crScore) lines.push(`CR Score: ${college.crScore}`);
  if (college.feesMin || college.feesMax) {
    lines.push(`Tuition fees: ₹${college.feesMin || '?'}–₹${college.feesMax || '?'} /year`);
  }
  if (college.avgPackageLpa) lines.push(`Average package: ₹${college.avgPackageLpa} LPA`);
  if (college.highestPackageLpa) lines.push(`Highest package: ₹${college.highestPackageLpa} LPA`);
  if (college.placementPct) lines.push(`Placement rate: ${college.placementPct}%`);
  if (college.hostelAvailable != null) lines.push(`Hostel available: ${college.hostelAvailable ? 'yes' : 'no'}`);
  if (Array.isArray(college.reviewExcerpts) && college.reviewExcerpts.length) {
    lines.push('Verified student review excerpts:');
    college.reviewExcerpts
      .slice(0, AI_CHAT_CONFIG.MAX_REVIEW_EXCERPTS)
      .forEach((r) => lines.push(`  - "${clip(r, 220)}"`));
  }
  if (Array.isArray(college.verifiedAnswerExcerpts) && college.verifiedAnswerExcerpts.length) {
    lines.push('Verified student Q&A excerpts:');
    college.verifiedAnswerExcerpts
      .slice(0, AI_CHAT_CONFIG.MAX_REVIEW_EXCERPTS)
      .forEach((a) => lines.push(`  - "${clip(a, 220)}"`));
  }
  return lines.join('\n');
}

function formatCandidates(candidates) {
  if (!Array.isArray(candidates) || candidates.length === 0) return '';
  const rows = candidates
    .slice(0, AI_CHAT_CONFIG.MAX_CANDIDATE_COLLEGES)
    .map((c, i) => {
      const bits = [`${i + 1}. ${clip(c.name, 100)} — ${clip(c.city, 50)}, ${clip(c.state, 50)}`];
      if (c.crScore) bits.push(`CR ${c.crScore}`);
      if (c.avgPackageLpa) bits.push(`avg ₹${c.avgPackageLpa}L`);
      if (c.placementPct) bits.push(`${c.placementPct}% placed`);
      if (c.feesMin) bits.push(`fees ₹${c.feesMin}+/yr`);
      return bits.join(' | ');
    });
  return `Matching verified colleges (already filtered/ranked by College Reality's database — do not add any other college):\n${rows.join('\n')}`;
}

function formatHistory(history) {
  if (!Array.isArray(history) || history.length === 0) return '';
  const turns = history.slice(-AI_CHAT_CONFIG.MAX_HISTORY_TURNS);
  return turns
    .map((h) => `${h.role === 'user' ? 'Student' : 'Assistant'}: ${clip(h.text, 300)}`)
    .join('\n');
}

/**
 * Builds the compact system+user prompt sent to the LLM. Deliberately
 * plain labeled text rather than indented JSON — noticeably fewer tokens
 * for the same information, and easier for a small/cheap model to read
 * reliably.
 */
function buildPrompt({ question, mode, collegeContext, candidateColleges, history }) {
  const sections = [];
  const historyText = formatHistory(history);
  if (historyText) sections.push(`RECENT CONVERSATION:\n${historyText}`);

  if (mode === 'college' && collegeContext) {
    sections.push(`VERIFIED COLLEGE REALITY DATA:\n${formatCollegeContext(collegeContext)}`);
  } else {
    const candidatesText = formatCandidates(candidateColleges);
    sections.push(
      candidatesText
        ? `VERIFIED COLLEGE REALITY DATA:\n${candidatesText}`
        : 'VERIFIED COLLEGE REALITY DATA: (none matched this query)',
    );
  }

  sections.push(`Student's question: ${clip(question, 500)}`);

  const userPrompt = sections.join('\n\n').slice(0, AI_CHAT_CONFIG.MAX_INPUT_CHARS);
  return { systemPrompt: SYSTEM_PROMPT, userPrompt };
}

module.exports = { buildPrompt, SYSTEM_PROMPT };
