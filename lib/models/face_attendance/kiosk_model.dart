/// Kiosk (tablet) models for single-point face attendance.
///
/// These back the wall-mounted kiosk flow:
///  - Company name match on login
///  - Master login (single tablet account)
///  - Date-wise staff attendance report with check-in / check-out
library;

/// A matched company returned by `POST face-attendance/kiosk/company-match`.
class KioskCompany {
  final int? id;
  final String? name;
  final String? logoUrl;
  final String? tenantId;

  KioskCompany({this.id, this.name, this.logoUrl, this.tenantId});

  factory KioskCompany.fromJson(Map<String, dynamic> json) {
    return KioskCompany(
      id: json['id'] as int? ?? (json['companyId'] as int?),
      name: json['name'] as String? ?? json['companyName'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'tenantId': tenantId,
      };
}

/// Result of company-name matching.
class KioskCompanyMatchResult {
  final bool ok;
  final KioskCompany? company;
  final String? message;

  KioskCompanyMatchResult({
    required this.ok,
    this.company,
    this.message,
  });

  factory KioskCompanyMatchResult.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as Map<String, dynamic>? ?? json;
    final matched = raw['ok'] as bool? ?? raw['matched'] as bool? ?? false;
    return KioskCompanyMatchResult(
      ok: matched,
      company: raw['company'] != null
          ? KioskCompany.fromJson(raw['company'] as Map<String, dynamic>)
          : null,
      message: raw['message'] as String? ?? json['message'] as String?,
    );
  }
}

/// Result of master login (`POST face-attendance/kiosk/login`).
class KioskLoginResult {
  final bool ok;
  final String? masterToken;
  final bool? deviceRequired;
  final String? message;

  KioskLoginResult({
    required this.ok,
    this.masterToken,
    this.deviceRequired,
    this.message,
  });

  factory KioskLoginResult.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as Map<String, dynamic>? ?? json;
    return KioskLoginResult(
      ok: raw['ok'] as bool? ?? (raw['token'] != null),
      masterToken: raw['token'] as String? ?? raw['masterToken'] as String?,
      deviceRequired:
          raw['deviceRequired'] as bool? ?? raw['device_required'] as bool?,
      message: raw['message'] as String? ?? json['message'] as String?,
    );
  }
}

/// One tenant employee returned by `GET face-attendance/kiosk/employees`
/// (used to pick who to register a face for on the kiosk).
class KioskEmployee {
  final int? employeeId;
  final String? name;
  final String? email;
  final String? code;

  KioskEmployee({
    this.employeeId,
    this.name,
    this.email,
    this.code,
  });

  factory KioskEmployee.fromJson(Map<String, dynamic> json) {
    // employee_id may arrive as an int or a numeric string depending on the
    // tenant DB / serializer — tolerate both instead of hard-casting.
    final rawId = json['employeeId'] ?? json['employee_id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    return KioskEmployee(
      employeeId: id,
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
      code: json['code'] as String?,
    );
  }
}

/// One staff row in the date-wise kiosk report.
class KioskReportRow {
  final int? employeeId;
  final String? employeeName;
  final String? checkIn;
  final String? checkOut;
  final bool? isLate;
  final bool? isEarly;
  final String? status;

  KioskReportRow({
    this.employeeId,
    this.employeeName,
    this.checkIn,
    this.checkOut,
    this.isLate,
    this.isEarly,
    this.status,
  });

  factory KioskReportRow.fromJson(Map<String, dynamic> json) {
    return KioskReportRow(
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
      isLate: json['isLate'] as bool?,
      isEarly: json['isEarly'] as bool?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'isLate': isLate,
        'isEarly': isEarly,
        'status': status,
      };
}

/// Date-wise daily report (`GET face-attendance/kiosk/report?date=...`).
class KioskDailyReport {
  final String? date;
  final int? presentCount;
  final List<KioskReportRow> rows;

  KioskDailyReport({this.date, this.presentCount, required this.rows});

  factory KioskDailyReport.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as Map<String, dynamic>? ?? json;
    final list = (raw['rows'] ?? raw['data'] ?? []) as List;
    return KioskDailyReport(
      date: raw['date'] as String?,
      presentCount:
          raw['presentCount'] as int? ?? raw['present_count'] as int?,
      rows: list
          .map((e) => KioskReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
