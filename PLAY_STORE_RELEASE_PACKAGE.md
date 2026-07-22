# College Reality — Play Store Release Package

**Version:** 1.0.0 (Build 1)  
**Package ID:** `com.collegereality.india`  
**Date:** July 22, 2026  

---

## App Store Listing

### App Name
College Reality

### Short Description (80 chars max)
Real college reviews, Q&A & rankings — know the truth before admission.

### Full Description
College Reality is India's trusted platform for honest college insights. Search 47,000+ colleges, read verified student reviews, ask seniors questions, compare colleges side-by-side, and get AI-powered admission guidance — all in one app.

**Why students choose College Reality:**
- Search colleges by name, city, state, course, and category
- Read verified student & alumni reviews across 10 rating dimensions
- Ask verified seniors questions before you take admission
- Join college community feeds and chat with students
- Compare up to 3 colleges with AI insights
- AI Assistant for placement, fees, hostel, and admission queries
- Admission calendar, scholarships, cutoffs, and predictor tools
- Careers hub with internships, jobs, and resume tips
- Campus life events, clubs, and competitions
- Smart college rankings and recommendations
- Push notifications for replies, reviews, and admission deadlines

**For verified students:**
- Write reviews and earn verified badges
- Submit placement data and mentor juniors
- Post in college community feeds

College Reality helps you make informed admission decisions with real data — not marketing brochures.

### Keywords (Play Store tagging)
college reviews, admission, engineering colleges, MBA colleges, college search India, student reviews, college comparison, placement, hostel review, admission predictor, college ranking, ask seniors, verified students, Maharashtra colleges, IIT NIT, medical colleges

### Release Notes (v1.0.0)
- Initial public release on Google Play
- Search 47,000+ Indian colleges with smart filters
- Verified student reviews and Q&A
- College community feeds and private chat
- AI College Assistant with grounded answers
- Admission tools: scholarships, exams, cutoffs, predictor
- Careers hub: internships, jobs, alumni network
- Campus life: events, clubs, competitions
- Push notifications and in-app alerts
- Firebase-powered secure login (Email + Google)
- Offline college cache for faster loading

### Feature List
1. Email & Google authentication
2. College search with pagination (47k+ colleges)
3. College profile with tabs (reviews, Q&A, placements, community)
4. Verified student review system
5. Ask a Student / Q&A board
6. Community feed per college
7. Private chat & Ask Seniors
8. Video/audio call with students (guides)
9. Push & in-app notifications
10. AI College Assistant
11. College compare (up to 3)
12. Rankings & smart recommendations
13. Admission hub (scholarships, exams, cutoffs, predictor)
14. Careers hub (internships, jobs, companies, alumni)
15. Student life (events, clubs, competitions, communities)
16. Student verification with document upload
17. Profile, favorites, bookmarks
18. Admin dashboard (staff only)
19. Privacy policy & terms of service in-app
20. Offline cache fallback

---

## Privacy Policy Checklist

- [x] Privacy policy screen in app (`/privacy-policy`)
- [x] Privacy policy URL ready for Play Console (host at collegereality.in/privacy or GitHub Pages)
- [x] Data collected: email, name, profile photo, college affiliation, reviews, messages
- [x] Firebase Auth, Firestore, Storage, Analytics, Crashlytics disclosed
- [x] Google Sign-In disclosed
- [x] Push notification (FCM) disclosed
- [x] User can delete account (profile → account deletion flow documented)
- [x] Data retention policy described
- [x] Contact email for privacy requests
- [ ] **Action:** Publish privacy policy at public HTTPS URL before submission

## Terms & Conditions Checklist

- [x] Terms of service screen in app (`/terms-of-service`)
- [x] User-generated content policy (reviews, posts, chat)
- [x] Verification document terms
- [x] Moderation and account suspension policy
- [x] Age requirement (13+ with parental consent under 18)
- [ ] **Action:** Publish terms at public HTTPS URL before submission

---

## Screenshot Checklist (Phone + 7-inch Tablet)

Capture on release build (`flutter build apk --release`):

| # | Screen | Required |
|---|--------|----------|
| 1 | Home with featured colleges | Yes |
| 2 | College search with results | Yes |
| 3 | College profile / reviews tab | Yes |
| 4 | Write review / rating screen | Yes |
| 5 | AI Assistant with answer | Yes |
| 6 | Community feed | Recommended |
| 7 | Compare colleges | Recommended |
| 8 | Admission predictor | Optional |
| 9 | Notifications center | Optional |
| 10 | Profile / verification badge | Optional |

**Specs:** Min 2 screenshots, max 8. JPEG or PNG, 16:9 or 9:16, min 320px short side.

---

## Play Store Upload Checklist

### App content
- [ ] App category: Education
- [ ] Content rating questionnaire completed (IARC)
- [ ] Target audience: 13+ (Teen)
- [ ] Ads declaration: No ads (current build)
- [ ] Data safety form completed (Firebase data types)

### Store listing
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars max)
- [ ] App icon 512×512 PNG
- [ ] Feature graphic 1024×500 PNG
- [ ] Phone screenshots (min 2)
- [ ] Privacy policy URL
- [ ] Contact email

### Release
- [ ] Upload AAB to Production or Internal testing track
- [ ] Upload keystore configured (`android/key.properties`)
- [ ] Version code 1, version name 1.0.0
- [ ] Release notes added
- [ ] Countries: India (primary), expand later

### Firebase (before release)
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules,firestore:indexes,storage`
- [ ] Enable Crashlytics in Firebase Console
- [ ] Enable Analytics in Firebase Console
- [ ] Add SHA-1/SHA-256 fingerprints for Google Sign-In

### Build artifacts
```bash
flutter build appbundle --release
flutter build apk --release
```
Output:
- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

---

## Play Store Requirements Verification

| Requirement | Status |
|-------------|--------|
| Target API 34+ | ✅ Via Flutter SDK |
| 64-bit support | ✅ Flutter default |
| App Bundle (AAB) | ✅ Build configured |
| Unique applicationId | ✅ `com.collegereality.india` |
| Signed release | ⚠️ Needs upload keystore (`key.properties`) |
| Privacy policy URL | ⚠️ Host publicly |
| Data safety | ⚠️ Complete in Play Console |
| Content rating | ⚠️ Complete IARC questionnaire |
| No debug banner | ✅ `debugShowCheckedModeBanner: false` |
| Permissions justified | ✅ Internet, notifications |

---

*Generated for Version 1.0 Production Release.*
