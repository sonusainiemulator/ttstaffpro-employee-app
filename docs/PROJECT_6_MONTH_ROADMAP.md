# TT Staff Pro 6-Month Roadmap

## Goal
Deliver a stable HRMS platform with a strong attendance notification layer and a finished face attendance module for kiosk-based attendance.

## Month 1: Notification foundation
- finalize notification DB schema
- implement attendance event rules and triggers
- integrate WhatsApp gateway and FCM push
- create app notification history and read status
- validate employee/admin alert paths

## Month 2: Face attendance completion
- complete kiosk login and company matching
- finalize device registration and heartbeat
- validate offline queue and retry handling
- check attendance sync into core attendance module
- complete daily report and admin review screens

## Month 3: Admin dashboards and exception views
- build summary cards for late, early, absent, missed checkout
- add admin monitoring screens
- add approval action widgets
- connect event notifications to dashboard reporting

## Month 4: Notification quality improvements
- deduplications by event id
- smart rules and escalation logic
- business-hour and quiet-hour controls
- user preference management

## Month 5: QA, hardening, and release readiness
- regression tests for app and kiosk flows
- stress test on offline and retry flows
- validate tenant behavior and module gating
- prepare version release notes

## Month 6: Pilot deployment and optimization
- pilot with one organization or selected tenant
- monitor real alert volume and duplicate rate
- tune critical events and user preferences
- finalize production rollout checklist

## Exit criteria for each phase
- business-critical alerts work end to end
- no duplicate attendance events from retry flows
- admin can review alerts and exceptions quickly
- kiosk attendance and employee app remain aligned with main attendance engine
- release-ready documentation and QA checklist are complete
