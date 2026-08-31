/// Kiosk (tablet) models for single-point face attendance.
///
/// These back the wall-mounted kiosk flow:
///  - Company name match on login
///  - Master login (single tablet account)
///  - Date-wise staff attendance report with check-in / check-out
library;

/// Tolerant bool parsing for kiosk payloads — accepts real bools, 0/1 and
/// common string forms so a mismatch in the server serializer can never crash
/// or drop a row.
bool? _kioskBoolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lowered = value.trim().toLowerCase();
    if (lowered == 'true' || lowered == '1' || lowered == 'yes') return true;
    if (lowered == 'false' || lowered == '0' || lowered == 'no') return false;
  }
  return null;
}

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

  /// Whether this employee already has a registered face. When the employees
  /// endpoint does not provide it, the kiosk fills it from the approved
  /// admin-profiles list so the picker can show “Face Registered”.
  final bool? faceRegistered;
  final String? profileStatus;

  KioskEmployee({
    this.employeeId,
    this.name,
    this.email,
    this.code,
    this.faceRegistered,
    this.profileStatus,
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
      faceRegistered: _kioskBoolValue(
        json['faceRegistered'] ??
            json['face_registered'] ??
            json['hasFace'] ??
            json['has_face'] ??
            json['isRegistered'] ??
            json['is_registered'],
      ),
      profileStatus: (json['profileStatus'] ??
              json['profile_status'] ??
              json['faceProfileStatus'] ??
              json['face_profile_status'])
          ?.toString(),
    );
  }

  /// Returns a copy with face-registration status filled in (used to enrich
  /// employees from the approved-profiles list without mutating the original).
  KioskEmployee copyWith({bool? faceRegistered, String? profileStatus}) {
    return KioskEmployee(
      employeeId: employeeId,
      name: name,
      email: email,
      code: code,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      profileStatus: profileStatus ?? this.profileStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'name': name,
        'email': email,
        'code': code,
        'faceRegistered': faceRegistered,
        'profileStatus': profileStatus,
      };
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
  final String? markedAt;

  KioskReportRow({
    this.employeeId,
    this.employeeName,
    this.checkIn,
    this.checkOut,
    this.isLate,
    this.isEarly,
    this.status,
    this.markedAt,
  });

  factory KioskReportRow.fromJson(Map<String, dynamic> json) {
    final rawId = json['employeeId'] ?? json['employee_id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    final name = (json['employeeName'] ?? json['employee_name'])?.toString();
    final checkInRaw = json['checkIn'] ?? json['check_in'] ?? json['checkin'];
    final checkOutRaw = json['checkOut'] ?? json['check_out'] ?? json['checkout'];
    final markedAtRaw = json['markedAt'] ?? json['marked_at'] ?? json['attendanceTime'];

    return KioskReportRow(
      employeeId: id,
      employeeName: name,
      checkIn: checkInRaw?.toString(),
      checkOut: checkOutRaw?.toString(),
      isLate: _kioskBoolValue(json['isLate'] ?? json['is_late'] ?? json['late']),
      isEarly:
          _kioskBoolValue(json['isEarly'] ?? json['is_early'] ?? json['early']),
      status: (json['status'] ?? json['attendance_status'])?.toString(),
      markedAt: markedAtRaw?.toString(),
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
        'markedAt': markedAt,
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
    final rowsValue = raw['rows'] ?? raw['data'] ?? [];
    final list = rowsValue is List ? rowsValue : const <dynamic>[];
    return KioskDailyReport(
      date: (raw['date'] ?? raw['attendanceDate'])?.toString(),
      presentCount: (raw['presentCount'] ?? raw['present_count']) is int
          ? (raw['presentCount'] ?? raw['present_count']) as int
          : int.tryParse('${raw['presentCount'] ?? raw['present_count']}'),
      rows: list
          .map((e) => KioskReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
