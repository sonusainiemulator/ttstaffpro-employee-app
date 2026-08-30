# TT Staff Pro Master Project Backlog

## 1. Product vision
Build and evolve TT Staff Pro into a complete HRMS + attendance platform that covers:
- employee self-service
- attendance and face attendance
- payroll and leave
- admin visibility and alerts
- notification automation for operational events

## 2. Current state summary
The app already includes:
- HRMS self-service screens
- attendance process and history
- payroll, leave, document, expense, and asset modules
- face attendance registration and kiosk flow
- Firebase messaging and app notification infrastructure
- backend-ready notification and attendance event patterns

## 3. Next-phase product priorities
### Priority 1 — Attendance notification system
- trigger attendance alerts for check-in, check-out, late, early, missed checkout
- send WhatsApp alert to configured recipients
- send FCM push to users with app tokens
- create in-app notification records
- store read/unread and audit logs

### Priority 2 — Face attendance completion
- complete kiosk company login + master operator flow if not fully finished
- finalize offline queue and retry reliability
- make daily kiosk report consistent with employee attendance model
- validate server-side attendance sync into core attendance engine

### Priority 3 — Admin operations and dashboard
- add admin attendance summary reports
- add alerts for exceptions, missing check-outs, late arrivals
- add approval queue visibility and review actions
- expose operational dashboard widgets to managers

### Priority 4 — Smart notification rules and optimization
- deduplicate duplicate triggers
- avoid spam via business-hour filters and preference settings
- support silent vs urgent notification levels
- automate escalation rules for exceptions

## 4. Backlog by workstream

### A. Backend / API work
#### A1. Attendance notification service
- create notifications table
- create notification_log table
- create user_devices table
- build AttendanceNotificationService
- add idempotency key handling
- add queue worker / async process

#### A2. Attendance event triggers
- after check-in send employee/admin messages
- after check-out send employee/admin messages
- late check-in rule and alert
- early checkout rule and alert
- missed checkout reminder rule

#### A3. Face attendance backend finish
- complete kiosk company match endpoints
- complete kiosk login and device registration
- finalize report endpoint
- validate attendance event integration with main attendance engine

#### A4. Notification delivery APIs
- register FCM token
- fetch notification history
- mark notification as read
- send WhatsApp alert payload to provider gateway
- log status and retry failures

### B. Flutter app work
#### B1. Mobile push support completion
- save FCM token on login/register
- listen for foreground/background messages
- display notification badges and in-app notification list
- handle tap behavior for notification types

#### B2. Attendance notification UX
- show toast and in-app notification after check-in/out
- show late/early/missed checkout warning states
- add notification center in dashboard and settings when needed

#### B3. Face attendance app polishing
- improve kiosk screen stability and no-sleep behavior
- finalize offline sync UX
- validate daily kiosk report accuracy
- improve admin review screens and statuses

### C. Admin / manager workflow
#### C1. Attendance exception dashboard
- list late employees
- list early leavers
- list missed checkout employees
- list absent employees for today

#### C2. Approvals visibility
- approval counts
- pending regularization items
- admin shortlist of requests requiring action

### D. Product QA and release work
- test all notifications with real event flows
- test WhatsApp + FCM combination without duplicates
- test offline queue behavior for face attendance
- test module gating and role permissions
- prepare release checklist and app version notes

## 5. Detailed task list

### Phase 1 — Notification foundation
1. Review existing Firebase setup in [lib/main.dart](lib/main.dart)
2. Implement user device registration for FCM
3. Define notification database schema
4. Create backend notification service for attendance events
5. Add WhatsApp integration layer for attendance alerts
6. Add in-app notification saving and read status support
7. Test employee and admin message flows

### Phase 2 — Face attendance stabilization
1. Confirm kiosk API contract and tenant behavior
2. Validate device registration and heartbeat flow
3. Confirm attendance event sync into core attendance engine
4. Validate kiosk report date-wise data
5. Complete offline sync and conflict handling
6. Perform QA on kiosk always-on behavior

### Phase 3 — Admin dashboard and exception monitoring
1. Build admin summary view for attendance anomalies
2. Add missing check-out and early checkout summaries
3. Add manager approval overview
4. Add quick links from home dashboard
5. Prepare summary cards and charts

### Phase 4 — Smart notification rules
1. Add notification dedupe by event id
2. Add notification preferences for employee/admin
3. Add business-hour / quiet-hours handling
4. Add retry queue and failure monitoring
5. Add escalation rules for critical events

## 6. Suggested milestone schedule
### Milestone 1: Attendance alert foundation
- backend schema
- attendance event trigger logic
- WhatsApp + FCM dispatch
- notification history

### Milestone 2: Face attendance completion
- kiosk app stabilization
- offline queue reliability
- admin workflow and reporting

### Milestone 3: Admin insights
- summary dashboards
- attendance exception cards
- manager approval overview

### Milestone 4: Notification optimization
- dedupe and smart rules
- user preferences
- escalation logic and monitoring

## 7. Definition of done
A task is done only when:
- backend logic is implemented and validated
- app integration is tested on a real device/simulator
- duplicate sends are prevented
- notification history is accurate
- admin/employee workflows are verified
- edge cases such as offline state and failed send are covered

## 8. Notes for future agent work
- keep this backlog as the source of truth for next implementation
- prefer business-critical event notifications over generic alerts
- keep WhatsApp and FCM as complementary channels, not competing duplicates
- maintain a strong separation between app notification logic and kiosk attendance logic
