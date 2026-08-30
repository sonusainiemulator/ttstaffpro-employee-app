# TT Staff Pro Next Sprint Tasks

## Sprint objective
Deliver the first operational notification system and stabilize the face-attendance module for production use.

## Sprint 1: Attendance notification backend

### Task 1.1 — notification schema
- create `notifications` table
- create `notification_logs` table
- create `user_devices` table
- add event type, channel, recipient, and read status fields

### Task 1.2 — attendance event trigger service
- add `AttendanceNotificationService`
- trigger on check-in, check-out, late check-in, early checkout, missed checkout
- generate idempotency keys for each event
- use a single central dispatcher for all notifications

### Task 1.3 — WhatsApp integration
- add WhatsApp provider adapter
- send critical alerts to employee/admin/owner recipients
- log send status and failure payloads
- support retry queue for failed sends

### Task 1.4 — FCM push registration and delivery
- register mobile device tokens
- send FCM push to employee/admin when token exists
- store in-app notification record for all recipients
- mark read/unread state in notification history

### Task 1.5 — validation and QA
- test check-in and check-out flows end to end
- validate no duplicate notifications
- validate failure and retry handling
- verify admin and employee message routing

## Sprint 2: Face attendance completion

### Task 2.1 — kiosk device lifecycle
- verify company match and master login flow
- confirm device registration and heartbeat stability
- validate session and token persistence

### Task 2.2 — sync and offline behavior
- verify offline pending event queue
- validate retry after connectivity is restored
- test duplicate event prevention
- confirm sync into core attendance engine

### Task 2.3 — report generation
- validate daily attendance report accuracy
- check late/early/in/out status mapping
- verify employee and admin reporting aligns with existing attendance rules

### Task 2.4 — admin review flow
- test approve/reject/reset actions for face registrations
- verify registration state visibility
- confirm stale or invalid registrations are handled safely

## Sprint 3: Admin dashboard and monitoring

### Task 3.1 — exception dashboard
- list late check-ins
- list early check-outs
- list missed check-outs
- list absent employees for the day

### Task 3.2 — approvals queue
- show pending regularization or approval items
- classify high-priority events
- link to employee or attendance details

### Task 3.3 — summary cards
- today’s attendance count
- current exceptions
- total pending approvals
- users needing action

## Definition of done for each sprint
- feature works end to end
- duplicate risk is controlled
- auth and tenant logic are respected
- no sensitive data is exposed
- relevant validation command or test was run
- documentation is updated when needed
