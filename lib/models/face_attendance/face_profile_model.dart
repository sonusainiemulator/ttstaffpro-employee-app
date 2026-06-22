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
    return FaceProfileSummary(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      registrationMode: json['registrationMode'] as String?,
      status: json['status'] as String?,
      approvalStatus: json['approvalStatus'] as String?,
      enrollmentVersion: json['enrollmentVersion']?.toString(),
      lastSyncedAt: json['lastSyncedAt'] as String?,
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
  final String? captureType;
  final double? qualityScore;

  FaceEnrollmentImageMetadata({
    this.imageUrl,
    this.captureType,
    this.qualityScore,
  });

  factory FaceEnrollmentImageMetadata.fromJson(Map<String, dynamic> json) {
    return FaceEnrollmentImageMetadata(
      imageUrl: json['imageUrl'] as String?,
      captureType: json['captureType'] as String?,
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
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
    return FaceProfileDetail(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      registrationMode: json['registrationMode'] as String?,
      status: json['status'] as String?,
      approvalStatus: json['approvalStatus'] as String?,
      enrollmentVersion: json['enrollmentVersion']?.toString(),
      lastSyncedAt: json['lastSyncedAt'] as String?,
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
