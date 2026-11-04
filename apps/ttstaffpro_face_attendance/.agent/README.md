# Face Attendance Agent Operating Manual

## Purpose
This folder provides reusable guidance for future AI coding agents and developers working on the TT Staff Pro Face Attendance project.

## Project scope
- kiosk app for tablet / wall-mounted attendance
- employee face registration flow
- admin approval and registration review
- attendance sync into the core TT Staff Pro HRMS system
- offline queue and report generation

## Core business rules
- employee account is the primary identity source
- face is a presence confirmation mechanism, not a master identity source
- attendance submissions must be idempotent
- invalid or absent face detection must fail safely
- server-side validation must be trusted over client-side checks
- the final attendance record should stay aligned with the main attendance engine

## Key project files
- app root: apps/ttstaffpro_face_attendance
- lib/**
- test/**
- docs/
- README.md

## Required docs to read before work
- docs/FACE_ATTENDANCE_PLAN.md
- docs/FACE_ATTENDANCE_PRD.md
- docs/FACE_ATTENDANCE_BRD.md
- root project AGENTS.md for git/version rules

## Working standards
- prefer minimal and direct fixes
- avoid broad refactors unless necessary
- keep kiosk behavior stable and always-on during attendance operations
- preserve offline queue reliability
- keep duplicate prevention and auditability in place
- do not log sensitive personal data or raw face data

## Common risk areas
- duplicate attendance submissions
- broken device registration / heartbeat flow
- failed sync when connectivity returns
- late / early detection mismatch with core attendance model
- screen sleep or kiosk inactivity after a scan
- insecure or unvalidated attendance event payloads

## Debugging workflow
1. reproduce the issue
2. trace the full flow: kiosk login → device registration → scan → event upload → sync → report
3. validate against server response contracts and attendance model
4. fix the root cause
5. verify with the smallest relevant test or app check

## Release checklist before final approval
- kiosk still stays awake during scan sessions
- device registration and heartbeat still work
- offline queue retries correctly
- attendance record sync is stable
- no duplicate check-in/out events
- admin registration flow still works
- no secret keys or private credentials are exposed in source
- app build passes the relevant validation command

## Reminder for future agents
Keep the face attendance flow safe, auditable, and consistent with the primary TT Staff Pro attendance model. Do not create a parallel system that bypasses validation or duplicates the main attendance rules.
