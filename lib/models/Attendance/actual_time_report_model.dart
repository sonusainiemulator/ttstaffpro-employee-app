class ActualTimeReport {
  final int id;
  final String date;
  final String dayName;

  // Actual recorded times
  final String? actualCheckIn;
  final String? actualCheckOut;
  final double actualWorkingHours;
  final String actualWorkingHoursFormatted;
  final double actualBreakHours;
  final String actualBreakHoursFormatted;

  // Shift expected times
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? shiftName;
  final int shiftExpectedHours;

  // Allow rules from shift settings
  final bool allowLateCheckIn;
  final bool allowEarlyCheckout;
  final bool allowBreakTime;
  final bool allowExtraBreakTime;
  final int allowedLateMinutes;
  final int allowedEarlyCheckoutMinutes;
  final int allowedBreakMinutes;
  final int allowedExtraBreakMinutes;
  final bool halfDayRule;
  final bool overtimeAllowed;

  // Computed differences
  final int lateMinutes;
  final int earlyCheckoutMinutes;
  final int extraBreakMinutes;
  final double overtimeHours;
  final bool isHalfDay;
  final bool isAbsent;
  final bool isHoliday;
  final bool isWeekend;

  // Status
  final String status;
  final String statusLabel;
  final String? lateReason;
  final String? earlyCheckoutReason;
  final bool? overtimeTask;
  final String? overtimeTaskNote;

  // Calculated rating / compliance
  final double complianceScore; // 0-100

  ActualTimeReport({
    required this.id,
    required this.date,
    required this.dayName,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.actualWorkingHours,
    required this.actualWorkingHoursFormatted,
    required this.actualBreakHours,
    required this.actualBreakHoursFormatted,
    this.shiftStartTime,
    this.shiftEndTime,
    this.shiftName,
    required this.shiftExpectedHours,
    required this.allowLateCheckIn,
    required this.allowEarlyCheckout,
    required this.allowBreakTime,
    required this.allowExtraBreakTime,
    required this.allowedLateMinutes,
    required this.allowedEarlyCheckoutMinutes,
    required this.allowedBreakMinutes,
    required this.allowedExtraBreakMinutes,
    required this.halfDayRule,
    required this.overtimeAllowed,
    required this.lateMinutes,
    required this.earlyCheckoutMinutes,
    required this.extraBreakMinutes,
    required this.overtimeHours,
    required this.isHalfDay,
    required this.isAbsent,
    required this.isHoliday,
    required this.isWeekend,
    required this.status,
    required this.statusLabel,
    this.lateReason,
    this.earlyCheckoutReason,
    this.overtimeTask,
    this.overtimeTaskNote,
    required this.complianceScore,
  });

  factory ActualTimeReport.fromJson(Map<String, dynamic> json) {
    // V1 fields mapping (documentation Section 6)
    final workingHours = _parseDouble(json['totalWorkingHours'] ?? json['actualWorkingHours']);
    final breakHours = _parseDouble((json['actualBreakMinutes'] ?? json['actualBreakHours'] ?? 0) / 60.0);
    final otHours = _parseDouble(json['lateCheckoutMinutes'] ?? json['overtimeHours']);

    return ActualTimeReport(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      actualCheckIn: json['checkInTime'] ?? json['actualCheckIn'],
      actualCheckOut: json['checkOutTime'] ?? json['actualCheckOut'],
      actualWorkingHours: workingHours,
      actualWorkingHoursFormatted: json['actualWorkingHoursFormatted'] ?? 
          '${workingHours.floor()}h ${((workingHours - workingHours.floor()) * 60).round()}m',
      actualBreakHours: breakHours,
      actualBreakHoursFormatted: json['actualBreakHoursFormatted'] ?? 
          '${(json['actualBreakMinutes'] ?? 0)}m',
      shiftStartTime: json['shift']?['startTime'] ?? json['shiftStartTime'],
      shiftEndTime: json['shift']?['endTime'] ?? json['shiftEndTime'],
      shiftName: json['shift']?['name'] ?? json['shiftName'],
      shiftExpectedHours: json['shift']?['workingHours'] ?? json['shiftExpectedHours'] ?? 0,
      allowLateCheckIn: json['allowLateCheckIn'] ?? (json['allowedLateMinutes'] != null),
      allowEarlyCheckout: json['allowEarlyCheckout'] ?? (json['allowedEarlyCheckoutMinutes'] != null),
      allowBreakTime: json['allowBreakTime'] ?? (json['allowedBreakMinutes'] != null),
      allowExtraBreakTime: json['allowExtraBreakTime'] ?? false,
      allowedLateMinutes: json['allowedLateMinutes'] ?? 0,
      allowedEarlyCheckoutMinutes: json['allowedEarlyCheckoutMinutes'] ?? 0,
      allowedBreakMinutes: json['allowedBreakMinutes'] ?? 0,
      allowedExtraBreakMinutes: json['allowedExtraBreakMinutes'] ?? 0,
      halfDayRule: json['halfDayRule'] ?? json['isHalfDay'] ?? false,
      overtimeAllowed: json['overtimeAllowed'] ?? (otHours > 0),
      lateMinutes: json['actualLateMinutes'] ?? json['lateMinutes'] ?? 0,
      earlyCheckoutMinutes: json['actualEarlyCheckoutMinutes'] ?? json['earlyCheckoutMinutes'] ?? 0,
      extraBreakMinutes: json['breakLossMinutes'] ?? json['extraBreakMinutes'] ?? 0,
      overtimeHours: otHours,
      isHalfDay: json['isHalfDay'] ?? false,
      isAbsent: json['isAbsent'] ?? (json['status'] == 'absent'),
      isHoliday: json['isHoliday'] ?? false,
      isWeekend: json['isWeekend'] ?? false,
      status: json['status'] ?? '',
      statusLabel: json['statusLabel'] ?? '',
      lateReason: json['lateReason'],
      earlyCheckoutReason: json['earlyCheckoutReason'],
      overtimeTask: json['overtimeTask'],
      overtimeTaskNote: json['overtimeTaskNote'],
      complianceScore: _parseDouble(json['complianceScore'] ?? 100), // Default high if missing
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'dayName': dayName,
      'actualCheckIn': actualCheckIn,
      'actualCheckOut': actualCheckOut,
      'actualWorkingHours': actualWorkingHours,
      'actualWorkingHoursFormatted': actualWorkingHoursFormatted,
      'actualBreakHours': actualBreakHours,
      'actualBreakHoursFormatted': actualBreakHoursFormatted,
      'shiftStartTime': shiftStartTime,
      'shiftEndTime': shiftEndTime,
      'shiftName': shiftName,
      'shiftExpectedHours': shiftExpectedHours,
      'allowLateCheckIn': allowLateCheckIn,
      'allowEarlyCheckout': allowEarlyCheckout,
      'allowBreakTime': allowBreakTime,
      'allowExtraBreakTime': allowExtraBreakTime,
      'allowedLateMinutes': allowedLateMinutes,
      'allowedEarlyCheckoutMinutes': allowedEarlyCheckoutMinutes,
      'allowedBreakMinutes': allowedBreakMinutes,
      'allowedExtraBreakMinutes': allowedExtraBreakMinutes,
      'halfDayRule': halfDayRule,
      'overtimeAllowed': overtimeAllowed,
      'lateMinutes': lateMinutes,
      'earlyCheckoutMinutes': earlyCheckoutMinutes,
      'extraBreakMinutes': extraBreakMinutes,
      'overtimeHours': overtimeHours,
      'isHalfDay': isHalfDay,
      'isAbsent': isAbsent,
      'isHoliday': isHoliday,
      'isWeekend': isWeekend,
      'status': status,
      'statusLabel': statusLabel,
      'lateReason': lateReason,
      'earlyCheckoutReason': earlyCheckoutReason,
      'overtimeTask': overtimeTask,
      'overtimeTaskNote': overtimeTaskNote,
      'complianceScore': complianceScore,
    };
  }
}

