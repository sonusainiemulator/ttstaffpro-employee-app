import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../main.dart';
import '../../utils/app_constants.dart';
import '../../utils/design_system.dart';
import '../../utils/app_widgets.dart';
import '../Account/account_screen.dart';
import '../Notification/notification_screen.dart';
import '../Loan/loan_screen.dart';
import '../Document/DocumentManagement/document_management_home_screen.dart';
import '../AttendanceHistory/attendance_history_screen.dart';
import '../AttendanceHistory/actual_time_report_screen.dart';
import '../AttendanceRegularization/attendance_regularization_list_screen.dart';
import '../DigitalId/digital_id_card_screen.dart';
// TODO: Approval screen needs to be implemented
// import '../Approvals/approval_screen.dart';
import '../Payroll/payroll_dashboard_screen.dart';
import '../Holidays/holiday_screen.dart';
import '../Calendar/calendar_screen.dart';
import '../NoticeBoard/notice_board_screen.dart';
// import '../HRPolicies/hr_policies_screen.dart';
import '../Assets/assets_list_screen.dart';
import '../Disciplinary/warnings_list_screen.dart';
import 'Component/attendance_component.dart';
import 'Component/demo_mode_banner.dart';
import 'Component/insight_widgets.dart';
import 'Component/recent_activity_widget.dart';

