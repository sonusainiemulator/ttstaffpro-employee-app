# Face Attendance Developer Pre-Release Checklist

## 1. Security review
- [ ] No secrets or credentials are stored in source files
- [ ] No raw personal data or face data is logged in debug output
- [ ] API requests use approved auth headers and tenant context
- [ ] Device token and master token handling is secure and validated
- [ ] Server-side validation is trusted over client-side assumptions

## 2. Attendance logic review
- [ ] Check-in and check-out actions are idempotent
- [ ] Duplicate scan submissions are prevented
- [ ] Attendance records sync correctly with the main attendance engine
- [ ] Late and early timing rules are consistent with the backend logic
- [ ] Invalid face detection results do not create fake attendance events

## 3. Kiosk reliability
- [ ] Screen stays awake during attendance scanning
- [ ] Camera and permission flow are stable
- [ ] Device registration and heartbeat still work after app restart
- [ ] Offline queue is retried correctly after connectivity is restored
- [ ] No scan sequence fails due to stale state or stale token data

## 4. Admin and registration flow
- [ ] Face registration eligibility logic is correct
- [ ] Approve / reject / reset actions still work
- [ ] Pending and approved states are displayed correctly
- [ ] Admin review screens remain consistent with backend results

## 5. Quality checks
- [ ] App builds with the relevant Flutter command
- [ ] No obvious lint or analyzer errors in changed files
- [ ] Relevant tests pass or have been updated
- [ ] The issue is reproduced and fixed at the root cause level
- [ ] No broad or unrelated refactor was introduced

## 6. Release confidence
- [ ] Basic end-to-end flow tested: login → scan → upload → sync → report
- [ ] Offline retry path tested at least once
- [ ] Duplicate prevention path validated
- [ ] Release notes and doc references are up to date

## Final sign-off
Only proceed to release when all boxes above are verified and the attendance flow is stable in real usage conditions.
