# Payroll & Financials Module Skill

This skill covers the implementation of Payroll, Payslips, and Loan management.

## 💰 Payroll System

### 1. Data Fetching
- **Store**: `PayrollStore`.
- **Endpoints**:
  - `getMySalaryStructure`: Detailed breakdown of earnings and deductions.
  - `getMyPayrollStatistics`: Summary of annual/monthly earnings for charts.
  - `getMyAdjustments`: Modifiers (bonuses, penalties) applied to current payroll.

### 2. Payslips
- **Format**: All payslips are fetched as PDF blobs or downloadable URLs.
- **Service**: `ApiService.downloadPayslip(int id)`.
- **UI**: Displayed using `flutter_pdfview`.

## 🏦 Loan Management

- **Types**: Fetched via `APIRoutes.loanTypes`.
- **EMI Calculator**: The app handles EMI calculations locally AND via API for verification.
- **Workflow**:
  1. User selects Loan Type.
  2. Input amount and tenure.
  3. API calculates EMI (`loanCalculateEmi`).
  4. Submit Request.

## 📈 Financial Charts
- Use the **Donut** and **Bar** chart recipes from the `ui_recipes` skill.
- The `PayrollStore` provides observable lists formatted for these charts.

## 🚀 Pro-Tip: "Currency Formatting"
Always use `appStore.currencySymbol` and the `NumberFormat` utility from `intl` to ensure amounts are formatted according to the company's local settings.
