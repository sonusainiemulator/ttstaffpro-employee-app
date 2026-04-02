/// Model for payroll statistics and dashboard data
/// Provides overview of payroll trends, comparisons, and summaries
/// Refactored to support V1 Mobile API Documentation (Section 5)
class PayrollStatistics {
  // --- V1 Summary Section ---
  final double totalGrossSalary;
  final double totalNetSalary;
  final double totalAmountPaid;
  final double totalBalanceDue;
  final double averageNetSalary;
  final int totalPayrollsCount;

  // --- V1 Status Counts ---
  final int draftCount;
  final int pendingCount;
  final int approvedCount;
  final int paidCount;
  final int partiallyPaidCount;
  final int rejectedCount;

  // --- Current/Latest Month (mapped from 'latest' key) ---
  final double currentMonthGross;
  final double currentMonthNet;
  final double currentMonthDeductions;
  final double currentMonthEarnings;
  final String? currentMonthName;
  final String? currentMonthYear;

  // --- Historical Trends ---
  final List<MonthlyPayrollSummary>? monthlyTrends;

  // --- Meta information ---
  final String year;
  final String currentMonth; // Friendly name for UI
  final String? lastUpdated;

  // --- Legacy compatibility fields (kept to avoid UI breakage, defaulted to 0 or calculated) ---
  final double ytdGross;
  final double ytdNet;
  final double ytdDeductions;
  final double ytdEarnings;
  final double ytdTax;
  final double averageMonthlyGross;
  final double averageMonthlyNet;
  final double averageMonthlyDeductions;
  final double currentMonthAttendancePercentage;
  final double ytdAverageAttendance;
  final double currentMonthLopAmount;
  final double currentMonthOvertimeAmount;
  final double ytdLopAmount;
  final double ytdOvertimeAmount;
  final double currentMonthPF;
  final double currentMonthESI;
  final double currentMonthProfessionalTax;
  final double currentMonthIncomeTax;
  final double ytdPF;
  final double ytdESI;
  final double ytdProfessionalTax;
  final double ytdIncomeTax;
  final int totalPayslips;
  final int paidPayslips;
  final int pendingPayslips;

  PayrollStatistics({
    required this.totalGrossSalary,
    required this.totalNetSalary,
    required this.totalAmountPaid,
    required this.totalBalanceDue,
    required this.averageNetSalary,
    required this.totalPayrollsCount,
    required this.draftCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.paidCount,
    required this.partiallyPaidCount,
    required this.rejectedCount,
    required this.currentMonthGross,
    required this.currentMonthNet,
    required this.currentMonthDeductions,
    required this.currentMonthEarnings,
    this.currentMonthName,
    this.currentMonthYear,
    this.monthlyTrends,
    required this.year,
    required this.currentMonth,
    this.lastUpdated,
    // Defaulting legacy
    this.ytdGross = 0,
    this.ytdNet = 0,
    this.ytdDeductions = 0,
    this.ytdEarnings = 0,
    this.ytdTax = 0,
    this.averageMonthlyGross = 0,
    this.averageMonthlyNet = 0,
    this.averageMonthlyDeductions = 0,
    this.currentMonthAttendancePercentage = 0,
    this.ytdAverageAttendance = 0,
    this.currentMonthLopAmount = 0,
    this.currentMonthOvertimeAmount = 0,
    this.ytdLopAmount = 0,
    this.ytdOvertimeAmount = 0,
    this.currentMonthPF = 0,
    this.currentMonthESI = 0,
    this.currentMonthProfessionalTax = 0,
    this.currentMonthIncomeTax = 0,
    this.ytdPF = 0,
    this.ytdESI = 0,
    this.ytdProfessionalTax = 0,
    this.ytdIncomeTax = 0,
    this.totalPayslips = 0,
    this.paidPayslips = 0,
    this.pendingPayslips = 0,
  });

  factory PayrollStatistics.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final statuses = json['statusCounts'] as Map<String, dynamic>? ?? {};
    final latest = json['latest'] as Map<String, dynamic>? ?? {};
    final period = json['period'] as Map<String, dynamic>? ?? {};

