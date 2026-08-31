/// Tolerant int parsing for face-attendance payloads — accepts int, numeric
/// strings and null so a serializer mismatch can never crash a parser.
int? _intValue(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

class FaceProfileSummary {
  final int? id;
  final int? employeeId;
  final String? employeeName;
  final String? registrationMode;
  final String? status;
  final String? approvalStatus;
  final String? enrollmentVersion;
  final String? lastSyncedAt;

  FaceProfileSummary({
    this.id,
    this.employeeId,
    this.employeeName,
    this.registrationMode,
    this.status,
    this.approvalStatus,
    this.enrollmentVersion,
    this.lastSyncedAt,
  });

  factory FaceProfileSummary.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase and snake_case keys (ApiResponse snake_cases keys
    // on the wire) so `employee_id` / `approval_status` are not dropped.
    return FaceProfileSummary(
      id: _intValue(json['id']),
      employeeId: _intValue(json['employeeId'] ?? json['employee_id']),
      employeeName:
          json['employeeName'] as String? ?? json['employee_name'] as String?,
      registrationMode: json['registrationMode'] as String? ??
          json['registration_mode'] as String?,
      status: json['status'] as String?,
      approvalStatus: json['approvalStatus'] as String? ??
          json['approval_status'] as String?,
      enrollmentVersion:
          (json['enrollmentVersion'] ?? json['enrollment_version'])?.toString(),
      lastSyncedAt:
          (json['lastSyncedAt'] ?? json['last_synced_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'registrationMode': registrationMode,
      'status': status,
      'approvalStatus': approvalStatus,
      'enrollmentVersion': enrollmentVersion,
      'lastSyncedAt': lastSyncedAt,
    };
  }
}

class FaceEnrollmentImageMetadata {
  final String? imageUrl;
  final String? filePath;
  final String? captureType;
  final double? qualityScore;

  FaceEnrollmentImageMetadata({
    this.imageUrl,
    this.filePath,
    this.captureType,
    this.qualityScore,
  });

  factory FaceEnrollmentImageMetadata.fromJson(Map<String, dynamic> json) {
    // The backend returns both camelCase (raw) and snake_case (after
    // ApiResponse transform) keys — accept either so kiosk profile-package
    // downloads are parsed correctly.
    return FaceEnrollmentImageMetadata(
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      filePath: json['filePath'] as String? ?? json['file_path'] as String?,
      captureType:
          json['captureType'] as String? ?? json['capture_type'] as String?,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ??
          (json['quality_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'filePath': filePath,
      'captureType': captureType,
      'qualityScore': qualityScore,
    };
  }
}

class FaceAuditSummary {
  final String? remarks;
  final String? updatedBy;
  final String? updatedAt;

  FaceAuditSummary({
    this.remarks,
    this.updatedBy,
    this.updatedAt,
  });

  factory FaceAuditSummary.fromJson(Map<String, dynamic> json) {
    return FaceAuditSummary(
      remarks: json['remarks'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'remarks': remarks,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }
}

class FaceAssignedDevice {
  final String? deviceId;
  final String? deviceName;
  final String? status;

  FaceAssignedDevice({
    this.deviceId,
    this.deviceName,
    this.status,
  });

  factory FaceAssignedDevice.fromJson(Map<String, dynamic> json) {
    return FaceAssignedDevice(
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'status': status,
    };
  }
}

class FaceProfileDetail {
  final int? id;
  final int? employeeId;
  final String? employeeName;
  final String? registrationMode;
  final String? status;
  final String? approvalStatus;
  final String? enrollmentVersion;
  final String? lastSyncedAt;
  final List<FaceEnrollmentImageMetadata>? images;
  final List<FaceAuditSummary>? auditSummary;
  final List<FaceAssignedDevice>? assignedDevices;

  FaceProfileDetail({
    this.id,
    this.employeeId,
    this.employeeName,
    this.registrationMode,
    this.status,
    this.approvalStatus,
    this.enrollmentVersion,
    this.lastSyncedAt,
    this.images,
    this.auditSummary,
    this.assignedDevices,
  });

  factory FaceProfileDetail.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase and snake_case keys (ApiResponse snake_cases keys
    // on the wire).
    return FaceProfileDetail(
      id: _intValue(json['id']),
      employeeId: _intValue(json['employeeId'] ?? json['employee_id']),
      employeeName: json['employeeName'] as String? ??
          json['employee_name'] as String?,
      registrationMode: json['registrationMode'] as String? ??
          json['registration_mode'] as String?,
      status: json['status'] as String?,
      approvalStatus: json['approvalStatus'] as String? ??
          json['approval_status'] as String?,
      enrollmentVersion:
          (json['enrollmentVersion'] ?? json['enrollment_version'])?.toString(),
      lastSyncedAt:
          (json['lastSyncedAt'] ?? json['last_synced_at'])?.toString(),
      images: (json['images'] as List?)
          ?.map((e) => FaceEnrollmentImageMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditSummary: (json['auditSummary'] as List?)
          ?.map((e) => FaceAuditSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignedDevices: (json['assignedDevices'] as List?)
          ?.map((e) => FaceAssignedDevice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'registrationMode': registrationMode,
      'status': status,
      'approvalStatus': approvalStatus,
      'enrollmentVersion': enrollmentVersion,
      'lastSyncedAt': lastSyncedAt,
      'images': images?.map((e) => e.toJson()).toList(),
      'auditSummary': auditSummary?.map((e) => e.toJson()).toList(),
      'assignedDevices': assignedDevices?.map((e) => e.toJson()).toList(),
    };
  }
}