/// Modern Home Screen - Employee Dashboard
/// Features gradient header, animated greetings, and enhanced UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _scrollOffset = 0.0;
  List<Map<String, dynamic>> modules = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _init();
    _scrollController.addListener(_onScroll);
    _buildModulesList();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _init() async {
    await appStore.refreshAttendanceStatus();
    await sharedHelper.setAppVersionToPref();
  }

  void _buildModulesList() {
    modules.clear();
    // Loan Module
    if (moduleService.isLoanModuleEnabled()) {
      modules.add({
        'title': language.lblLoanRequests,
        'icon': Iconsax.wallet_3,
        'gradient': const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        'onTap': () => const LoanScreen().launch(context),
      });
    }

    // Documents Module
    if (moduleService.isDocumentModuleEnabled()) {
      modules.add({
        'title': language.lblDocuments,
        'icon': Iconsax.folder_2,
        'gradient': const [Color(0xFFFA8BFF), Color(0xFF2BD2FF)],
        'onTap': () => const DocumentManagementHomeScreen().launch(context),
      });
    }

    // Attendance History
    modules.add({
      'title': language.lblAttendanceHistory,
      'icon': Iconsax.clock,
      'gradient': const [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      'onTap': () => AttendanceHistoryScreen().launch(context),
    });

    // Attendance Regularization
    modules.add({
      'title': language.lblRegularization,
      'icon': Iconsax.edit_2,
      'gradient': const [Color(0xFFFEAC5E), Color(0xFFC779D0)],
      'onTap': () => const AttendanceRegularizationListScreen().launch(context),
    });

    // Actual Time Report
    modules.add({
      'title': 'Actual Time Report',
      'icon': Iconsax.chart_2,
      'gradient': const [Color(0xFF11998E), Color(0xFF38EF7D)],
      'onTap': () => const ActualTimeReportScreen().launch(context),
    });

    // Digital ID Card
    if (moduleService.isDigitalIdCardModuleEnabled()) {
      modules.add({
        'title': language.lblDigitalIDCard,
        'icon': Iconsax.card,
        'gradient': const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        'onTap': () => const DigitalIDCardScreen().launch(context),
      });
    }

    // Approvals - TODO: Implement ApprovalScreen
    // if (moduleService.isApprovalModuleEnabled() && getBoolAsync(approverPref)) {
    //   modules.add({
    //     'title': language.lblApprovals,
    //     'icon': Iconsax.task_square,
    //     'gradient': const [Color(0xFF43E97B), Color(0xFF38F9D7)],
    //     'onTap': () => ApprovalScreen().launch(context, isNewTask: true),
    //   });
    // }

    // Payroll Module
    if (moduleService.isPayrollModuleEnabled()) {
      modules.add({
        'title': language.lblPayroll,
        'icon': Iconsax.wallet_2,
        'gradient': const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        'onTap': () => const PayrollDashboardScreen().launch(context),
      });
    }

    // Holidays
    modules.add({
      'title': language.lblHolidays,
      'icon': Iconsax.sun_1,
      'gradient': const [Color(0xFFFD7B7D), Color(0xFFFDAD4D)],
      'onTap': () => const HolidayScreen().launch(context),
    });

    // Calendar - Paid Addon
    if (moduleService.isCalendarModuleEnabled()) {
      modules.add({
        'title': language.lblCalendar,
        'icon': Iconsax.calendar_1,
        'gradient': const [Color(0xFF667EEA), Color(0xFF764BA2)],
        'onTap': () => const CalendarScreen().launch(context),
      });
    }

    // NoticeBoard - Paid Addon
    if (moduleService.isNoticeModuleEnabled()) {
      modules.add({
        'title': language.lblNoticeBoard,
        'icon': Iconsax.clipboard_text,
        'gradient': const [Color(0xFF43E97B), Color(0xFF38F9D7)],
        'onTap': () => const NoticeBoard().launch(context),
      });
    }

    // HR Policies Module - Hidden for now, later add with coming soon text
    /*
    if (moduleService.isHrPoliciesModuleEnabled()) {
      modules.add({
        'title': language.lblHRPolicies,
        'icon': Iconsax.document_text,
        'gradient': const [Color(0xFF6A11CB), Color(0xFF2575FC)],
        'onTap': () => toast(language.lblComingSoon),
      });
    }
    */

    // Assets Module
    if (moduleService.isAssetsModuleEnabled()) {
      modules.add({
        'title': language.lblAssets,
        'icon': Iconsax.box,
        'gradient': const [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        'onTap': () => const AssetsListScreen().launch(context),
      });
    }

    // Disciplinary Module
    if (moduleService.isDisciplinaryActionsModuleEnabled()) {
      modules.add({
        'title': language.lblDisciplinary,
        'icon': Iconsax.warning_2,
        'gradient': const [Color(0xFFEF4444), Color(0xFFDC2626)],
        'onTap': () => const WarningsListScreen().launch(context),
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return language.lblGoodMorning;
    if (hour < 17) return language.lblGoodAfternoon;
    if (hour < 21) return language.lblGoodEvening;
    return language.lblGoodNight;
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 21) return '🌆';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: appStore.isDarkModeOn ? AppDesignSystem.neutral900 : AppDesignSystem.backgroundColor,
          ),
          child: Stack(
            children: [
              // Background Gradient Ornaments
              if (!appStore.isDarkModeOn)
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppDesignSystem.primaryColor.withOpacity(0.05),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 20, duration: 4000.ms),
                Positioned(
                  top: 200,
                  left: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppDesignSystem.successColor.withOpacity(0.03),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(begin: 0, end: 30, duration: 5000.ms),

              SafeArea(
                child: Column(
                  children: [
                    // Premium Header with Blur
                    _buildPremiumHeader(),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // Greeting Card
                            _buildGreetingCard().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 32),

                            // Insight Widgets
                            const InsightWidgets(),

                            const SizedBox(height: 32),

                            // Attendance Component
                            const AttendanceComponent().animate().fadeIn(delay: 200.ms),

                            // Demo Mode Banner
                            if (getBoolAsync('isDemoCreds')) ...[
                              const SizedBox(height: 16),
                              const DemoModeBanner(),
                            ],

                            const SizedBox(height: 32),

                            // Quick Actions Title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    language.lblQuickActions,
                                    style: boldTextStyle(
                                      size: 20,
                                      color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                                    ),
                                  ),
                                  Text(
                                    "View All",
                                    style: secondaryTextStyle(
                                      color: AppDesignSystem.primaryColor,
                                      weight: FontWeight.w600,
                                    ),
                                  ).onTap(() {}),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Modern Modules Grid
                            _buildModernModulesGrid(),

                            const SizedBox(height: 32),

                            // Recent Activity
                            const RecentActivityWidget(),

                            const SizedBox(height: 48),

                            // Footer
                            FooterSignature(
                              textColor: appStore.isDarkModeOn ? white : AppDesignSystem.neutral400,
                            ).paddingBottom(40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium Header with Blur
  Widget _buildPremiumHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: (appStore.isDarkModeOn ? AppDesignSystem.neutral900 : Colors.white).withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Profile Image with ring
              Hero(
                tag: 'profile',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppDesignSystem.primaryColor, width: 2),
                  ),
                  child: ClipOval(
                    child: profileImageWidget(size: 44),
                  ),
                ),
              ).onTap(() => const AccountScreen().launch(context)),
              16.width,

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sharedHelper.getFullName(),
                      style: boldTextStyle(
                        size: 18,
                        color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.height,
                    Text(
                      getStringAsync(designationPref),
                      style: secondaryTextStyle(
                        size: 13,
                        color: AppDesignSystem.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Notification Icon
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Iconsax.notification,
                      color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                      size: 26,
                    ),
                    onPressed: () => const NotificationScreen().launch(context),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.errorColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium Greeting Card
  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowMedium,
      ),
      child: Row(
        children: [
          // Dynamic Icon with background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppDesignSystem.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGreetingEmoji(),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          20.width,

          // Greeting Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: boldTextStyle(
                    size: 22,
                    color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
                  ),
                ),
                4.height,
                Text(
                  language.lblHaveAProductiveDay,
                  style: secondaryTextStyle(
                    size: 14,
                    color: AppDesignSystem.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modern Modules Grid with Gradients
  Widget _buildModernModulesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AlignedGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return _buildModuleCard(
            title: module['title'],
            icon: module['icon'],
            gradient: module['gradient'],
            onTap: module['onTap'],
            index: index,
          );
        },
      ),
    );
  }

  /// Individual Module Card (Premium Glass Style)
  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int index,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (appStore.isDarkModeOn ? white : AppDesignSystem.neutral200).withOpacity(0.05),
              width: 1,
            ),
            boxShadow: AppDesignSystem.shadowSmall,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with Shadow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: white,
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.15, 1.15))
                 .shimmer(delay: (index * 200).ms, duration: 2000.ms, color: white.withOpacity(0.3)),
              ),
              14.height,

              // Title with premium type
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: boldTextStyle(
                  size: 11,
                  color: appStore.isDarkModeOn ? AppDesignSystem.neutral300 : AppDesignSystem.neutral800,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
