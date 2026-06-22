class DeviceRegistrationRequest {
  final String deviceUuid;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String mlRuntime;
  final int? branchId;

  DeviceRegistrationRequest({
    required this.deviceUuid,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.mlRuntime,
    this.branchId,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceUuid': deviceUuid,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'mlRuntime': mlRuntime,
      if (branchId != null) 'branchId': branchId,
    };
  }
}

class DeviceRegistrationResult {
  final String? deviceId;
  final String? deviceToken;
  final String? status;
  final dynamic assignedBranch;

  DeviceRegistrationResult({
    this.deviceId,
    this.deviceToken,
    this.status,
    this.assignedBranch,
  });

  factory DeviceRegistrationResult.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResult(
      deviceId: json['deviceId']?.toString(),
      deviceToken: json['deviceToken']?.toString(),
      status: json['status']?.toString(),
      assignedBranch: json['assignedBranch'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceToken': deviceToken,
      'status': status,
      'assignedBranch': assignedBranch,
    };
  }
}

class DeviceHeartbeatBody {
  final int batteryLevel;
  final String networkState;
  final String storageState;
  final String appVersion;

  DeviceHeartbeatBody({
    required this.batteryLevel,
    required this.networkState,
    required this.storageState,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'batteryLevel': batteryLevel,
      'networkState': networkState,
      'storageState': storageState,
      'appVersion': appVersion,
    };
  }
}

class ProfilePackageVersion {
  final String? packageVersion;
  final int? profilesCount;
  final bool? downloadRequired;

  ProfilePackageVersion({
    this.packageVersion,
    this.profilesCount,
    this.downloadRequired,
  });

  factory ProfilePackageVersion.fromJson(Map<String, dynamic> json) {
    return ProfilePackageVersion(
      packageVersion: json['packageVersion']?.toString(),
      profilesCount: json['profilesCount'] as int?,
      downloadRequired: json['downloadRequired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageVersion': packageVersion,
      'profilesCount': profilesCount,
      'downloadRequired': downloadRequired,
    };
  }
}
