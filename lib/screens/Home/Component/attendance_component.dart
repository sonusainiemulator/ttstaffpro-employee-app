import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../Widgets/home_attendance_loading_widget.dart';
import '../../../main.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/design_system.dart';
import 'attendance_type_widget.dart';
import 'in_out_component.dart';

class AttendanceComponent extends StatefulWidget {
  const AttendanceComponent({super.key});

  @override
  State<AttendanceComponent> createState() => _AttendanceComponentState();
}

class _AttendanceComponentState extends State<AttendanceComponent> {
  bool get _isTrackingEnabled =>
      getBoolAsync(locationActivityTrackingEnabledPref, defaultValue: false);

  bool get _isTrackingStarted =>
      globalAttendanceStore.isCheckedIn || globalAttendanceStore.isOnBreak;

  Widget _buildTrackingStatusChips() {
    final bool hasStartedAt =
        (globalAttendanceStore.currentStatus?.checkInAt ?? '').trim().isNotEmpty;
    final bool canShowStartedChip = _isTrackingStarted && hasStartedAt;

    Widget buildChip({
      required IconData icon,
      required String label,
      required Color foreground,
      required Color background,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            6.width,
            Text(
              label,
              style: boldTextStyle(size: 11, color: foreground),
            ),
          ],
        ),
      );
    }

    final Color enabledFg = const Color(0xFF15803D);
    final Color enabledBg = const Color(0xFFDCFCE7);
    final Color disabledFg = appStore.isDarkModeOn ? Colors.grey[300]! : const Color(0xFF6B7280);
    final Color disabledBg = appStore.isDarkModeOn ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildChip(
          icon: _isTrackingEnabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
          label:
              '${language.lblOfflineTracking}: ${_isTrackingEnabled ? language.lblEnabled : language.lblDisabled}',
          foreground: _isTrackingEnabled ? enabledFg : disabledFg,
          background: _isTrackingEnabled ? enabledBg : disabledBg,
        ),
        if (canShowStartedChip)
          buildChip(
            icon: Icons.location_on_outlined,
            label:
                '${language.lblTrackingStartedAt} ${globalAttendanceStore.currentStatus!.checkInAt}',
            foreground: enabledFg,
            background: enabledBg,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => appStore.isStatusCheckLoading
          ? CustomLoadingWidget()
          : globalAttendanceStore.isNew ||
                  globalAttendanceStore.isCheckedIn ||
                  globalAttendanceStore.isCheckedOut
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusXLarge),
                    boxShadow: AppDesignSystem.shadowMedium,
                    border: Border.all(
                      color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrackingStatusChips(),

                      16.height,

                      // Attendance Type Section
                      AttendanceTypeWidget(
                        type: globalAttendanceStore.attendanceType,
                        showCard: false, // Don't show card wrapper
                      ),

                      16.height,

                      // Divider
                      Divider(color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withValues(alpha: 0.1)),

                      16.height,

                      // Check-in/out Section
                      const InOutComponent(
                        showCard: false, // Don't show card wrapper
                      ),
                    ],
                  ),
                )
              : Container(),
    );
  }
}
