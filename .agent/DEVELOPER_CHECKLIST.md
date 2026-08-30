# TT Staff Pro Pre-Release Developer Checklist

## 1. Security
- [ ] No secrets, credentials, tokens, or private configuration were added to the repo
- [ ] No sensitive user data or personal info was logged
- [ ] Backend auth, tenant, and permission checks are respected
- [ ] client-side validation does not bypass server-side safety checks
- [ ] notification and attendance paths are handled safely and audibly

## 2. Root-cause fix validation
- [ ] The bug was reproduced or the exact logic path was confirmed
- [ ] The fix targets the root cause, not just the symptom
- [ ] The change is small, scoped, and directly related to the issue
- [ ] A relevant verification command or test was run before completion

## 3. Attendance and notification safety
- [ ] attendance flow is idempotent and duplicate-safe
- [ ] no duplicate notification trigger was introduced
- [ ] offline queue and retry logic remains safe and predictable
- [ ] approval and status workflows remain auditable
- [ ] device and token lifecycle is handled consistently

## 4. App quality
- [ ] code follows repo patterns and existing architecture
- [ ] any required generated code was updated
- [ ] module gating still works for enabled/disabled features
- [ ] app strings use localization instead of hardcoded English text
- [ ] no unrelated refactor or accidental scope expansion occurred

## 5. Release readiness
- [ ] the relevant build or validation command succeeded
- [ ] the changed behavior was checked in the correct app flow
- [ ] no broken imports or compile issues remain
- [ ] documentation or notes were updated when relevant
- [ ] git status is clean and only intended files are included

## Final release note
Do not mark work complete until the relevant checks pass and the change is consistent with the product, security, and attendance rules of TT Staff Pro.
