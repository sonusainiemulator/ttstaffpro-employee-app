# Phase 1 Backend Requirements

## Objective
Implement attendance-triggered notifications for employees and admins using both WhatsApp and app push notifications.

## Scope
Phase 1 covers only the highest-value attendance events:
- check-in
- check-out
- late check-in
- early checkout
- missed checkout

## Core business rule
When an attendance event is processed, the backend must trigger:
1. internal notification record creation
2. WhatsApp notification sending for configured recipients
3. FCM push notification sending for app users when device token exists
4. audit/logging for delivery status

## Notification channels
### 1) WhatsApp
Use for operational and escalation alerts.

Recommended recipients:
- employee owner
- assigned manager/admin
- company owner when configured

### 2) FCM Push
Use for mobile app users.

Recommended recipients:
- employee
- admin/manager if they have the app installed and token registered

### 3) In-app notification record
Always store a record in the app notification table for history and unread tracking.

## Event types
- attendance.check_in
- attendance.check_out
- attendance.late_check_in
- attendance.early_checkout
- attendance.missed_checkout

## Trigger points
### Check-in
Trigger when employee checks in successfully.

Send:
- employee confirmation
- admin/manager notification

### Check-out
Trigger when employee checks out successfully.

Send:
- employee confirmation
- admin/manager notification

### Late check-in
Trigger when check-in time exceeds the configured allowed time.

Send:
- employee warning alert
- admin/manager alert

### Early checkout
Trigger when checkout happens before required time.

Send:
- employee notice
- manager/admin alert

### Missed checkout
Trigger when employee has checked in but has not checked out by the configured cutoff time.

Send:
- employee reminder
- admin/manager reminder

## Notification payload contract
Each notification event should include:
- event_type
- employee_id
- employee_name
- company_id
- branch_id
- attendance_id
- check_in_time
- check_out_time
- trigger_time
- message_title
- message_body
- recipient_type (employee|admin|owner|manager)
- recipient_id
- channel (whatsapp|fcm|in_app)
- status
- created_at

## Backend processing flow
1. Attendance action is saved to the attendance table.
2. Backend evaluates event type and rules.
3. Backend chooses target recipients.
4. Backend creates internal notification row(s).
5. Backend sends WhatsApp message to configured recipients.
6. Backend sends FCM push to app users with active tokens.
7. Backend records each result as queued, sent, delivered, or failed.
8. Failed events should be retried or logged for manual follow-up.

## API requirements
### Endpoint: POST /api/V1/attendance/check-in-out
Request body:
- employee_id
- action (check_in|check_out)
- latitude
- longitude
- device_id
- source (app|kiosk|web)

Response:
- attendance_id
- action
- status
- check_in_time
- check_out_time
- notification_triggered

### Endpoint: POST /api/V1/notifications/send-attendance-alert
Purpose: trigger a notification event manually or from a queue worker.

Request body:
- event_type
- employee_id
- attendance_id
- notify_admin
- notify_employee
- message_title
- message_body

### Endpoint: POST /api/V1/notifications/fcm/register
Purpose: register app token for user.

Request body:
- user_id
- device_token
- platform (android|ios)

### Endpoint: GET /api/V1/notifications
Purpose: fetch app notification history for a user.

Optional filters:
- unread_only
- type
- date_from
- date_to

## Database requirements
### notifications table
Columns:
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
Columns:
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
Columns:
- id
- user_id
- device_token
- platform
- is_active
- last_used_at
- created_at
- updated_at

## Message templates
### Check-in success employee
Title: Check-in Successful
Body: You checked in at {time}.

### Check-in success admin
Title: Employee Checked In
Body: {employee_name} checked in at {time}.

### Check-out success employee
Title: Check-out Successful
Body: You checked out at {time}.

### Late check-in
Title: Late Check-in Alert
Body: You checked in late at {time}. Please contact your manager if needed.

### Early checkout
Title: Early Checkout Alert
Body: You checked out early at {time}. Please review your attendance.

### Missed checkout
Title: Missed Checkout Reminder
Body: You have not checked out yet today. Please complete your checkout.

## Business rules
- A check-in event should not send duplicate alerts if retried by the same request.
- Use idempotency key per attendance action to prevent duplicate notification sends.
- If a user has no device token, skip FCM but still send WhatsApp and app notification record.
- If no admin is configured, use fallback owner/manager recipients.
- Maintain a notification queue so event processing is asynchronous when needed.

## Acceptance criteria
- When an employee checks in, a notification is logged and sent to the employee and relevant admin.
- When an employee checks out, a notification is logged and sent to the employee and relevant admin.
- When a check-in exceeds the acceptable time window, a late alert is triggered.
- When check-out happens before allowed time, an early checkout alert is triggered.
- When an employee remains checked in past the configured cutoff, a missed checkout reminder is sent.
- All events can be reviewed from the notification history screen in the app.

## Phase 1 out of scope
- payroll reminders
- leave notifications
- advanced preference rules
- recurring schedules
- complex admin dashboards

## Recommended implementation approach
- Use event-driven background jobs or queue workers for notification delivery.
- Put notification logic in a dedicated service class: AttendanceNotificationService.
- Use a single central function that dispatches to multiple channels.
- Keep the notification templates configurable in the database or config file.

## Suggested next step
Create the Laravel notification service and the database tables for notifications and user devices, then wire attendance event triggers to that service.
