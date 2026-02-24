import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../Widgets/home_attendance_loading_widget.dart';
import '../../../main.dart';
import '../../../utils/design_system.dart';
import 'attendance_type_widget.dart';
import 'in_out_component.dart';

class AttendanceComponent extends StatefulWidget {
  const AttendanceComponent({super.key});

  @override
  State<AttendanceComponent> createState() => _AttendanceComponentState();
}

class _AttendanceComponentState extends State<AttendanceComponent> {
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
                      color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attendance Type Section
                      AttendanceTypeWidget(
                        type: globalAttendanceStore.attendanceType,
                        showCard: false, // Don't show card wrapper
                      ),

                      16.height,

                      // Divider
                      Divider(color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.1)),

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
