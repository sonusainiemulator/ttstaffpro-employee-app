import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/store/global_attendance_store.dart';
import 'package:public_ip_address/public_ip_address.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../../main.dart';
import '../../../service/map_helper.dart';
import '../../../utils/design_system.dart';

class AttendanceTypeWidget extends StatefulWidget {
  final AttendanceType type;
  final bool showCard;
  const AttendanceTypeWidget({
    super.key,
    required this.type,
    this.showCard = true,
  });

  @override
  State<AttendanceTypeWidget> createState() => _AttendanceTypeWidgetState();
}

class _AttendanceTypeWidgetState extends State<AttendanceTypeWidget> {
  String ipAddress = language.lblGettingYourIPAddress;
  String address = language.lblGettingYourAddress;
  String attendanceType = '...';

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    if (widget.type == AttendanceType.ipAddress) {
      attendanceType = 'IP Based';
      var ip = IpAddress();
      var ipAdd = await ip.getIp();
      ipAddress = '$ipAdd ${language.lblIsYourIPAddress}';
    } else if (widget.type == AttendanceType.geofence) {
      attendanceType = 'Geofence';
      var mapHelper = MapHelper();
      address =
          await mapHelper.getCurrentAddress() ?? language.lblUnableToGetAddress;
    } else if (widget.type == AttendanceType.qr) {
      attendanceType = 'QR Code';
    } else if (widget.type == AttendanceType.dynamicQr) {
      attendanceType = 'Dynamic QR Code';
    } else if (widget.type == AttendanceType.face) {
      attendanceType = 'Face';
    } else {
      attendanceType = 'Open';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (globalAttendanceStore.isSiteEmployee)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppDesignSystem.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.building,
                  color: AppDesignSystem.primaryColor,
                  size: 16
                ),
                8.width,
                Text(
                  '${language.lblSite}: ${globalAttendanceStore.siteName}',
                  style: boldTextStyle(
                    size: 12,
                    color: AppDesignSystem.primaryColor,
                  ),
                ),
              ],
            ),
          ).paddingBottom(16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.lblAttendanceType,
                    style: secondaryTextStyle(
                      size: 12,
                      color: AppDesignSystem.neutral500,
                    ),
                  ),
                  6.height,
                  Text(
                    attendanceType,
                    style: boldTextStyle(
                      size: 18,
                      color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppDesignSystem.primaryColor,
              shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                HapticFeedback.lightImpact();
                appStore.refreshAttendanceStatus();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.refresh, color: white, size: 16).animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 3000.ms),
                  8.width,
                  Text(
                    language.lblRefresh,
                    style: boldTextStyle(color: white, size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        12.height,

        // Dynamic Content Based on Attendance Type
        _buildAttendanceDetails(),
      ],
    );

    return Observer(
      builder: (_) => widget.showCard
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: content,
            )
          : content,
    );
  }

  Widget _buildAttendanceDetails() {
    Widget detailRow(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appStore.isDarkModeOn
              ? const Color(0xFF111827)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: appStore.isDarkModeOn
                ? Colors.grey[700]!
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppDesignSystem.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppDesignSystem.primaryColor,
                size: 20,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, color: AppDesignSystem.primaryColor.withOpacity(0.2)),
            12.width,
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: appStore.isDarkModeOn
                      ? Colors.grey[300]
                      : const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.type == AttendanceType.ipAddress) {
      return detailRow(Iconsax.global, ipAddress);
    } else if (widget.type == AttendanceType.geofence) {
      return detailRow(Iconsax.location, address);
    } else if (widget.type == AttendanceType.qr) {
      return detailRow(Iconsax.scan, language.lblScanQRCodeToMarkAttendance);
    } else if (widget.type == AttendanceType.dynamicQr) {
      return detailRow(Icons.qr_code, language.lblDynamicQRCodeIsEnabled);
    } else if (widget.type == AttendanceType.face) {
      return detailRow(Icons.face, language.lblFaceRecognitionIsEnabled);
    } else {
      return detailRow(Iconsax.unlock, language.lblOpenAttendance);
    }
  }
}
