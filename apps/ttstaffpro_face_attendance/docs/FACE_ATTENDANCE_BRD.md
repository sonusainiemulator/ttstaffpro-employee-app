# Face Attendance BRD

## 1. Business need
Organizations need a fast and reliable way to record attendance at fixed points such as gates, classrooms, or workstations. Manual attendance causes delays, mismatches, and poor auditability.

TT Staff Pro Face Attendance addresses this by enabling a dedicated kiosk attendance flow with employee self-registration and admin approval.

## 2. Business goals
- reduce manual attendance time and queue delays
- improve employee attendance accuracy
- support kiosk-based single-point attendance capture
- give managers and admins clear attendance exception visibility
- keep the feature aligned with the broader HRMS attendance model

## 3. Business stakeholders
### Staff / employees
Need a simple way to register a face and use a fast attendance process.

### Managers / HR admins
Need reliable attendance records, approval controls, and exception review.

### Kiosk operators
Need a device that stays active and supports repeated attendance scanning.

### Business owner
Need a scalable attendance flow integrated with the HRMS platform.

## 4. Business requirements
### Registration workflow
- employees should be able to self-register their face from the employee app
- admins should review and approve or reject registrations
- employees should be able to retry or re-enroll after reset

### Kiosk workflow
- kiosk should be able to match company and allow login
- kiosk should remain active during attendance scanning
- kiosk should support rapid repeated scans
- attendance events should sync to the central attendance engine

### Reporting and visibility
- managers should see late and early attendance patterns
- daily staff reports should be visible
- admin should be able to review failed or invalid recognition events

### Reliability
- offline attendance attempts should be queued and retried
- duplicate events should be prevented
- the attendance system should remain consistent with the main attendance engine

## 5. Business rules
- employee account remains the primary identity
- face data is used for presence confirmation, not as a standalone identity record
- if recognition is invalid, the event must fail safely
- approved and eligible profiles should only be used in real attendance capture
- invalid attempts must remain auditable

## 6. KPI and success measures
- reduced queue time for attendance check-in/out
- higher attendance compliance and lower manual intervention
- fewer invalid or duplicate records
- better visibility into late and early attendance patterns
- improved auditability and exception tracking

## 7. Implementation alignment
The current implementation already reflects the expected business flow:
- company match and kiosk login
- employee face registration and admin review
- attendance event capture and report generation
- kiosk wake-lock and always-on behavior
- offline queue and retry workflow
- integration with the main attendance module

## 8. Conclusion
Face Attendance is valuable for organizations needing fast physical attendance capture without manual attendance sheets. It supports employee self-registration, admin approval, kiosk-based recognition, and integration with the TT Staff Pro attendance system.
