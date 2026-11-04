import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_widgets.dart';
import '../../utils/design_system.dart';
import '../Account/account_screen.dart';
import '../Assets/assets_list_screen.dart';
import '../AttendanceHistory/actual_time_report_screen.dart';
import '../AttendanceHistory/attendance_history_screen.dart';
import '../AttendanceRegularization/attendance_regularization_list_screen.dart';
import '../Calendar/calendar_screen.dart';
import '../DigitalId/digital_id_card_screen.dart';
import '../Disciplinary/warnings_list_screen.dart';
import '../Document/DocumentManagement/document_management_home_screen.dart';
import '../FaceAttendance/face_registration_screen.dart';
import '../Holidays/holiday_screen.dart';
import '../Loan/loan_screen.dart';
import '../NoticeBoard/notice_board_screen.dart';
import '../Notification/notification_screen.dart';
import '../Payroll/payroll_dashboard_screen.dart';
import 'Component/attendance_component.dart';
import 'Component/demo_mode_banner.dart';

/// Employee home: attendance first, followed by enabled employee tools.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> modules = [];

  @override
  void initState() {
    super.initState();
    _init();
    _buildModulesList();
  }

  Future<void> _init() async {
    await appStore.refreshAttendanceStatus();
    await sharedHelper.setAppVersionToPref();
  }

  void _addModule({
    required String category,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    modules.add({
      'category': category,
      'title': title,
      'icon': icon,
      'onTap': onTap,
    });
  }

  void _buildModulesList() {
    modules.clear();

    // Attendance and time tools
    _addModule(
      category: language.lblAttendance,
      title: language.lblAttendanceHistory,
      icon: Iconsax.clock,
      onTap: () => AttendanceHistoryScreen().launch(context),
    );
    _addModule(
      category: language.lblAttendance,
      title: language.lblRegularization,
      icon: Iconsax.edit_2,
      onTap: () => const AttendanceRegularizationListScreen().launch(context),
    );
    _addModule(
      category: language.lblAttendance,
      title: 'Actual Time Report',
      icon: Iconsax.chart_2,
      onTap: () => const ActualTimeReportScreen().launch(context),
    );
    if (moduleService.isFaceAttendanceModuleEnabled()) {
      _addModule(
        category: language.lblAttendance,
        title: language.lblFaceAttendance,
        icon: Iconsax.scanning,
        onTap: () => const FaceRegistrationScreen().launch(context),
      );
    }

    // Pay and benefits
    if (moduleService.isPayrollModuleEnabled()) {
      _addModule(
        category: language.lblBenefits,
        title: language.lblPayroll,
        icon: Iconsax.wallet_2,
        onTap: () => const PayrollDashboardScreen().launch(context),
      );
    }
    if (moduleService.isLoanModuleEnabled()) {
      _addModule(
        category: language.lblBenefits,
        title: language.lblLoanRequests,
        icon: Iconsax.wallet_3,
        onTap: () => const LoanScreen().launch(context),
      );
    }

    // Documents
    if (moduleService.isDocumentModuleEnabled()) {
      _addModule(
        category: language.lblDocuments,
        title: language.lblDocuments,
        icon: Iconsax.folder_2,
        onTap: () => const DocumentManagementHomeScreen().launch(context),
      );
    }

    // Other enabled employee tools
    if (moduleService.isDigitalIdCardModuleEnabled()) {
      _addModule(
        category: language.lblMore,
        title: language.lblDigitalIDCard,
        icon: Iconsax.card,
        onTap: () => const DigitalIDCardScreen().launch(context),
      );
    }
    _addModule(
      category: language.lblMore,
      title: language.lblHolidays,
      icon: Iconsax.sun_1,
      onTap: () => const HolidayScreen().launch(context),
    );
    if (moduleService.isCalendarModuleEnabled()) {
      _addModule(
        category: language.lblMore,
        title: language.lblCalendar,
        icon: Iconsax.calendar_1,
        onTap: () => const CalendarScreen().launch(context),
      );
    }
    if (moduleService.isNoticeModuleEnabled()) {
      _addModule(
        category: language.lblMore,
        title: language.lblNoticeBoard,
        icon: Iconsax.clipboard_text,
        onTap: () => const NoticeBoard().launch(context),
      );
    }
    if (moduleService.isAssetsModuleEnabled()) {
      _addModule(
        category: language.lblMore,
        title: language.lblAssets,
        icon: Iconsax.box,
        onTap: () => const AssetsListScreen().launch(context),
      );
    }
    if (moduleService.isDisciplinaryActionsModuleEnabled()) {
      _addModule(
        category: language.lblMore,
        title: language.lblDisciplinary,
        icon: Iconsax.warning_2,
        onTap: () => const WarningsListScreen().launch(context),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return language.lblGoodMorning;
    if (hour < 17) return language.lblGoodAfternoon;
    if (hour < 21) return language.lblGoodEvening;
    return language.lblGoodNight;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AttendanceComponent(),
                        if (getBoolAsync('isDemoCreds')) ...[
                          const SizedBox(height: 16),
                          const DemoModeBanner(),
                        ],
                        const SizedBox(height: 24),
                        _buildModuleSections(context),
                        const SizedBox(height: 28),
                        FooterSignature(
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ).paddingBottom(20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => const AccountScreen().launch(context),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(child: profileImageWidget(size: 44)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sharedHelper.getFullName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (getStringAsync(designationPref).trim().isNotEmpty)
                  Text(
                    getStringAsync(designationPref),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: language.lblNotification,
            onPressed: () => const NotificationScreen().launch(context),
            icon: Icon(Iconsax.notification, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSections(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      language.lblAttendance,
      language.lblBenefits,
      language.lblDocuments,
      language.lblMore,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories)
          if (modules.any((module) => module['category'] == category)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                category,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 88,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: modules
                  .where((module) => module['category'] == category)
                  .length,
              itemBuilder: (context, index) {
                final items = modules
                    .where((module) => module['category'] == category)
                    .toList();
                final module = items[index];
                return _buildModuleCard(
                  context,
                  title: module['title'] as String,
                  icon: module['icon'] as IconData,
                  onTap: module['onTap'] as VoidCallback,
                );
              },
            ),
            const SizedBox(height: 22),
          ],
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
