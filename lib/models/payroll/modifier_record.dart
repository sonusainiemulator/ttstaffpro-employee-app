/// Model for modifier record from API
/// Represents a payroll period with its associated modifiers
/// Refactored to support V1 Modifier History (Section 6.5)
class ModifierRecord {
  final int payrollRecordId;
  final String period;
  final String? monthYear;
  final PayrollCycleInfo? payrollCycle;
  final ModifiersList modifiers;
  final AmountInfo totalEarnings;
  final AmountInfo totalDeductions;

  ModifierRecord({
    required this.payrollRecordId,
    required this.period,
    this.monthYear,
    this.payrollCycle,
    required this.modifiers,
    required this.totalEarnings,
    required this.totalDeductions,
  });

  factory ModifierRecord.fromJson(Map<String, dynamic> json) {
    // Check for nested V1 History item or direct envelope
    if (json.containsKey('payroll_record_id') || json.containsKey('payrollId')) {
      final payrollId = json['payroll_record_id'] ?? json['payrollId'] ?? 0;
      final month = json['month'] ?? '';
      
      return ModifierRecord(
        payrollRecordId: payrollId,
        period: month,
        monthYear: json['monthYear'],
        payrollCycle: json['paymentDate'] != null 
            ? PayrollCycleInfo(name: 'Paid on', payDate: json['paymentDate']) 
            : null,
        modifiers: ModifiersList.fromJson(json['modifiers'] ?? json['adjustments'] ?? json),
        totalEarnings: AmountInfo.fromJson(json['total_earnings'] ?? {'amount': 0.0}),
        totalDeductions: AmountInfo.fromJson(json['total_deductions'] ?? {'amount': 0.0}),
      );
    }
    
    // Default fallback
    return ModifierRecord(
      payrollRecordId: 0,
      period: 'Unknown',
      modifiers: ModifiersList(earnings: [], deductions: []),
      totalEarnings: AmountInfo(amount: 0, formatted: '₹0'),
      totalDeductions: AmountInfo(amount: 0, formatted: '₹0'),
    );
  }

  /// Groups flat V1 history items (Section 6.5) into a list of ModifierRecords (one per month)
  static List<ModifierRecord> fromFlatV1List(List<dynamic> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final key = item['monthYear'] ?? item['month'] ?? 'Other';
        if (!grouped.containsKey(key)) grouped[key] = [];
        grouped[key]!.add(item);
      }
    }

    return grouped.entries.map((entry) {
      final periodItems = entry.value;
      final first = periodItems.first;
      
      final earnings = periodItems
          .where((i) => i['type'] == 'earning' || i['type'] == 'benefit')
          .map((i) => ModifierItem.fromV1Json(i))
          .toList();
          
      final deductions = periodItems
          .where((i) => i['type'] == 'deduction')
          .map((i) => ModifierItem.fromV1Json(i))
          .toList();

      final totalE = earnings.fold(0.0, (sum, i) => sum + i.amount.amount);
      final totalD = deductions.fold(0.0, (sum, i) => sum + i.amount.amount);

      return ModifierRecord(
        payrollRecordId: first['payrollId'] ?? 0,
        period: first['month'] ?? entry.key,
        monthYear: entry.key,
        payrollCycle: first['paymentDate'] != null 
            ? PayrollCycleInfo(name: 'Paid on', payDate: first['paymentDate']) 
            : null,
        modifiers: ModifiersList(earnings: earnings, deductions: deductions),
        totalEarnings: AmountInfo(amount: totalE, formatted: '₹${totalE.toStringAsFixed(2)}'),
        totalDeductions: AmountInfo(amount: totalD, formatted: '₹${totalD.toStringAsFixed(2)}'),
      );
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'payroll_record_id': payrollRecordId,
      'period': period,
      'monthYear': monthYear,
      'payrollCycle': payrollCycle?.toJson(),
      'modifiers': modifiers.toJson(),
      'total_earnings': totalEarnings.toJson(),
      'total_deductions': totalDeductions.toJson(),
    };
  }
}

/// Model for payroll cycle information
class PayrollCycleInfo {
  final String name;
  final String payDate;

  PayrollCycleInfo({
    required this.name,
    required this.payDate,
  });

  factory PayrollCycleInfo.fromJson(Map<String, dynamic> json) {
    return PayrollCycleInfo(
      name: json['name'] ?? '',
      payDate: json['pay_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pay_date': payDate,
    };
  }
}

/// Model for modifiers list (earnings and deductions)
class ModifiersList {
  final List<ModifierItem> earnings;
  final List<ModifierItem> deductions;

  ModifiersList({
    required this.earnings,
    required this.deductions,
  });

  factory ModifiersList.fromJson(Map<String, dynamic> json) {
    return ModifiersList(
      earnings: (json['earnings'] as List<dynamic>?)
              ?.map((e) => ModifierItem.fromJson(e, 'benefit'))
              .toList() ??
          [],
      deductions: (json['deductions'] as List<dynamic>?)
              ?.map((e) => ModifierItem.fromJson(e, 'deduction'))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earnings': earnings.map((e) => e.toJson()).toList(),
      'deductions': deductions.map((e) => e.toJson()).toList(),
    };
  }
}

/// Model for individual modifier item
class ModifierItem {
  final int? id;
  final String name;
  final String code;
  final AmountInfo amount;
  final double? percentage;
  final String type; // 'benefit' or 'deduction'
  final String? applicability;

  ModifierItem({
    this.id,
    required this.name,
    required this.code,
    required this.amount,
    this.percentage,
    required this.type,
    this.applicability,
  });

  factory ModifierItem.fromJson(Map<String, dynamic> json, String defaultType) {
    return ModifierItem(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      amount: AmountInfo.fromJson(json['amount'] is Map ? json['amount'] : {'amount': json['amount']}),
      percentage: json['percentage'] != null ? _parseDouble(json['percentage']) : null,
      type: json['type'] ?? defaultType,
      applicability: json['applicability'],
    );
  }

  factory ModifierItem.fromV1Json(Map<String, dynamic> json) {
    final rawAmount = _parseDouble(json['amount']);
    return ModifierItem(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      amount: AmountInfo(amount: rawAmount, formatted: '₹${rawAmount.toStringAsFixed(2)}'),
      type: json['type'] ?? 'earning',
      percentage: 0,
      applicability: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'amount': amount.toJson(),
      'percentage': percentage,
      'type': type,
      'applicability': applicability,
    };
  }

  /// Get display text with percentage if available
  String get displayValue {
    if (percentage != null && percentage! > 0) {
      return '${amount.formatted} (${percentage!.toStringAsFixed(1)}%)';
    }
    return amount.formatted;
  }
}

/// Model for amount information with formatted string
class AmountInfo {
  final double amount;
  final String formatted;

  AmountInfo({
    required this.amount,
    required this.formatted,
  });

  factory AmountInfo.fromJson(Map<String, dynamic> json) {
    final val = _parseDouble(json['amount'] ?? json['value'] ?? 0);
    return AmountInfo(
      amount: val,
      formatted: json['formatted'] ?? '₹${val.toStringAsFixed(2)}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'formatted': formatted,
    };
  }
}

/// Helper function for numeric parsing
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
