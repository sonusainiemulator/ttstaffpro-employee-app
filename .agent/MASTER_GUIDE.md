# TT Staff Pro Master Agent Guide

## 1. Project overview
This repository contains the main TT Staff Pro HRMS app and the face-attendance kiosk project under `apps/ttstaffpro_face_attendance`.

The app is built around:
- employee self-service HRMS workflows
- attendance management
- payroll, leave, expenses, assets, and notices
- admin monitoring and approvals
- notifications and future alert workflows
- face attendance for kiosk-based attendance capture

## 2. Mandatory rules
- Read AGENTS.md before starting tasks.
- Keep work aligned with the architecture already in the repo.
- Do not create parallel systems when an existing pattern already fits the requirement.
- Do not commit secrets, credentials, or private configuration.
- Keep every fix minimal, targeted, and easy to review.
- Validate with the smallest relevant command before completion.

## 3. Required working behavior
- Prefer root-cause fixes over symptom-level patches.
- Check tenant, user, and role context before changing attendance or approval logic.
- Keep attendance and notification processes idempotent.
- Preserve app security, reliability, and user trust.
- Make changes in a way that is maintainable by future agents.

## 4. High-risk domains
- attendance check-in and check-out workflows
- notification sending and unread tracking
- face attendance submissions and queues
- device registration and token validation
- admin approval and audit flows
- module gating and permissions

## 5. Standard development workflow
1. Read the relevant docs and source files.
2. Confirm the business rule and expected outcome.
3. Reproduce or inspect the failing path.
4. Fix the root cause with minimal edits.
5. Validate the changed behavior.
6. Review final git diff and ensure only intended files changed.

## 6. Product alignment
- main app: HRMS employee engagement and operational support
- face-attendance app: single-point attendance and staff registration review
- both should remain consistent with the core attendance engine and company/tenant rules

## 7. Security and quality rule set
- no hardcoded secrets
- no debug logs with sensitive data
- no unverified client-side business logic for attendance, approvals, or payments
- no duplicate notification triggers without dedupe logic
- no change that weakens auditability or offline integrity

## 8. Release confidence
Before signing off, confirm:
- the relevant work was tested or validated
- duplicates and edge cases were checked
- no sensitive data leak was introduced
- the final change matches the task and business requirement
- only intentional files remain changed

## 9. Reminder
Future work should stay practical, secure, and aligned with TT Staff Pro’s real business workflows. The app should be reliable for employees, managers, admin staff, and kiosk operators alike.
