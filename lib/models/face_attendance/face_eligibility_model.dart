import 'face_profile_model.dart';

/// Tolerant bool parsing for face-attendance payloads — accepts real bools,
/// 0/1 and common string forms.
bool? _boolValue(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lowered = v.trim().toLowerCase();
    if (lowered == 'true' || lowered == '1' || lowered == 'yes') return true;
    if (lowered == 'false' || lowered == '0' || lowered == 'no') return false;
  }
  return null;
}

int? _intValue(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

class FaceEligibility {
  final bool? canRegister;
  final int? employeeId;
  final bool? hasExistingProfile;
  final String? profileStatus;
  final bool? requiresApproval;
  final bool? registrationWindowOpen;

  FaceEligibility({
    this.canRegister,
    this.employeeId,
    this.hasExistingProfile,
    this.profileStatus,
    this.requiresApproval,
    this.registrationWindowOpen,
  });

  factory FaceEligibility.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase and snake_case keys (ApiResponse snake_cases keys
    // on the wire).
    return FaceEligibility(
      canRegister: _boolValue(json['canRegister'] ?? json['can_register']),
      employeeId: _intValue(json['employeeId'] ?? json['employee_id']),
      hasExistingProfile: _boolValue(
        json['hasExistingProfile'] ?? json['has_existing_profile'],
      ),
      profileStatus:
          json['profileStatus'] as String? ?? json['profile_status'] as String?,
      requiresApproval: _boolValue(
        json['requiresApproval'] ?? json['requires_approval'],
      ),
      registrationWindowOpen: _boolValue(
        json['registrationWindowOpen'] ?? json['registration_window_open'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canRegister': canRegister,
      'employeeId': employeeId,
      'hasExistingProfile': hasExistingProfile,
      'profileStatus': profileStatus,
      'requiresApproval': requiresApproval,
      'registrationWindowOpen': registrationWindowOpen,
    };
  }
}

class OwnFaceProfileStatus {
  final String? profileStatus;
  final String? approvalStatus;
  final String? lastRegisteredAt;
  final String? lastApprovedAt;
  final bool? canRefresh;
  final List<FaceEnrollmentImageMetadata>? images;

  OwnFaceProfileStatus({
    this.profileStatus,
    this.approvalStatus,
    this.lastRegisteredAt,
    this.lastApprovedAt,
    this.canRefresh,
    this.images,
  });

  factory OwnFaceProfileStatus.fromJson(Map<String, dynamic> json) {
    // self/profile returns the snake_cased FaceProfile model: `status`,
    // `approval_status`, `approved_at`, `created_at`, `images`. Accept both
    // the model keys and the camelCase contract.
    return OwnFaceProfileStatus(
      profileStatus: json['profileStatus'] as String? ??
          json['profile_status'] as String? ??
          json['status'] as String?,
      approvalStatus: json['approvalStatus'] as String? ??
          json['approval_status'] as String?,
      lastRegisteredAt: json['lastRegisteredAt'] as String? ??
          json['last_registered_at'] as String? ??
          json['created_at'] as String?,
      lastApprovedAt: json['lastApprovedAt'] as String? ??
          json['last_approved_at'] as String? ??
          json['approved_at'] as String?,
      canRefresh: _boolValue(json['canRefresh'] ?? json['can_refresh']),
      images: (json['images'] as List?)
          ?.map((e) => FaceEnrollmentImageMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileStatus': profileStatus,
      'approvalStatus': approvalStatus,
      'lastRegisteredAt': lastRegisteredAt,
      'lastApprovedAt': lastApprovedAt,
      'canRefresh': canRefresh,
      'images': images?.map((e) => e.toJson()).toList(),
    };
  }
}
