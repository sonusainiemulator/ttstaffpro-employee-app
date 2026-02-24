# Project Management Plan

This document outlines the strategy for tracking bugs, issues, features, and milestones for the **Open Core Employee App**.

## 🚀 Milestones

### **v1.0.0 - MVP Release (Current)**
**Goal**: Core functionality validation and initial stable release.
- [x] Basic Auth & Onboarding
- [x] Employee Attendance Tracking
- [x] Profile Management
- [x] Initial UI/UX Polish
- [x] Signed App Bundle Generation

### **v1.1.0 - Usability & Optimization**
**Goal**: Improve user experience and fix critical post-launch bugs.
- [ ] **Feature**: Dark Mode support across all screens.
- [ ] **Feature**: Push Notifications for attendance reminders.
- [ ] **Optimization**: Reduce app start time by 20%.
- [ ] **Bug Fix**: Resolve high-priority issues reported by initial users.

### **v1.2.0 - Advanced Features**
**Goal**: Add value-added features for better staff management.
- [ ] **Feature**: Leave Application & Approval Workflow.
- [ ] **Feature**: Real-time Chat/Communication module.
- [ ] **Integration**: Calendar sync.

---

## 🏷️ Labeling Strategy

Use these labels to categorize issues on GitHub:

### **Type**
- `bug`: Something isn't working.
- `enhancement`: New feature or request.
- `documentation`: Improvements or additions to documentation.
- `maintenance`: Code refactoring, dependency updates.

### **Priority**
- `priority: high`: Must be fixed ASAP (blocker).
- `priority: medium`: Important but not blocking.
- `priority: low`: Nice to have, can wait.

### **Status**
- `status: in-progress`: Currently being worked on.
- `status: review-needed`: PR submitted, needs review.
- `status: blocked`: Waiting for external factors.

---

##  Workflow

1.  **Issue Creation**: All work must start with an Issue (Bug Report or Feature Request).
2.  **Triage**: Assign labels and a milestone to the issue.
3.  **Development**: Create a branch from `main` (e.g., `feature/login-ui` or `fix/crash-on-start`).
4.  **Pull Request**: Submit PR linking to the issue (e.g., "Closes #123").
5.  **Review**: Peer review and automated AI review by **CodeRabbit**.
6.  **Merge**: Squash and merge into `main`.

---

## 🤖 Dependency Management

We use **Dependabot** to keep our dependencies up to date.
- **Schedule**: Checks for updates weekly.
- **Scope**: Covers Flutter packages (`pubspec.yaml`) and GitHub Actions.
- **Workflow**: Dependabot opens a PR -> CI runs -> Review -> Merge.

