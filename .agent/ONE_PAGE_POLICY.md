# TT Staff Pro One-Page AI Policy

## Mission
Build and maintain a secure, reliable, production-ready HRMS and face-attendance platform.

## Mandatory rules
- Read AGENTS.md before work.
- Keep work aligned with the existing app architecture.
- Prefer business-safe, minimal fixes over broad refactors.
- Never add secrets, private keys, credentials, or config leaks.
- Respect tenant, role, and permission context.
- Maintain idempotent attendance and notification behavior.
- Keep face-attendance identity logic separate from the main employee identity model.

## High-risk areas
- attendance check-in/out
- approvals and status changes
- notifications and FCM / WhatsApp flows
- face-attendance registration and kiosk scans
- offline queue and retry behavior
- device registration and token handling

## Working workflow
1. Read the exact relevant files and docs.
2. Confirm the business rule and expected outcome.
3. Reproduce or inspect the issue path.
4. Fix the root cause.
5. Validate with the smallest relevant command/test.
6. Review the final diff before finishing.

## Quality bar
- no duplicate or repeated actions
- no silent failures for business-critical flows
- no debug leaks of user or face data
- no insecure trust of client-only checks
- no unrelated scope expansion

## Release gate
Only finish when the fix is validated, minimal, secure, and consistent with the product rules and the repo’s workflow requirements.
