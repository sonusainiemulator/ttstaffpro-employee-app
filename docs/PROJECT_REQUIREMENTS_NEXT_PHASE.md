# Next Project Requirements

## Product objective
Add a combined notification system for attendance events to support employees and admins with instant updates.

## Functional requirements
- Trigger notifications for employee check-in and check-out events
- Send alerts for late check-in, early checkout, and missed checkout
- Notify admin users when attendance anomalies occur
- Send WhatsApp alerts to configured admin/owner/employee recipients
- Send Firebase push notifications to app users
- Save notifications in the app notification history
- Mark notifications as read/unread
- Support notification deduplication for the same event

## Non-functional requirements
- Fast delivery for time-sensitive events
- Low duplication and message spam
- Clear message templates for employee and admin
- Scalable event-driven backend design
- Logging for audit and troubleshooting

## Role-based behavior
### Employee
- Receives confirmation for successful check-in/check-out
- Receives reminders for missed checkout or late attendance
- Receives approval result notifications

### Admin
- Receives attendance alerts in real time
- Receives exception notifications for irregular attendance
- Receives approval queue alerts

## Backend event triggers
- attendance.check_in
- attendance.check_out
- attendance.late_check_in
- attendance.early_checkout
- attendance.missed_checkout
- leave.approved
- leave.rejected

## Message examples
- Employee: "You checked in successfully at 9:15 AM."
- Admin: "Rahul checked in at 9:15 AM."
- Admin: "Riya left early today at 5:00 PM."
- Employee: "You forgot to check out today. Please do so immediately."

## Technical expectation
- WhatsApp module remains business-critical alerting
- FCM is used for app-native user notifications
- Notification data is stored for history and reconciliation
- Event-driven backend architecture should handle future expansion to payroll, leave, expense, and HR approvals

## Milestones
### Milestone 1
Attendance event triggers and WhatsApp alerts

### Milestone 2
FCM push notification support and notification center

### Milestone 3
Admin dashboard alert summaries and approvals

### Milestone 4
Smart deduplication and notification preferences

## Reminder for future AI agent
When continuing this project, review the notification roadmap and requirements first. Prefer minimal, high-value event notifications over generic alerts. Use WhatsApp for operational alerts and FCM for app-level user notifications.
