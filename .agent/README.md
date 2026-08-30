# TT Staff Pro Agent Operating Manual

## Purpose
This folder stores the operating rules, product context, and quality guardrails for future AI coding agents working on the TT Staff Pro project.

## Scope
This project includes:
- main HRMS employee app at the repository root
- face attendance kiosk app under `apps/ttstaffpro_face_attendance`
- Laravel backend at https://ttstaffpro.in/api/V1/

## Mandatory first step for every task
Before writing or editing code, read:
- AGENTS.md
- CLAUDE.md if relevant
- the product documentation in the docs folder
- the most relevant skill file for the workstream

## Core project rules
- do not bypass the existing architecture
- prefer current repo patterns over creating new parallel implementations
- keep business logic consistent with the attendance model and tenant context
- never commit secrets or credentials
- keep fixes minimal, targeted, and production-safe
- validate with the smallest relevant command before claiming success

## Workstreams covered
- HRMS employee app features
- attendance, payroll, leave, expenses, documents, notices, assets
- notification and messaging flow
- face attendance kiosk workflow
- admin approval and reporting flows

## Key directories
- lib/
- apps/ttstaffpro_face_attendance/
- docs/
- .agent/
- test/

## Security and quality rules
- never hardcode API keys, tokens, or secrets
- do not log personal or sensitive user data
- do not trust client-side checks for financial, attendance, or approval decisions
- prefer idempotent and auditable logic for attendance and notifications
- keep retry, queue, and offline behavior safe and predictable

## Pre-release checklist
Before completion, verify:
- the relevant app/build still works
- no duplicate or repeated actions were introduced
- attendance and notification logic remained consistent
- module gating and role logic still behave correctly
- no sensitive data leakage or debug logs remain
- behavior is validated with the smallest relevant command or test

## Reminder for future agents
Think in terms of business correctness first, then technical convenience. Reliable attendance, approval, notification, and security behavior are more important than speed or cleverness.
