class FaceDashboardSummary {
  final int? presentEmployees;
  final int? absentEmployees;
  final int? lateEmployees;
  final int? onLeaveEmployees;
  final int? currentWorkforce;
  final int? unknownFacesToday;
  final int? spoofAttemptsToday;
  final int? offlineDevices;

  FaceDashboardSummary({
    this.presentEmployees,
    this.absentEmployees,
    this.lateEmployees,
    this.onLeaveEmployees,
    this.currentWorkforce,
    this.unknownFacesToday,
    this.spoofAttemptsToday,
    this.offlineDevices,
  });

  factory FaceDashboardSummary.fromJson(Map<String, dynamic> json) {
    return FaceDashboardSummary(
      presentEmployees: json['presentEmployees'] as int?,
      absentEmployees: json['absentEmployees'] as int?,
      lateEmployees: json['lateEmployees'] as int?,
      onLeaveEmployees: json['onLeaveEmployees'] as int?,
      currentWorkforce: json['currentWorkforce'] as int?,
      unknownFacesToday: json['unknownFacesToday'] as int?,
      spoofAttemptsToday: json['spoofAttemptsToday'] as int?,
      offlineDevices: json['offlineDevices'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'presentEmployees': presentEmployees,
      'absentEmployees': absentEmployees,
      'lateEmployees': lateEmployees,
      'onLeaveEmployees': onLeaveEmployees,
      'currentWorkforce': currentWorkforce,
      'unknownFacesToday': unknownFacesToday,
      'spoofAttemptsToday': spoofAttemptsToday,
      'offlineDevices': offlineDevices,
    };
  }
}

class RecognitionAuditEntry {
  final String? eventUuid;
  final int? employeeId;
  final String? employeeName;
  final String? deviceId;
  final String? deviceName;
  final String? eventType;
  final String? recognitionStatus;
  final double? confidenceScore;
  final String? occurredAt;
  final String? snapshotUrl;

  RecognitionAuditEntry({
    this.eventUuid,
    this.employeeId,
    this.employeeName,
    this.deviceId,
    this.deviceName,
    this.eventType,
    this.recognitionStatus,
    this.confidenceScore,
    this.occurredAt,
    this.snapshotUrl,
  });

  factory RecognitionAuditEntry.fromJson(Map<String, dynamic> json) {
    return RecognitionAuditEntry(
      eventUuid: json['eventUuid'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      eventType: json['eventType'] as String?,
      recognitionStatus: json['recognitionStatus'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      occurredAt: json['occurredAt'] as String?,
      snapshotUrl: json['snapshotUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'eventType': eventType,
      'recognitionStatus': recognitionStatus,
      'confidenceScore': confidenceScore,
      'occurredAt': occurredAt,
      'snapshotUrl': snapshotUrl,
    };
  }
}

class FailedRecognitionEntry {
  final String? eventUuid;
  final String? deviceId;
  final String? deviceName;
  final String? occurredAt;
  final String? failureReason;
  final String? snapshotUrl;

  FailedRecognitionEntry({
    this.eventUuid,
    this.deviceId,
    this.deviceName,
    this.occurredAt,
    this.failureReason,
    this.snapshotUrl,
  });

  factory FailedRecognitionEntry.fromJson(Map<String, dynamic> json) {
    return FailedRecognitionEntry(
      eventUuid: json['eventUuid'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      occurredAt: json['occurredAt'] as String?,
      failureReason: json['failureReason'] as String?,
      snapshotUrl: json['snapshotUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'occurredAt': occurredAt,
      'failureReason': failureReason,
      'snapshotUrl': snapshotUrl,
    };
  }
}

class SpoofEventEntry {
  final String? eventUuid;
  final int? employeeId;
  final String? employeeName;
  final String? deviceId;
  final String? deviceName;
  final String? occurredAt;
  final double? confidenceScore;
  final String? snapshotUrl;

  SpoofEventEntry({
    this.eventUuid,
    this.employeeId,
    this.employeeName,
    this.deviceId,
    this.deviceName,
    this.occurredAt,
    this.confidenceScore,
    this.snapshotUrl,
  });

  factory SpoofEventEntry.fromJson(Map<String, dynamic> json) {
    return SpoofEventEntry(
      eventUuid: json['eventUuid'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      occurredAt: json['occurredAt'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      snapshotUrl: json['snapshotUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'occurredAt': occurredAt,
      'confidenceScore': confidenceScore,
      'snapshotUrl': snapshotUrl,
    };
  }
}

class DeviceHealthStatus {
  final String? deviceId;
  final String? deviceName;
  final String? status;
  final int? batteryLevel;
  final String? networkState;
  final String? storageState;
  final String? lastHeartbeatAt;
  final String? appVersion;

  DeviceHealthStatus({
    this.deviceId,
    this.deviceName,
    this.status,
    this.batteryLevel,
    this.networkState,
    this.storageState,
    this.lastHeartbeatAt,
    this.appVersion,
  });

  factory DeviceHealthStatus.fromJson(Map<String, dynamic> json) {
    return DeviceHealthStatus(
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      status: json['status'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      networkState: json['networkState'] as String?,
      storageState: json['storageState'] as String?,
      lastHeartbeatAt: json['lastHeartbeatAt'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'status': status,
      'batteryLevel': batteryLevel,
      'networkState': networkState,
      'storageState': storageState,
      'lastHeartbeatAt': lastHeartbeatAt,
      'appVersion': appVersion,
    };
  }
}
