import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:public_ip_address/public_ip_address.dart';

import '../api/result.dart';
import '../main.dart';
import 'package:open_core_hr/models/status/status_response.dart';
import '../api/dio_api/repositories/attendance_repository.dart';

part 'global_attendance_store.g.dart';

class GlobalAttendanceStore = GlobalAttendanceStoreBase
    with _$GlobalAttendanceStore;

abstract class GlobalAttendanceStoreBase with Store {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  @observable
  bool isInOutBtnLoading = false;

  @observable
  bool isBreakBtnLoading = false;

  final Location locationService = Location();

  @observable
  StatusResponse? currentStatus = StatusResponse();

  @computed
  bool get isKillDevice {
    return currentStatus != null && currentStatus!.deviceStatus?.toLowerCase() == 'kill';
  }

  @computed
  bool get isNew {
    return currentStatus != null && currentStatus!.status?.toLowerCase() == 'new';
  }

  @computed
  bool get isCheckedIn {
    return currentStatus != null && currentStatus!.status?.toLowerCase() == 'checkedin';
  }

  @computed
  bool get isLate {
    if (currentStatus != null && currentStatus!.isLate != null) {
      return currentStatus!.isLate!;
    } else {
      return false;
    }
  }

  @computed
  bool get isCheckedOut {
    return currentStatus != null && currentStatus!.status?.toLowerCase() == 'checkedout';
  }

  @computed
  String get trackedHours {
    if (currentStatus != null && currentStatus!.trackedHours != null) {
      return currentStatus!.trackedHours.toString();
    } else {
      return '';
    }
  }

  @computed
  String get travelledDistance {
    if (currentStatus != null && currentStatus!.travelledDistance != null) {
      return currentStatus!.travelledDistance!.toStringAsFixed(0);
    } else {
      return '';
    }
  }

  @computed
  bool get isSiteEmployee {
    if (currentStatus != null && currentStatus!.isSiteEmployee != null) {
      return currentStatus!.isSiteEmployee!;
    } else {
      return false;
    }
  }

  @computed
  String get siteName {
    if (currentStatus != null && currentStatus!.siteName != null) {
      return currentStatus!.siteName!;
    } else {
      return '';
    }
  }

  @computed
  AttendanceType get attendanceType {
    if (currentStatus != null && currentStatus!.attendanceType != null) {
      switch (currentStatus!.attendanceType!.toLowerCase()) {
        case 'geofence':
          return AttendanceType.geofence;
        case 'ip':
          return AttendanceType.ipAddress;
        case 'staticqrcode':
          return AttendanceType.qr;
        case 'dynamicqrcode':
          return AttendanceType.dynamicQr;
        case 'face':
          return AttendanceType.face;
        default:
          return AttendanceType.none;
      }
    } else {
      return AttendanceType.none;
    }
  }

  @action
  Future<bool> validateQrCode(String qrCode) async {
    isInOutBtnLoading = true;
    var result = await _attendanceRepository.verifyQr(qrCode);
    if (result) {
      isInOutBtnLoading = false;
      toast('Your QR code is verified');
      return true;
    }
    isInOutBtnLoading = false;
    return false;
  }

  @action
  Future<bool> validateDynamicQrCode(String qrCode) async {
    isInOutBtnLoading = true;
    var result = await _attendanceRepository.verifyDynamicQr(qrCode);
    if (result) {
      isInOutBtnLoading = false;
      toast('Your QR code is verified');
      return true;
    }
    isInOutBtnLoading = false;
    return false;
  }

  @action
  Future<bool> validateIpAddress() async {
    isInOutBtnLoading = true;
    var ipAdd = IpAddress();
    var ip = await ipAdd.getIp();
    var result = await _attendanceRepository.validateIpAddress(ip);
    if (result) {
      toast('Your IP address is verified');
      isInOutBtnLoading = false;
      return true;
    } else {
      toast('You are not in the IP address range');
    }
    isInOutBtnLoading = false;
    return false;
  }

  @action
  Future<bool> startStopBreak() async {
    isBreakBtnLoading = true;
    var result = await _attendanceRepository.startStopBreak();
    await appStore.refreshAttendanceStatus();

    isBreakBtnLoading = false;
    return result;
  }

