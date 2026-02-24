# HR Management Module Skill (Leave, Expense, Docs)

This skill documents the "Request-Approval" cycle used by Leave, Expenses, and Document modules.

## 📅 Leave Management
- **Flow**: Fetch types (`getLeaveTypes`) -> Submit Request with optional attachment -> Monitor Status.
- **Rules**: Check `remainingBalance` before allowing a new request submission.
- **Attachment**: Leave documents are uploaded via `multipartRequest`.

## 💸 Expense Management
- **Flow**: Create Request -> Attach Receipt -> Specify Category/Amount.
- **Service**: `uploadExpenseDocument` must be called first to get a file path/ID, which is then sent with the `sendExpenseRequest` payload.

## 📄 Document Requests
- Used for requesting official letters, certificates, or digital IDs.
- Follows the standard `ApiService.createDocumentRequest` pattern.

## ✅ Approval System (Manager Mode)
If the user is an approver (`isApprovalModuleEnabled`), they use:
- `getApprovalLeaveRequests`
- `takeLeaveActionForApproval` (Approve/Reject)
- `takeExpenseActionForApproval` (Approve/Reject)

## 🚀 Pro-Tip: "Document Status States"
Always map integer/string statuses to localized strings:
- `0`: Pending (Orange)
- `1`: Approved (Green)
- `2`: Rejected (Red)
- `3`: Cancelled (Grey)
Use the `badge` recipes from the UI skill.