    return PayrollStatistics(
      // V1 Summary
      totalGrossSalary: _parseDouble(summary['totalGrossSalary']),
      totalNetSalary: _parseDouble(summary['totalNetSalary']),
      totalAmountPaid: _parseDouble(summary['totalAmountPaid']),
      totalBalanceDue: _parseDouble(summary['totalBalanceDue']),
      averageNetSalary: _parseDouble(summary['averageNetSalary']),
      totalPayrollsCount: summary['totalPayrolls'] ?? 0,

      // V1 Statuses
      draftCount: statuses['draft'] ?? 0,
      pendingCount: statuses['pending'] ?? 0,
      approvedCount: statuses['approved'] ?? 0,
      paidCount: statuses['paid'] ?? 0,
      partiallyPaidCount: statuses['partially_paid'] ?? 0,
      rejectedCount: statuses['rejected'] ?? 0,

      // Latest Month Info
      currentMonthGross: _parseDouble(latest['grossSalary']),
      currentMonthNet: _parseDouble(latest['netSalary']),
      currentMonthDeductions: _parseDouble(latest['grossSalary']) - _parseDouble(latest['netSalary']),
      currentMonthEarnings: _parseDouble(latest['grossSalary']),
      currentMonthName: latest['month'],
      currentMonthYear: latest['monthYear'],

      // Trends
      monthlyTrends: json['trend'] != null
          ? (json['trend'] as List)
              .map((item) => MonthlyPayrollSummary.fromJson(item))
              .toList()
          : null,

      // Meta
      year: period['endMonth']?.split('-')?.first ?? '',
      currentMonth: latest['month'] ?? 'Latest',
      lastUpdated: json['lastUpdated'],

      // Legacy Mapping for UI stability
      ytdGross: _parseDouble(summary['totalGrossSalary']),
      ytdNet: _parseDouble(summary['totalNetSalary']),
      ytdDeductions: _parseDouble(summary['totalGrossSalary']) - _parseDouble(summary['totalNetSalary']),
      totalPayslips: summary['totalPayrolls'] ?? 0,
      paidPayslips: statuses['paid'] ?? 0,
      pendingPayslips: statuses['pending'] ?? 0,
      averageMonthlyNet: _parseDouble(summary['averageNetSalary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': {
        'totalGrossSalary': totalGrossSalary,
        'totalNetSalary': totalNetSalary,
        'totalAmountPaid': totalAmountPaid,
        'totalBalanceDue': totalBalanceDue,
        'averageNetSalary': averageNetSalary,
        'totalPayrolls': totalPayrollsCount,
      },
      'statusCounts': {
        'draft': draftCount,
        'pending': pendingCount,
        'approved': approvedCount,
        'paid': paidCount,
        'partially_paid': partiallyPaidCount,
        'rejected': rejectedCount,
      },
      'latest': {
        'grossSalary': currentMonthGross,
        'netSalary': currentMonthNet,
        'month': currentMonthName,
        'monthYear': currentMonthYear,
      },
      'trend': monthlyTrends?.map((m) => m.toJson()).toList(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model for monthly payroll summary (for trends/charts)
class MonthlyPayrollSummary {
  final String month; // Friendly name: "September 2025"
  final String monthYear; // "2025-09"
  final double grossSalary;
  final double netSalary;
  final int payrollCount;

  MonthlyPayrollSummary({
    required this.month,
    required this.monthYear,
    required this.grossSalary,
    required this.netSalary,
    required this.payrollCount,
  });

  factory MonthlyPayrollSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyPayrollSummary(
      month: json['month'] ?? '',
      monthYear: json['monthYear'] ?? '',
      grossSalary: _parseDouble(json['totalGrossSalary']),
      netSalary: _parseDouble(json['totalNetSalary']),
      payrollCount: json['payrollCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'monthYear': monthYear,
      'totalGrossSalary': grossSalary,
      'totalNetSalary': netSalary,
      'payrollCount': payrollCount,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
