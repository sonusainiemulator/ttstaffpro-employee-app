# Business Requirements Document (BRD)

## 1. Business purpose
TT Staff Pro is an employee-centric HRMS platform designed to simplify attendance tracking, payroll access, leave requests, document workflows, and operational communication for employees, managers, and admins.

The business goal is to improve HR efficiency, reduce manual admin work, and give employees easier self-service access to core HR processes.

## 2. Business objectives
- reduce manual attendance follow-up and reconciliation
- improve employee transparency regarding attendance and payroll
- reduce dependency on paper-based HR processes
- enable service delivery for multi-tenant organizations
- provide flexible app features through module configuration
- extend the product with notifications and alerts in the next phase

## 3. Business stakeholders
### Employees
Need a convenient way to:
- mark attendance
- check status and history
- view payroll and leave-related information
- request HR-document workflows
- receive operational updates and reminders

### Managers and admins
Need a way to:
- monitor staff attendance and anomalies
- review regularization and exceptions
- approve or monitor internal requests
- keep employees informed through timely alerts

### Organization owner / business leadership
Need a system that:
- scales across employees and tenant groups
- enables modular HR operations
- supports future notification and escalation workflows
- improves employee engagement and accountability

## 4. Business requirements
### 4.1 Employee usability
- Employees should be able to check in and check out from the mobile app.
- Employees should be able to view attendance history and statuses.
- Employees should be able to access leave, payroll, notice, and document data.
- Employees should be able to receive confirmation or reminders for attendance milestones.

### 4.2 Operational monitoring
- Admins should be able to review flagged attendance cases such as late check-in or early checkout.
- Managers should be able to act on leave and other approval-driven processes.
- App-level module toggles should allow organizations to enable or disable features based on business needs.

### 4.3 Notification requirements
The next business phase requires:
- WhatsApp alerts for operational attendance events
- FCM push notifications for app users
- in-app notification history for read/unread tracking
- admin and employee-specific alert routing

### 4.4 System flexibility
- Features should be configurable through backend settings rather than hardcoded app logic.
- The application should support multiple organizations/tenants.
- The HR platform should allow future additions like AI workflows, deeper analytics, and approval automation.

## 5. Business rules
- Attendance must be treated as a core operational workflow.
- Notifications should be meaningful and event-based, not noisy or spam-like.
- Operational alerts should prioritize employee/admin action, especially for exceptions.
- WhatsApp should be used for critical communication and escalation.
- App push should support real-time mobile engagement inside the app ecosystem.

## 6. Success criteria
The business is successful when:
- employees can complete attendance tasks without manual follow-up
- managers/admins can act quickly on exceptions
- payroll and leave information is accessible from the app
- notification alerts reduce missed workflows and improve communication
- the product scales cleanly across organizations and departments

## 7. Current implementation status
The current app already includes the core HRMS foundation, especially around:
- attendance operations
- payroll access
- leave and documents
- internal modules and app-level configuration
- notification infrastructure groundwork

The next phase is focused on extending the system with strong attendance event notifications and operational alerting using both WhatsApp and app push mechanisms.

## 8. Recommended next-phase priority
1. attendance event alerts
2. employee/admin WhatsApp notifications
3. FCM push messages and notification center
4. admin summary notifications and exception reporting
5. deduplication and smart notification rules

## 9. Business conclusion
The current product is already practically useful as an HRMS mobile app. The business value of the next phase is not to redesign the app, but to strengthen communication and operational visibility around attendance, with WhatsApp and mobile push notifications working together.
