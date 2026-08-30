# Face Attendance PRD

## 1. Product overview
TT Staff Pro Face Attendance is a single-point attendance module designed for wall-mounted kiosk deployments and employee self-registration. It supports secure face-based attendance capture for staff and employees without using biometric identity matching as the primary source of identity.

The product uses the employee account as the primary identity and uses a face registration step as a local presence confirmation mechanism. The kiosk is designed for shared, always-on attendance points such as gates, classrooms, workplaces, or manager stations.

## 2. Product vision
Create a reliable face attendance workflow that allows:
- employee self-registration of face data
- approval and review of face registrations by admin
- kiosk-based attendance scanning on a dedicated device
- instant attendance event capture with check-in/check-out logic
- reporting of late, early, and staff-wise attendance records
- sync with the main attendance engine used by the HRMS system

## 3. Target users
### Employee / staff user
- register their face in the employee app
- use the face attendance flow when needed
- view attendance status and registration status

### Manager / admin
- review face registration requests
- approve, reject, or reset employee registrations
- monitor kiosk attendance and per-day staff reports

### Kiosk operator / administrator
- login to the wall-mounted kiosk app
- start attendance scanning sessions
- monitor live attendance events
- review reports for the selected date

## 4. Core product goals
- support fast face attendance at a single fixed point
- keep enrollment and recurring attendance simple for staff
- prevent duplicate or replayed attendance submissions
- keep app behavior resilient in offline or low-connectivity environments
- sync attendance into the existing employee app attendance module
- provide auditability for admin review

## 5. Functional scope
### 5.1 Employee app features
- face registration eligibility check
- self-registration for face data
- status tracking for approval or rejection
- update or reset of face registration if needed
- ownership of their own registration and profile data

### 5.2 Admin features
- list approved, pending, rejected, and reset registrations
- approve or reject employee registration requests
- trigger re-enrollment flow when necessary
- review face attendance dashboard and audit data

### 5.3 Kiosk app features
- company match and kiosk login flow
- master login for the kiosk operator
- device registration and heartbeat
- always-on attendance scanning mode
- face recognition / presence flow for staff attendance
- attendance event upload and sync
- daily staff attendance report
- offline event queue and retry when connectivity returns

## 6. Product rules and privacy boundaries
The face attendance project follows a privacy-safe approach:
- the employee account remains the primary identity
- face data is not treated as the master identity source
- camera-based presence is used only as a local confirmation step
- if the face is not present, the system should fail safely and not create a false attendance record
- no biometric identity database should be treated as a full-person recognition system
- all data must be auditable and reviewable by admin users

## 7. User journeys
### 7.1 Employee face registration
1. User opens the face registration screen.
2. App checks if registration is allowed.
3. User captures face images according to the app workflow.
4. Backend stores the registration request in pending or approved state.
5. Admin reviews and approves or rejects the request.
6. The user can retry or re-register after reset.

### 7.2 Kiosk attendance scanning
1. Kiosk operator selects company and logs in.
2. Device registers and sends heartbeat.
3. Operator starts scanning flow with screen lock/wakelock enabled.
4. Staff member stands in front of the kiosk.
5. Camera captures a face presence or recognition attempt.
6. Backend validates and records attendance event.
7. Attendance is reflected in the main attendance system.
8. Daily report updates for the selected date.

## 8. Functional requirements
### Identity and access
- user must be authenticated before using face registration
- kiosk master login must be protected by valid credentials
- device registration must be tracked per kiosk
- backend must validate request ownership and tenant association

### Attendance processing
- each submission must be idempotent
- duplicate attempts must be prevented
- attendance event must resolve to check-in or check-out according to server logic
- attendance event must sync into the existing attendance engine used by the HRMS

### Reporting
- kiosk report must show date-wise attendance for staff
- report must distinguish in/out results and exceptions like late/early
- admin must be able to review daily attendance summaries

### Offline support
- face attendance attempts must be queued locally when connectivity fails
- the queue must be retried automatically once connectivity returns
- retry status must be visible to support/admin users

## 9. Non-functional requirements
- kiosk app must remain active and not sleep during attendance activity
- app should work on Android tablet devices with camera access and stable connectivity
- app should support local persistence for pending events
- device health information should be available for admin monitoring
- system should be resilient to incomplete or failed recognition attempts

## 10. Success criteria
- employees can register face attendance with minimal friction
- admin can approve or reject registration requests quickly
- kiosk attendance can complete in seconds without repeated manual steps
- attendance data is synced into the main attendance module
- late/early detection is reflected in report logic
- the flow supports offline queue and retry recovery

## 11. Out of scope for this version
- full biometric identity matching or government-style biometric enrollment
- continuous tracking or background surveillance
- automatic employment decision-making from face data alone
- full face recognition outside the kiosk attendance use case

## 12. Summary
The Face Attendance module is a practical, privacy-conscious attendance solution for organizations that need dedicated kiosk-based check-in/out, employee self-registration, and admin approval workflows. It integrates with the broader TT Staff Pro platform while preserving the employee account as the source of identity and using face presence as a local verification step.
