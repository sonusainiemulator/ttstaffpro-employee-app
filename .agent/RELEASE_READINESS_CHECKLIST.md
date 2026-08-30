# TT Staff Pro Release Readiness Checklist

## 1. Product and scope
- [ ] Business goal of the change is clear and documented
- [ ] Scope is limited to the intended feature or fix
- [ ] No unrelated refactor or accidental broad change is included
- [ ] Documentation and notes were updated when required

## 2. Security and privacy
- [ ] No secrets, API keys, credentials, or private config were added
- [ ] No personal or sensitive data is logged or exposed in debug output
- [ ] Tenant and permission checks remain valid
- [ ] Attendance, approval, and notification logic still uses trusted server-side validation
- [ ] Face attendance logic does not treat face data as a standalone identity source

## 3. Attendance and workflow safety
- [ ] check-in and check-out flows are idempotent
- [ ] duplicate submissions and repeated notifications are prevented
- [ ] offline queue and retry logic remains safe
- [ ] admin approval or rejection flows are still consistent and auditable
- [ ] main attendance engine remains the source of truth for final records

## 4. App quality
- [ ] relevant files compile without errors
- [ ] generated code was refreshed if required
- [ ] localization is used for user-facing strings
- [ ] module gating still behaves properly
- [ ] no broken imports, stale references, or dead code remain

## 5. Feature validation
- [ ] the specific task was reproduced or logic path confirmed
- [ ] the fix addresses the root cause
- [ ] the relevant app flow was manually or automatically validated
- [ ] edge cases such as no connection, duplicate events, and invalid state were considered
- [ ] success/failure states are clear to the user

## 6. Release confidence
- [ ] build/test verification command was run and passed
- [ ] final diff is intentional and scoped
- [ ] branch status is clean or intentionally tracked
- [ ] no hidden assumptions remain before handoff

## Final sign-off
Only mark the task as release-ready when all required checks above are complete and the change is safe for production use.
