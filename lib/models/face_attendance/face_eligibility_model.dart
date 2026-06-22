import 'face_profile_model.dart';

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
    return FaceEligibility(
      canRegister: json['canRegister'] as bool?,
      employeeId: json['employeeId'] as int?,
      hasExistingProfile: json['hasExistingProfile'] as bool?,
      profileStatus: json['profileStatus'] as String?,
      requiresApproval: json['requiresApproval'] as bool?,
      registrationWindowOpen: json['registrationWindowOpen'] as bool?,
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
    return OwnFaceProfileStatus(
      profileStatus: json['profileStatus'] as String?,
      approvalStatus: json['approvalStatus'] as String?,
      lastRegisteredAt: json['lastRegisteredAt'] as String?,
      lastApprovedAt: json['lastApprovedAt'] as String?,
      canRefresh: json['canRefresh'] as bool?,
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
