/// Tolerant int parsing for face-attendance payloads.
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

/// Converts a camelCase key to its snake_case equivalent (used to accept both
/// contract styles since ApiResponse snake_cases all keys on the wire).
String _snake(String camel) {
  return camel.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]}_${m[2]!.toLowerCase()}',
  );
}

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
    // Accept both camelCase and snake_case keys (ApiResponse snake_cases keys
    // on the wire).
    int? val(String key) =>
        _asInt(json[key] ?? json[_snake(key)]);
    return FaceDashboardSummary(
      presentEmployees: val('presentEmployees'),
      absentEmployees: val('absentEmployees'),
      lateEmployees: val('lateEmployees'),
      onLeaveEmployees: val('onLeaveEmployees'),
      currentWorkforce: val('currentWorkforce'),
      unknownFacesToday: val('unknownFacesToday'),
      spoofAttemptsToday: val('spoofAttemptsToday'),
      offlineDevices: val('offlineDevices'),
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
      eventUuid: json['eventUuid'] as String? ?? json['event_uuid'] as String?,
      employeeId: _asInt(json['employeeId'] ?? json['employee_id']),
      employeeName: json['employeeName'] as String? ??
          json['employee_name'] as String?,
      deviceId: json['deviceId'] as String? ?? json['device_id'] as String?,
      deviceName: json['deviceName'] as String? ??
          json['device_name'] as String?,
      eventType: json['eventType'] as String? ?? json['event_type'] as String?,
      recognitionStatus: json['recognitionStatus'] as String? ??
          json['recognition_status'] as String?,
      confidenceScore: _asNum(
            json['confidenceScore'] ?? json['confidence_score'],
          )?.toDouble(),
      occurredAt: json['occurredAt'] as String? ??
          json['occurred_at'] as String?,
      snapshotUrl: json['snapshotUrl'] as String? ??
          json['snapshot_url'] as String?,
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
      eventUuid: json['eventUuid'] as String? ?? json['event_uuid'] as String?,
      deviceId: json['deviceId'] as String? ?? json['device_id'] as String?,
      deviceName: json['deviceName'] as String? ??
          json['device_name'] as String?,
      occurredAt: json['occurredAt'] as String? ??
          json['occurred_at'] as String?,
      failureReason: json['failureReason'] as String? ??
          json['failure_reason'] as String?,
      snapshotUrl: json['snapshotUrl'] as String? ??
          json['snapshot_url'] as String?,
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
      eventUuid: json['eventUuid'] as String? ?? json['event_uuid'] as String?,
      employeeId: _asInt(json['employeeId'] ?? json['employee_id']),
      employeeName: json['employeeName'] as String? ??
          json['employee_name'] as String?,
      deviceId: json['deviceId'] as String? ?? json['device_id'] as String?,
      deviceName: json['deviceName'] as String? ??
          json['device_name'] as String?,
      occurredAt: json['occurredAt'] as String? ??
          json['occurred_at'] as String?,
      confidenceScore: _asNum(
            json['confidenceScore'] ?? json['confidence_score'],
          )?.toDouble(),
      snapshotUrl: json['snapshotUrl'] as String? ??
          json['snapshot_url'] as String?,
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
      deviceId: json['deviceId'] as String? ?? json['device_id'] as String?,
      deviceName: json['deviceName'] as String? ??
          json['device_name'] as String?,
      status: json['status'] as String?,
      batteryLevel: _asInt(json['batteryLevel'] ?? json['battery_level']),
      networkState: json['networkState'] as String? ??
          json['network_state'] as String?,
      storageState: json['storageState'] as String? ??
          json['storage_state'] as String?,
      lastHeartbeatAt: json['lastHeartbeatAt'] as String? ??
          json['last_heartbeat_at'] as String?,
      appVersion: json['appVersion'] as String? ??
          json['app_version'] as String?,
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
