# Laravel Notification Backend Plan

## Objective
Build the backend layer that sends attendance alerts through WhatsApp, app push, and in-app notification history for the TT Staff Pro platform.

## 1. Core backend architecture

### Recommended service structure
- `AttendanceNotificationService`
- `NotificationDispatcher`
- `NotificationChannel` interface with implementations:
  - `WhatsAppChannel`
  - `FirebasePushChannel`
  - `InAppNotificationChannel`
- `NotificationEventFactory`
- `NotificationRepository`

### Delivery flow
1. attendance event is saved
2. backend identifies event type and affected users
3. notification service creates internal notification record
4. dispatcher sends to all enabled channels
5. result is recorded in `notification_logs`
6. failed sends go to retry queue or error log

## 2. Database design

### notifications table
- id
- user_id
- target_user_id
- role
- event_type
- title
- message
- channel
- status
- read_at
- created_at
- updated_at

### notification_logs table
- id
- notification_id
- channel
- recipient_id
- recipient_phone
- external_message_id
- sent_at
- delivered_at
- status
- error_message
- created_at

### user_devices table
- id
- user_id
- device_token
- platform
- is_active
- last_used_at
- created_at
- updated_at

### Optional idempotency table
- id
- event_key
- event_type
- status
- created_at

## 3. Notification event types
- `attendance.check_in`
- `attendance.check_out`
- `attendance.late_check_in`
- `attendance.early_checkout`
- `attendance.missed_checkout`

## 4. Event processing rules

### Employee check-in
- create notification for employee
- create notification for relevant manager/admin
- send WhatsApp alert to configured recipients
- send FCM push if user has a valid device token
- record internal app notification

### Employee check-out
- same as above for checkout

### Late check-in
- notify employee and manager/admin
- use a stronger alert message and route to escalation if needed

### Early checkout
- notify employee and manager/admin
- log as operational anomaly

### Missed checkout
- send reminder to employee
- send admin reminder if configured

## 5. Message template examples

### Employee check-in success
Title: `Check-in Successful`
Message: `You checked in at 9:15 AM.`

### Admin check-in alert
Title: `Employee Checked In`
Message: `Rahul checked in at 9:15 AM.`

### Late check-in
Title: `Late Check-in Alert`
Message: `You checked in late at 9:40 AM.`

### Missed checkout
Title: `Missed Checkout Reminder`
Message: `You have not checked out today. Please complete your checkout.`

## 6. API plan

### POST /api/V1/notifications/register-device
Request:
- user_id
- device_token
- platform

Response:
- success
- device_id

### GET /api/V1/notifications
Query params:
- unread_only
- type
- date_from
- date_to

### POST /api/V1/notifications/mark-read
Request:
- notification_id

### POST /api/V1/notifications/send-attendance-alert
Request:
- event_type
- employee_id
- attendance_id
- notify_employee
- notify_admin
- message_title
- message_body

### POST /api/V1/notifications/whatsapp/test
For provider testing only.

## 7. FCM implementation plan
- store one active token per device
- update token on login or new device registration
- send push payload with title/body/data payload
- include `event_type`, `attendance_id`, and `user_id` in payload
- if token is invalid, deactivate it and log the failure

## 8. WhatsApp integration plan
- use a provider adapter for your current WhatsApp module
- standardize payload to:
  - recipient_phone
  - message
  - template_name
  - metadata
- log the provider response ID
- do not send duplicate messages for same attendance event

## 9. Security and reliability
- use idempotency key per attendance action
- prevent duplicate sends when retry or webhook is retried
- store provider response IDs for auditing
- keep retry and dead-letter handling for failed messages
- do not log raw sensitive data or full personal details in logs

## 10. Acceptance criteria
- check-in triggers employee + admin notification path
- check-out triggers employee + admin notification path
- late/early/missed event detection creates proper alerts
- FCM messages are sent only when valid device token exists
- WhatsApp sends a single message per event unless intentionally duplicated by business rule
- app notification records remain visible in notification history
- failed sends are logged and can be retried

## 11. Recommended implementation order
1. create notification tables
2. add device registration API
3. create central dispatcher service
4. hook attendance check-in/out save flow
5. add WhatsApp adapter and FCM adapter
6. add notification history API
7. add retry / dedupe logic
8. run end-to-end QA

## 12. Notes
This phase is the highest-value backend addition for the product because it connects attendance data to real-time communication for both employee and admin operations.
