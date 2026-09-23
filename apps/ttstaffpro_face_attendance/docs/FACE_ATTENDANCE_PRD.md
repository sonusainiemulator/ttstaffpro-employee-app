# Face Attendance PRD

## 1. Product overview
TT Staff Pro Face Attendance is a single-point attendance module for wall-mounted kiosk deployment and employee self-registration. It supports secure face attendance capture without treating face data as a standalone identity source.

## 2. Product vision
Create a reliable face attendance workflow that allows:
- employee self-registration of face data
- approval and review of face registrations by admin
- kiosk-based attendance scanning
- instant attendance event capture with check-in / check-out logic
- reporting of late, early, and staff-wise attendance results
- sync with the main attendance engine used by the HRMS platform

## 3. Target users
### Employee / staff
- register their face in the employee app
- use face attendance when needed
- view attendance and registration status

### Manager / admin
- review face registration requests
- approve, reject, or reset registrations
- monitor kiosk attendance and daily staff reports

### Kiosk operator
- login to the wall-mounted kiosk app
- start scanning flow
- review attendance reports for the selected date

## 4. Functional scope
### Employee app
- face registration eligibility check
- self-registration for face data
- status tracking for approval or rejection
- update or reset face registration

### Admin flow
- list pending and approved registrations
- approve or reject registration requests
- re-enroll employee if required

### Kiosk flow
- company match flow
- master login for kiosk operator
- device registration and heartbeat
- always-on attendance scanning mode
- attendance event upload and sync
- offline queue and retry
- daily report view

## 5. Product rules and privacy boundaries
- employee account remains the primary identity source
- face image is used as a presence confirmation step
- invalid or absent face attempts must fail safely
- no biometric matching should be used as a replacement for account identity
- all data must remain auditable and reviewable by administrators

## 6. Functional requirements
### Identity and access
- user must be authenticated before face registration
- kiosk master login must be protected by valid credentials
- device registration must be tracked per kiosk
- tenant and company validation must be enforced

### Attendance processing
- each submission must be idempotent
- duplicate attempts must be prevented
- attendance event must resolve to check-in or check-out according to server logic
- attendance must sync into the core attendance engine used by the app

### Reporting
- kiosk report must show date-wise attendance for staff
- report must distinguish in/out and exception states like late or early
- admin must be able to review attendance summaries

### Offline support
- events should be queued when connectivity is lost
- queues must retry when connectivity returns
- retry status must be visible to support/admin users

## 7. Success criteria
- employees can register face attendance quickly
- admin can approve or reject registrations efficiently
- kiosk attendance can complete in seconds without extra steps
- attendance events sync into the main attendance module
- late/early detection appears in reports
- the flow supports offline queue and recovery

## 8. Out of scope
- full biometric identity matching beyond kiosk attendance context
- continuous tracking or real-time surveillance
- automatic employment decisions from face data alone

## 9. Summary
The Face Attendance module is a practical, privacy-conscious attendance solution for organizations that need fast single-point attendance capture using a dedicated kiosk and employee self-registration.
