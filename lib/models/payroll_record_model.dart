/// Payroll list item model — maps to GET /api/V1/payroll response (mobile-optimized).
///
/// All numeric fields are explicitly typed (int/double) as guaranteed by the API.
/// Use this for the payroll list screen.
class PayrollRecordModel {
  final int id;

  /// Human-readable month label, e.g. "February 2026"
  final String month;

  /// ISO month string, e.g. "2026-02"
  final String monthYear;

  final double netSalary;
  final double grossSalary;
  final double basicSalary;
  final int userId;

  /// One of: draft | pending | approved | paid | partially_paid
  final String status;

  /// Display label for status, e.g. "Paid"
  final String statusLabel;

  /// Payment date in YYYY-MM-DD format. Null for unpaid payrolls.
  final String? paymentDate;

  PayrollRecordModel({
    required this.id,
    required this.month,
    required this.monthYear,
    required this.netSalary,
    required this.grossSalary,
    required this.basicSalary,
    required this.userId,
    required this.status,
    required this.statusLabel,
    this.paymentDate,
  });

  /// Parses a single item from the GET /payroll `items` array.
  factory PayrollRecordModel.fromJson(Map<String, dynamic> json) {
    return PayrollRecordModel(
      id: _parseInt(json['id']),
      month: json['month'] as String? ?? '',
      monthYear: json['monthYear'] as String? ?? '',
      netSalary: _parseDouble(json['netSalary']),
      grossSalary: _parseDouble(json['grossSalary']),
      basicSalary: _parseDouble(json['basicSalary']),
      userId: _parseInt(json['userId']),
      status: json['status'] as String? ?? 'draft',
      statusLabel: json['statusLabel'] as String? ?? '',
      paymentDate: json['paymentDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month,
        'monthYear': monthYear,
        'netSalary': netSalary,
        'grossSalary': grossSalary,
        'basicSalary': basicSalary,
        'userId': userId,
        'status': status,
        'statusLabel': statusLabel,
        'paymentDate': paymentDate,
      };

  // ── Status helpers ────────────────────────────────────────────────────────
  bool get isDraft => status == 'draft';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isPaid => status == 'paid';
  bool get isPartiallyPaid => status == 'partially_paid';
  bool get isUnpaid => isDraft || isPending || isApproved;

  /// Hex color for the status badge.
  String get statusColorHex {
    switch (status) {
      case 'paid':
        return '#4CAF50';
      case 'partially_paid':
        return '#8BC34A';
      case 'approved':
        return '#FF9800';
      case 'pending':
        return '#2196F3';
      case 'draft':
      default:
        return '#9E9E9E';
    }
  }

  // ── Parsers ───────────────────────────────────────────────────────────────
  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// Paginated list response from GET /api/V1/payroll
class PayrollListResponse {
  final int total;
  final int skip;
  final int take;
  final List<PayrollRecordModel> items;

  PayrollListResponse({
    required this.total,
    required this.skip,
    required this.take,
    required this.items,
  });

  factory PayrollListResponse.fromJson(Map<String, dynamic> json) {
    return PayrollListResponse(
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      take: json['take'] as int? ?? 10,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PayrollRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => (skip + take) < total;
}

// ─────────────────────────────────────────────────────────────────────────────
// Payslip Detail  —  GET /api/V1/payroll/payslip/{id}
// ─────────────────────────────────────────────────────────────────────────────

/// Single earnings line inside a payslip.
class PayslipEarning {
  final String name;
  final double amount;

  PayslipEarning({required this.name, required this.amount});

  factory PayslipEarning.fromJson(Map<String, dynamic> json) => PayslipEarning(
        name: json['name'] as String? ?? '',
        amount: _parseDouble(json['amount']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
}

/// Single deduction line inside a payslip.
class PayslipDeduction {
  final String name;
  final double amount;

  PayslipDeduction({required this.name, required this.amount});

  factory PayslipDeduction.fromJson(Map<String, dynamic> json) =>
      PayslipDeduction(
        name: json['name'] as String? ?? '',
        amount: _parseDouble(json['amount']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
}

/// Attendance summary block inside Payslip detail.
class PayslipAttendance {
  final int totalWorkingDays;
  final int calendarDays;
  final int offDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int halfDays;
  final int lateDays;
  final double overtimeHours;

  /// presentDays + halfDays × 0.5
  final double effectiveDays;

  PayslipAttendance({
    required this.totalWorkingDays,
    required this.calendarDays,
    required this.offDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.halfDays,
    required this.lateDays,
    required this.overtimeHours,
    required this.effectiveDays,
  });

  factory PayslipAttendance.fromJson(Map<String, dynamic> json) {
    return PayslipAttendance(
      totalWorkingDays: _parseInt(json['total_working_days']),
      calendarDays: _parseInt(json['calendar_days']),
      offDays: _parseInt(json['off_days']),
      presentDays: _parseInt(json['present_days']),
      absentDays: _parseInt(json['absent_days']),
      leaveDays: _parseInt(json['leave_days']),
      halfDays: _parseInt(json['half_days']),
      lateDays: _parseInt(json['late_days']),
      overtimeHours: _parseDouble(json['overtime_hours']),
      effectiveDays: _parseDouble(json['effective_days']),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_working_days': totalWorkingDays,
        'calendar_days': calendarDays,
        'off_days': offDays,
        'present_days': presentDays,
        'absent_days': absentDays,
        'leave_days': leaveDays,
        'half_days': halfDays,
        'late_days': lateDays,
        'overtime_hours': overtimeHours,
        'effective_days': effectiveDays,
      };

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// Full payslip detail — maps to GET /api/V1/payroll/payslip/{id}
class PayslipDetailModel {
  final int id;
  final String month;

  /// "01 Feb 2026 - 28 Feb 2026"
  final String? payPeriod;

  final double basicSalary;
  final double grossSalary;
  final double totalEarnings;
  final double totalDeductions;
  final double netSalary;

  final String status;
  final String? statusLabel;

  /// Null for draft/pending/approved payrolls
  final String? paymentDate;
  final String? paymentMethod;
  final String? notes;

  /// Non-zero earnings lines only (filter by amount > 0 for display)
  final List<PayslipEarning> earnings;

  /// Non-zero deductions lines only
  final List<PayslipDeduction> deductions;

  final PayslipAttendance? attendance;

  PayslipDetailModel({
    required this.id,
    required this.month,
    this.payPeriod,
    required this.basicSalary,
    required this.grossSalary,
    required this.totalEarnings,
    required this.totalDeductions,
    required this.netSalary,
    required this.status,
    this.statusLabel,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.earnings,
    required this.deductions,
    this.attendance,
  });

  factory PayslipDetailModel.fromJson(Map<String, dynamic> json) {
    return PayslipDetailModel(
      id: _parseInt(json['id']),
      month: json['month'] as String? ?? '',
      payPeriod: json['payPeriod'] as String?,
      basicSalary: _parseDouble(json['basicSalary']),
      grossSalary: _parseDouble(json['grossSalary']),
      totalEarnings: _parseDouble(json['totalEarnings']),
      totalDeductions: _parseDouble(json['totalDeductions']),
      netSalary: _parseDouble(json['netSalary']),
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String?,
      paymentDate: json['paymentDate'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
      earnings: (json['earnings'] as List<dynamic>? ?? [])
          .map((e) => PayslipEarning.fromJson(e as Map<String, dynamic>))
          .toList(),
      deductions: (json['deductions'] as List<dynamic>? ?? [])
          .map((e) => PayslipDeduction.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendance: json['attendance'] != null
          ? PayslipAttendance.fromJson(
              json['attendance'] as Map<String, dynamic>)
          : null,
    );
  }

  // ── Convenience helpers ───────────────────────────────────────────────────
  bool get isPaid => status == 'paid';
  bool get isUnpaid =>
      status == 'draft' || status == 'pending' || status == 'approved';

  /// Earnings with a non-zero amount (for cleaner display)
  List<PayslipEarning> get nonZeroEarnings =>
      earnings.where((e) => e.amount > 0).toList();

  /// Deductions with a non-zero amount
  List<PayslipDeduction> get nonZeroDeductions =>
      deductions.where((d) => d.amount > 0).toList();

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Salary Structure  —  GET /api/V1/payroll/salary-structure
// ─────────────────────────────────────────────────────────────────────────────

/// Single component in the salary structure (earning or deduction).
class SalaryStructureComponent {
  final String name;
  final double amount;

  /// Share of total earnings / total deductions in %
  final double? percentage;

  /// Configured % of basic salary (HRA, DA, PF...)
  final double? ofBasic;

  /// Configured % of gross salary (ESI...)
  final double? ofGross;

  SalaryStructureComponent({
    required this.name,
    required this.amount,
    this.percentage,
    this.ofBasic,
    this.ofGross,
  });

  factory SalaryStructureComponent.fromJson(Map<String, dynamic> json) =>
      SalaryStructureComponent(
        name: json['name'] as String? ?? '',
        amount: _parseDouble(json['amount']),
        percentage: json['percentage'] != null
            ? _parseDouble(json['percentage'])
            : null,
        ofBasic: json['of_basic'] != null ? _parseDouble(json['of_basic']) : null,
        ofGross: json['of_gross'] != null ? _parseDouble(json['of_gross']) : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        if (percentage != null) 'percentage': percentage,
        if (ofBasic != null) 'of_basic': ofBasic,
        if (ofGross != null) 'of_gross': ofGross,
      };

  /// True if this component is computed as a % of basic
  bool get hasBasicRate => ofBasic != null;

  /// True if this component is computed as a % of gross
  bool get hasGrossRate => ofGross != null;

  /// Human-readable rate label, e.g. "40% of Basic"
  String? get rateLabel {
    if (ofBasic != null) return '${ofBasic!.toStringAsFixed(0)}% of Basic';
    if (ofGross != null) return '${ofGross!.toStringAsFixed(0)}% of Gross';
    return null;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
}

/// Full salary structure — maps to GET /api/V1/payroll/salary-structure
class SalaryStructureModel {
  final int id;
  final double basicSalary;
  final double grossSalary;
  final double netSalary;

  /// ISO date "YYYY-MM-DD"
  final String effectiveFrom;

  final List<SalaryStructureComponent> earnings;
  final List<SalaryStructureComponent> deductions;

  SalaryStructureModel({
    required this.id,
    required this.basicSalary,
    required this.grossSalary,
    required this.netSalary,
    required this.effectiveFrom,
    required this.earnings,
    required this.deductions,
  });

  factory SalaryStructureModel.fromJson(Map<String, dynamic> json) {
    return SalaryStructureModel(
      id: _parseInt(json['id']),
      basicSalary: _parseDouble(json['basicSalary']),
      grossSalary: _parseDouble(json['grossSalary']),
      netSalary: _parseDouble(json['netSalary']),
      effectiveFrom: json['effectiveFrom'] as String? ?? '',
      earnings: (json['earnings'] as List<dynamic>? ?? [])
          .map((e) =>
              SalaryStructureComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      deductions: (json['deductions'] as List<dynamic>? ?? [])
          .map((e) =>
              SalaryStructureComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'basicSalary': basicSalary,
        'grossSalary': grossSalary,
        'netSalary': netSalary,
        'effectiveFrom': effectiveFrom,
        'earnings': earnings.map((e) => e.toJson()).toList(),
        'deductions': deductions.map((e) => e.toJson()).toList(),
      };

  /// Total earnings amount (sum of earning component amounts)
  double get totalEarningsAmount =>
      earnings.fold(0.0, (sum, e) => sum + e.amount);

  /// Total deductions amount
  double get totalDeductionsAmount =>
      deductions.fold(0.0, (sum, d) => sum + d.amount);

  /// Non-zero earnings only
  List<SalaryStructureComponent> get activeEarnings =>
      earnings.where((e) => e.amount > 0).toList();

  /// Non-zero deductions only
  List<SalaryStructureComponent> get activeDeductions =>
      deductions.where((d) => d.amount > 0).toList();

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy detail model alias — kept so existing code referencing
// PayrollRecordDetailModel still compiles while the codebase migrates.
// ─────────────────────────────────────────────────────────────────────────────
typedef PayrollRecordDetailModel = PayslipDetailModel;