class ActualTimeReportResponse {
  final int totalCount;
  final List<ActualTimeReport> values;
  final ActualTimeReportSummary? summary;

  ActualTimeReportResponse({
    required this.totalCount,
    required this.values,
    this.summary,
  });

  factory ActualTimeReportResponse.fromJson(Map<String, dynamic> json) {
    final List<ActualTimeReport> values = (json['items'] as List? ?? json['values'] as List? ?? [])
              .map((e) => ActualTimeReport.fromJson(Map<String, dynamic>.from(e)))
              .toList()
              .cast<ActualTimeReport>();
          
    return ActualTimeReportResponse(
      totalCount: json['total'] ?? json['totalCount'] ?? values.length,
      values: values,
      summary: json['summary'] != null
          ? ActualTimeReportSummary.fromJson(json['summary'])
          : _calculateSummary(values),
    );
  }

  static ActualTimeReportSummary _calculateSummary(List<ActualTimeReport> values) {
    double totalWH = 0, totalBH = 0, totalOT = 0;
    int lateM = 0, earlyM = 0, p = 0, a = 0, h = 0, hol = 0, w = 0;
    double scoreSum = 0;

    for (var r in values) {
      totalWH += r.actualWorkingHours;
      totalBH += r.actualBreakHours;
      totalOT += r.overtimeHours;
      lateM += r.lateMinutes;
      earlyM += r.earlyCheckoutMinutes;
      if (r.isAbsent) a++;
      else if (r.isHoliday) hol++;
      else if (r.isWeekend) w++;
      else if (r.isHalfDay) h++;
      else p++;
      scoreSum += r.complianceScore;
    }

    return ActualTimeReportSummary(
      totalWorkingHours: totalWH,
      totalBreakHours: totalBH,
      totalOvertimeHours: totalOT,
      totalLateMinutes: lateM,
      totalEarlyCheckoutMinutes: earlyM,
      presentDays: p,
      absentDays: a,
      halfDays: h,
      holidayDays: hol,
      weekendDays: w,
      avgComplianceScore: values.isEmpty ? 0 : scoreSum / values.length,
    );
  }
}

