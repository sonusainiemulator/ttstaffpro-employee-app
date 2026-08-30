# TT Staff Pro Notification Roadmap

## Goal
Add a combined notification system that supports both employee awareness and admin operations for attendance-related events.

## Recommendation
Use both channels together:
- WhatsApp for operational and escalation alerts
- Firebase Cloud Messaging (FCM) for in-app mobile push notifications
- App notification list for history and read status

## Why this matters
Attendance events are time-sensitive. Employees need confirmation after check-in/check-out, and admins need visibility for late or irregular attendance.

## Target use cases
### Employee notifications
- Successful check-in
- Successful check-out
- Late check-in alert
- Missed checkout reminder
- Leave approval/rejection
- Payroll or attendance summary updates

### Admin notifications
- Employee checked in
- Employee checked out
- Late arrival
- Early exit
- Missed checkout
- Attendance anomaly
- Pending approval requests

## Phase 1: Attendance event alerts
- Employee check-in notification
- Employee check-out notification
- Admin notification for each attendance event
- Late arrival alert
- Early checkout alert
- Missed checkout alert

## Phase 2: Mobile push + in-app notification center
- Save FCM token per user
- Send push to relevant employee/admin
- Maintain unread state
- Show notification history in app
- Add notification badge count

## Phase 3: Admin dashboard alerts
- Daily attendance summary
- Absents list
- Late employees
- Early leavers
- Pending approvals and regularizations

## Phase 4: Smart rules and deduplication
- Do not send duplicate notifications
- Send WhatsApp only for exceptions or important events
- Send push only for high-value events
- Add user notification preferences
- Add quiet hours or business-hour filtering

## Backend requirements
- Event is triggered on attendance action
- Notification payload includes: user_id, target_role, type, message, timestamp, related entity id
- One event can trigger multiple channels: WhatsApp + FCM + internal app notification
- Every notification should be logged and auditable

## Database considerations
Required fields for each notification:
- id
- user_id
- target_user_id
- role
- type
- title
- message
- channel (whatsapp, fcm, in_app)
- status (queued, sent, delivered, failed)
- created_at
- read_at
- is_read

## Success criteria
- Attendance actions result in immediate employee/admin alerts
- No duplicate notifications for a single event
- Admin can review attendance anomalies quickly
- Employees can see notification history in the app
- WhatsApp becomes an escalation channel, not the only communication path

## Recommended next implementation order
1. check-in / check-out notifications
2. late / early / missed alerts
3. FCM token registration and push delivery
4. notification list and read status
5. admin summaries
6. dedupe and rules engine

## Notes
This should be treated as a Phase 2 project enhancement, not a quick patch. It adds measurable operational value and significantly improves HRMS adoption.
