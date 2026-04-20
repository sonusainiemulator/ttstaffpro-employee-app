class UserModel {
  String? id,
      firstName,
      lastName,
      avatar,
      gender,
      address,
      phoneNumber,
      alternateNumber,
      status,
      token,
      email,
      designation,
      employeeCode;

  bool? locationActivityTrackingEnabled,
      isApprover,
      isLeaveApprover,
      isExpenseApprover;

  UserModel(
      {this.id,
      this.firstName,
      this.lastName,
      this.avatar,
      this.gender,
      this.address,
      this.phoneNumber,
      this.alternateNumber,
      this.status,
      this.token,
      this.email,
      this.employeeCode,
      this.designation,
      this.locationActivityTrackingEnabled,
      this.isApprover,
      this.isLeaveApprover,
      this.isExpenseApprover});

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    Map<String, dynamic> userData = json;
    if (json.containsKey('user') && json['user'] is Map) {
      userData = json['user'];
    } else if (json.containsKey('employee') && json['employee'] is Map) {
      userData = json['employee'];
    }

    return UserModel(
      id: (userData['id'] ?? json['id'])?.toString(),
      firstName: (userData['firstName'] ?? json['firstName'])?.toString(),
      lastName: (userData['lastName'] ?? json['lastName'])?.toString(),
      avatar: (userData['avatar'] ?? json['avatar'])?.toString(),
      gender: (userData['gender'] ?? json['gender'])?.toString(),
      address: (userData['address'] ?? json['address'])?.toString(),
      phoneNumber: (userData['phoneNumber'] ?? json['phoneNumber'])?.toString(),
      alternateNumber: (userData['alternateNumber'] ?? json['alternateNumber'])?.toString(),
      status: (userData['status'] ?? json['status'])?.toString(),
      token: (json['token'] ?? userData['token'])?.toString(),
      employeeCode: (userData['employeeCode'] ?? json['employeeCode'])?.toString(),
      email: (userData['email'] ?? json['email'])?.toString(),
      designation: (userData['designation'] ?? json['designation'])?.toString(),
      locationActivityTrackingEnabled:
          userData['isLocationActivityTrackingEnabled'] ?? json['isLocationActivityTrackingEnabled'] ?? false,
      isApprover: userData['isApprover'] ?? json['isApprover'] ?? false,
      isLeaveApprover: userData['isLeaveApprover'] ?? json['isLeaveApprover'] ?? false,
      isExpenseApprover: userData['isExpenseApprover'] ?? json['isExpenseApprover'] ?? false,
    );
  }
}