  @computed
  bool get isOnBreak {
    if (currentStatus != null &&
        currentStatus!.isOnBreak != null &&
        currentStatus!.isOnBreak!) {
      return true;
    } else {
      return false;
    }
  }

  @computed
  DateTime get breakStartAt {
    if (isOnBreak &&
        currentStatus != null &&
        !currentStatus!.breakStartedAt.isEmptyOrNull) {
      try {
        var format = DateFormat('dd-MM-yy HH:mm:ss a');
        var nowDateString = DateFormat('dd-MM-yy').format(DateTime.now());
        return format.parse('$nowDateString ${currentStatus!.breakStartedAt}');
      } catch (e) {
        log('Error parsing break start time: $e');
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  @computed
  String get shiftStartAt {
    if (currentStatus != null && currentStatus!.shiftStartAt != null) {
      return currentStatus!.shiftStartAt!;
    } else {
      return '';
    }
  }

  @computed
  String get shiftEndAt {
    if (currentStatus != null && currentStatus!.shiftEndAt != null) {
      return currentStatus!.shiftEndAt!;
    } else {
      return '';
    }
  }

  @action
  Future<bool> validateGeofence() async {
    isInOutBtnLoading = true;
    var location = await locationService.getLocation();
    if (location.latitude == null || location.longitude == null) {
      toast('Unable to get device location');
      isInOutBtnLoading = false;
      return false;
    }
    var result = await _attendanceRepository.validateGeofence(
        location.latitude!, location.longitude!);
    if (result) {
      toast('Your location is verified');
      isInOutBtnLoading = false;
      return true;
    }

    toast('You are not in the geofence area');
    isInOutBtnLoading = false;
    return false;
  }

  @action
  Future<bool> setEarlyCheckoutReason(String reason) async {
    isInOutBtnLoading = true;
    var result = await _attendanceRepository.setEarlyCheckoutReason(reason);
    if (result) {
      toast('Reason updated');
      isInOutBtnLoading = false;
      return true;
    }
    toast('Failed to update reason');
    isInOutBtnLoading = false;
    return false;
  }

  @action
  void setCurrentStatus(StatusResponse status) {
    currentStatus = status;
  }

  @action
  Future<Result> checkInOut(AttendanceStatus status,
      {String? lateCheckInReason, String? earlyCheckoutReason, bool? overtimeTask, String? overtimeTaskNote}) async {
    isInOutBtnLoading = true;

    var location = await locationService.getLocation();
    if (location.latitude == null || location.longitude == null) {
      toast('Unable to get device location');
      return Result()..message = 'Unable to get device location'..isSuccess = false;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    Map<String, dynamic> req = {
      "status": status == AttendanceStatus.checkIn ? 'checkin' : 'checkout',
      "lateReason": lateCheckInReason,
      "earlyCheckoutReason": earlyCheckoutReason,
      "overtimeTask": overtimeTask,
      "overtimeTaskNote": overtimeTaskNote,
      "latitude": location.latitude,
      "longitude": location.longitude,
      "altitude": location.altitude ?? 0,
      "bearing": 0,
      "locationAccuracy": location.accuracy ?? 0,
      "speed": location.speed ?? 0,
      "time": location.time ?? 0,
      "isMock": location.isMock ?? false,
      "batteryPercentage": 100,  // Default battery level since tracking is removed
      "isLocationOn": true,
      "isWifiOn": connectivityResult
          .where((element) => element == ConnectivityResult.wifi)
          .isNotEmpty,
      "signalStrength": 5
    };

    var result = await _attendanceRepository.checkInOut(req);
    if (!result.isSuccess) {
      toast(result.message);
      isInOutBtnLoading = false;
      return result;
    }
    var statusResult = await _attendanceRepository.checkAttendanceStatus();
    if (statusResult != null) {
      appStore.setCurrentStatus(statusResult);
    }
    toast(
        'Successfully ${status == AttendanceStatus.checkIn ? 'checked in' : 'checked out'}');
    isInOutBtnLoading = false;
    return result;
  }

}

enum AttendanceStatus { checkIn, checkOut, newStatus }

enum AttendanceType { geofence, ipAddress, none, qr, dynamicQr, face }
