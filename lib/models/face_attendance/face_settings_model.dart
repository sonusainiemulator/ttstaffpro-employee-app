class FaceModuleSettings {
  final int? defaultThreshold;
  final int? minThreshold;
  final int? maxThreshold;
  final bool? requireLiveness;
  final bool? allowSelfRegistration;
  final bool? selfRegistrationRequiresApproval;
  final int? snapshotRetentionDays;
  final List<String>? attendanceModes;

  FaceModuleSettings({
    this.defaultThreshold,
    this.minThreshold,
    this.maxThreshold,
    this.requireLiveness,
    this.allowSelfRegistration,
    this.selfRegistrationRequiresApproval,
    this.snapshotRetentionDays,
    this.attendanceModes,
  });

  factory FaceModuleSettings.fromJson(Map<String, dynamic> json) {
    return FaceModuleSettings(
      defaultThreshold: json['defaultThreshold'] as int?,
      minThreshold: json['minThreshold'] as int?,
      maxThreshold: json['maxThreshold'] as int?,
      requireLiveness: json['requireLiveness'] as bool?,
      allowSelfRegistration: json['allowSelfRegistration'] as bool?,
      selfRegistrationRequiresApproval: json['selfRegistrationRequiresApproval'] as bool?,
      snapshotRetentionDays: json['snapshotRetentionDays'] as int?,
      attendanceModes: (json['attendanceModes'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultThreshold': defaultThreshold,
      'minThreshold': minThreshold,
      'maxThreshold': maxThreshold,
      'requireLiveness': requireLiveness,
      'allowSelfRegistration': allowSelfRegistration,
      'selfRegistrationRequiresApproval': selfRegistrationRequiresApproval,
      'snapshotRetentionDays': snapshotRetentionDays,
      'attendanceModes': attendanceModes,
    };
  }
}