class ActualTimeReportSummary {
  final double totalWorkingHours;
  final double totalBreakHours;
  final double totalOvertimeHours;
  final int totalLateMinutes;
  final int totalEarlyCheckoutMinutes;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int holidayDays;
  final int weekendDays;
  final double avgComplianceScore;

  ActualTimeReportSummary({
    required this.totalWorkingHours,
    required this.totalBreakHours,
    required this.totalOvertimeHours,
    required this.totalLateMinutes,
    required this.totalEarlyCheckoutMinutes,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.holidayDays,
    required this.weekendDays,
    required this.avgComplianceScore,
  });

  factory ActualTimeReportSummary.fromJson(Map<String, dynamic> json) {
    return ActualTimeReportSummary(
      totalWorkingHours: ActualTimeReport._parseDouble(json['totalWorkingHours']),
      totalBreakHours: ActualTimeReport._parseDouble(json['totalBreakHours']),
      totalOvertimeHours: ActualTimeReport._parseDouble(json['totalOvertimeHours']),
      totalLateMinutes: json['totalLateMinutes'] ?? 0,
      totalEarlyCheckoutMinutes: json['totalEarlyCheckoutMinutes'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      halfDays: json['halfDays'] ?? 0,
      holidayDays: json['holidayDays'] ?? 0,
      weekendDays: json['weekendDays'] ?? 0,
      avgComplianceScore: ActualTimeReport._parseDouble(json['avgComplianceScore']),
    );
  }
}
