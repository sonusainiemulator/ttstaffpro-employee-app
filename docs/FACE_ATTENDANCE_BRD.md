# Face Attendance BRD

## 1. Business need
Organizations need a fast and reliable way to record attendance at fixed points such as gates, workstations, classrooms, or kiosk devices. Manual check-in causes delays, attendance mismatches, and poor auditability.

TT Staff Pro Face Attendance addresses this by enabling a dedicated kiosk attendance flow with employee self-registration and admin-approved face enrollment.

## 2. Business goals
- reduce manual attendance time and queue delays
- improve reliability of staff attendance tracking
- support kiosk-based single-point attendance collection
- give admins and managers a clear view of attendance records and exceptions
- keep the product aligned with broader HRMS attendance workflows

## 3. Business stakeholders
### Staff / employees
Need a simple way to register a face and use a fast check-in/out process.

### Managers / HR admins
Need reliable attendance records, approval controls, and review of exceptions.

### Kiosk operators
Need a device that stays active, is easy to use, and supports repeated attendance scanning.

### Business owner / organization
Need a scalable attendance workflow that integrates with the existing HRMS platform without forcing a full redesign.

## 4. Business requirements
### 4.1 Registration workflow
- employees should be able to self-register their face from the employee app
- an admin should review and approve or reject the registration request
- employees should be able to retry or re-enroll after reset

### 4.2 Kiosk attendance workflow
- the kiosk should be able to match the company and allow master login
- the kiosk should remain active without sleeping during attendance scanning
- the kiosk should support repeated face-based attendance checks
- attendance events should be processed and stored in the central attendance data model

### 4.3 Reporting and visibility
- managers should see late and early attendance patterns
- staff-wise reports should be visible for a selected date
- admin should be able to identify failed or invalid recognition events

### 4.4 Reliability requirements
- offline attendance attempts should be queued and retried without losing records
- no duplicate attendance should be accepted for the same action
- the attendance system should remain consistent with the core attendance engine

## 5. Business rules
- the employee account remains the primary identity for the employee
- face data is used for presence confirmation, not as a standalone identity record
- if recognition is not valid, the system must reject the event and keep audit data
- only approved or eligible profiles should be used in real attendance capture
- the app must support review and exception handling for invalid or failed attempts

## 6. KPI and success measures
- reduced queue time for staff check-in and check-out
- higher attendance compliance and lower manual intervention
- fewer invalid or duplicate records
- better visibility into late and early attendance patterns
- improved traceability of attendance actions for audits and investigations

## 7. Implementation alignment
The current implementation already reflects the expected business flow:
- company match and kiosk login flow
- employee face registration and admin review flow
- attendance event capture and reporting
- kiosk wake lock and always-on behavior
- offline queue and retry mechanism
- integration with the main attendance module

## 8. Phase priorities
### Phase 1
- stable self-registration and admin review flow
- base kiosk login and company matching
- attendance event capture and status updates

### Phase 2
- stronger reporting and dashboard insights
- device health and admin audit improvements
- offline retry optimization and deduplication controls

### Phase 3
- deeper integration with broader HR and manager approvals
- more advanced reporting and exception handling

## 9. Business conclusion
Face Attendance is a valuable module for organizations that need fast, physical attendance scanning at fixed points without relying on manual attendance sheets. It supports employee self-enrollment, admin review, kiosk-based recognition, and direct integration with TT Staff Pro attendance data. This makes it both operationally useful and commercially relevant for HR and attendance-driven organizations.
