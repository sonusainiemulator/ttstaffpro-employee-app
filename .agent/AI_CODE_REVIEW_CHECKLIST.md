# TT Staff Pro AI Code Review Checklist

## 1. Task fit
- [ ] The change directly matches the requested task or bug
- [ ] It does not expand scope unnecessarily
- [ ] The fix is aligned with the current project architecture

## 2. Root cause and logic
- [ ] The root cause was identified before patching
- [ ] The logic path was traced through the relevant app/service/API layer
- [ ] The final fix is minimal and directly connected to the cause

## 3. Security and privacy
- [ ] No secrets, tokens, API keys, or credentials were added
- [ ] No personal or sensitive user data was exposed in logs or code
- [ ] Tenant, auth, and permission context are preserved
- [ ] Attendance and approval logic does not trust client-side checks alone

## 4. App stability
- [ ] No duplicate or repeated actions were introduced
- [ ] Offline and retry behavior remains safe and predictable
- [ ] Notification and attendance flows do not trigger spam or duplicates
- [ ] App state and data flow remain consistent after the fix

## 5. Quality and maintainability
- [ ] Existing repo patterns were followed
- [ ] Localized strings were used for UI text
- [ ] Generated code was refreshed if required
- [ ] No broken imports or stale references remain
- [ ] Code is readable and easy for another developer to review

## 6. Validation
- [ ] The relevant build/test/analysis command was run
- [ ] The result was checked and the outcome was understood
- [ ] Any failing path or edge case was considered before sign-off

## Final result
Approve only if the fix is correct, safe, minimal, and properly validated.
