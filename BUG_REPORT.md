# Bug Report

**Audit:** Zero-Assumption Production Audit — 2026-08-05

## Critical (fixed)

| ID | Area | Description | Status |
|----|------|-------------|--------|
| BUG-001 | Marketing | UI claimed 47,000+ colleges; live Firestore has 45,020 | FIXED |
| BUG-002 | Search | Load-more UI after exhaustive search | FIXED |
| BUG-003 | Home | homeRecentReviewsProvider unhandled errors | FIXED |

## High (open)

| ID | Area | Description |
|----|------|-------------|
| BUG-004 | Meta | collegeDirectory analytics stale |
| BUG-005 | Search | universityName empty in production |
| BUG-006 | Auth | User detail timeout (mitigated to 8s) |
| BUG-007 | Admin | AI telemetry not wired |
| BUG-008 | Docs | PLAY_STORE doc still says 47,000+ |
