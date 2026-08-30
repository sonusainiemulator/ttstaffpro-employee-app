# Product Requirements Document (PRD)

## 1. Product overview
TT Staff Pro is a Flutter-based employee HRMS mobile application that connects to the Laravel backend at https://ttstaffpro.in/api/V1/. The product is designed for employee self-service, attendance management, payroll access, document requests, approvals, and internal operational workflows.

The current implementation is a mobile-first HRMS app focused on employee productivity, attendance operations, and operational visibility for managers and admins.

## 2. Product vision
Provide employees with a single mobile app to:
- mark attendance
- view attendance history
- request leave
- track payroll
- upload documents
- manage expenses
- access HR and internal notices
- view digital identity and work-related information

Provide admins and managers with operational visibility through the same platform, including attendance monitoring, payroll summaries, approvals, assets, and notices.

## 3. Current implemented features
Based on the current codebase, the app includes the following modules and capabilities:

### 3.1 Core employee features
- login and account authentication
- organization / tenant selection support
- profile management
- user onboarding and device validation
- local preferences and language/theme support

### 3.2 Attendance features
- check-in / check-out
- attendance status check
- attendance history
- actual time report
- regularization workflow
- early checkout reasoning
- geolocation / IP validation related attendance rules
- QR attendance support (dynamic QR / QR verification hooks)
- face attendance module support

### 3.3 Payroll and compensation
- payroll dashboard
- payslip access
- salary structure
- payroll statistics
- adjustments / modifier history
- payroll download support

### 3.4 Leave and approvals
- leave type management
- leave request creation
- leave request history
- leave cancellation
- approval-ready framework and conditional module gating

### 3.5 Expense and finance workflows
- expense types
- expense request creation
- expense request history
- document upload for expense support

### 3.6 Document and HR utilities
- document request flow
- document type listings
- document file access
- holidays
- notice board
- calendar
- policies support (feature disabled/placeholder depending on module state)

### 3.7 Assets and internal operations
- asset list
- asset assignments and documentation
- disciplinary warnings list
- loan request support
- task management support
- client visit tracking
- product and order support (depending on module enablement)

### 3.8 Collaboration and communication
- chat system
- messaging token registration
- notification history screen
- app-level notification infrastructure using Firebase messaging

### 3.9 User experience features
- dark/light theme
- multi-language localization
- gradient-based modern dashboard UI
- module-based feature display using backend settings

## 4. Target users
### Employee / staff
- check attendance and attendance history
- request leave and view approvals
- access payroll information
- apply for document requests and expense requests
- receive role-based notifications and reminders

### Manager / admin
- monitor attendance status and exceptions
- review regularization requests
- approve or act on internal workflows
- access payroll, notices, and task information
- manage operational efficiency across employees

### Organization admin
- enable/disable modules via backend module settings
- configure tenant-level and app-level feature flags
- manage app behavior through API-driven settings

## 5. Business goals
- reduce manual HR operations through mobile self-service
- improve attendance accuracy and accountability
- give employees transparent access to data
- reduce dependency on manual paperwork and reporting
- support multi-module HRMS usage for growing organizations

## 6. Functional requirements
### 6.1 Authentication and account
- user must log in through backend auth flow
- tenant/organization is detected or selected as needed
- device validation and registration must support secure access

### 6.2 Attendance
- employee must be able to check in and check out
- system must detect attendance status and update app state
- there must be a history screen with attendance logs
- regularization and early checkout reasons must be supported
- attendance rules must respect geofence, IP, and configured conditions

### 6.3 Module-driven app experience
- app UI must render modules conditionally based on server module settings
- modules such as payroll, leave, notice, calendar, documents, assets, loans, and face attendance must be controlled via configuration

### 6.4 Communication
- app must support notifications and notification history
- push notifications should support future alert workflows
- WhatsApp-style operational alerts are a planned extension, not the current core app feature

### 6.5 HR data access
- employees must be able to see their own payroll, attendance, documents, and notices
- managers/admins must be able to review operational data in relevant modules

## 7. Non-functional requirements
- app must be mobile-friendly and responsive
- app must support local data persistence for offline states
- app must tolerate connection drops and sync using background mechanisms
- app must support multiple locales and dark mode
- app must be modular for future feature expansion

## 8. Scope boundaries
### In scope for current app
- employee HRMS workflows
- attendance management and regularization
- payroll access
- leave and documents
- expense and asset modules
- notice, calendar, and policy-related modules
- notifications and chat foundation

### Out of scope for the current app
- advanced AI-based HR automation
- fully automated approval engine with deep orchestration
- full next-generation notification platform with WhatsApp/FCM integration as a business-wide alerting layer
- complete manager dashboard analytics beyond current feature set

## 9. Success metrics
- employees can perform attendance actions quickly and reliably
- attendance history is accessible and understandable
- payroll and leave information is available without extra manual follow-up
- app features can be enabled or disabled by organization configuration
- employee experience remains mobile-first and lightweight

## 10. Product decision summary
The current app is a practical HRMS employee application with strong attendance and operational workflows. The next strategic enhancement is not replacing the core app, but extending it with stronger real-time notification intelligence, especially for attendance events and admin alerts.
