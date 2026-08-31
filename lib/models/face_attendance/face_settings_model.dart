/// Tolerant int parsing for face-attendance payloads.
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

/// Converts a camelCase key to its snake_case equivalent (used to accept both
/// contract styles since ApiResponse snake_cases all keys on the wire).
String _snake(String camel) {
  return camel.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]}_${m[2]!.toLowerCase()}',
  );
}

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
    bool? b(String key) {
      final v = json[key] ?? json[_snake(key)];
      if (v == null) return null;
      if (v is bool) return v;
      return v is num ? v != 0 : (v.toString() == 'true' || v.toString() == '1');
    }

    int? n(String key) => _asInt(json[key] ?? json[_snake(key)]);

    return FaceModuleSettings(
      defaultThreshold: n('defaultThreshold'),
      minThreshold: n('minThreshold'),
      maxThreshold: n('maxThreshold'),
      requireLiveness: b('requireLiveness'),
      allowSelfRegistration: b('allowSelfRegistration'),
      selfRegistrationRequiresApproval: b('selfRegistrationRequiresApproval'),
      snapshotRetentionDays: n('snapshotRetentionDays'),
      attendanceModes: ((json['attendanceModes'] ?? json['attendance_modes'])
              as List?)
          ?.map((e) => e.toString())
          .toList(),
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
