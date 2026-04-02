import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/models/Attendance/actual_time_report_model.dart';
import 'package:shimmer/shimmer.dart';

import '../../main.dart';
import '../../utils/design_system.dart';

class ActualTimeReportScreen extends StatefulWidget {
  static String tag = '/ActualTimeReportScreen';
  const ActualTimeReportScreen({super.key});

  @override
  State<ActualTimeReportScreen> createState() => _ActualTimeReportScreenState();
}

class _ActualTimeReportScreenState extends State<ActualTimeReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = false;
  String? errorMessage;
  ActualTimeReportResponse? reportData;

  // Date range filter
  String? startDate;
  String? endDate;
  final _dateRangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDefaultDates();
    _loadReport();
  }

  void _initDefaultDates() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    startDate = _formatDate(firstDay);
    endDate = _formatDate(lastDay);
    _dateRangeController.text = '$startDate - $endDate';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';

  Future<void> _loadReport() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await apiService.getActualTimeReport(
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        reportData = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _showFilterSheet() async {
    DateTimeRange? selectedRange;
    final isDark = appStore.isDarkModeOn;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Filter Report',
                style: boldTextStyle(size: 20),
              ),
              24.height,
              // Date Range
              TextField(
                readOnly: true,
                controller: _dateRangeController,
                decoration: InputDecoration(
                  labelText: 'Select Date Range',
                  prefixIcon: const Icon(Iconsax.calendar),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _dateRangeController.clear();
                      selectedRange = null;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(2021),
                    lastDate: DateTime.now(),
                    helpText: 'Select Report Period',
                  );
                  if (range != null) {
                    selectedRange = range;
                    _dateRangeController.text =
                        '${_formatDate(range.start)} - ${_formatDate(range.end)}';
                  }
                },
              ),
              24.height,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _initDefaultDates();
                        _loadReport();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Reset',
                          style: boldTextStyle(color: Colors.red, size: 15)),
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF696CFF), Color(0xFF5457E6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (selectedRange != null) {
                            startDate = _formatDate(selectedRange!.start);
                            endDate = _formatDate(selectedRange!.end);
                          }
                          _loadReport();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Apply',
                            style: boldTextStyle(color: Colors.white, size: 15)),
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

  @override
  void dispose() {
    _tabController.dispose();
    _dateRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkModeOn;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFF696CFF), const Color(0xFF5457E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Container(
                    color: isDark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF3F4F6),
                    child: isLoading
                        ? _buildShimmer(isDark)
                        : errorMessage != null
                            ? _buildError(isDark)
                            : reportData == null
                                ? _buildEmpty(isDark)
                                : _buildBody(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actual Time Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (startDate != null && endDate != null)
                  Text(
                    '$startDate  →  $endDate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.filter, color: Colors.white),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final data = reportData!;
    return RefreshIndicator(
      onRefresh: _loadReport,
      color: const Color(0xFF696CFF),
      child: CustomScrollView(
        slivers: [
          // Summary Cards
          if (data.summary != null)
            SliverToBoxAdapter(
              child: _buildSummarySection(data.summary!, isDark),
            ),

          // Date filter chip
          if (startDate != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF696CFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.calendar, color: Colors.white, size: 14),
                      6.width,
                      Text(
                        '$startDate  -  $endDate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Daily Records list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Daily Breakdown (${data.totalCount} records)',
                style: boldTextStyle(
                  size: 15,
                  color: isDark ? Colors.white : AppDesignSystem.neutral800,
                ),
              ),
            ),
          ),

          // Daily records
          if (data.values.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty(isDark))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: index == 0 ? 0 : 0,
                      bottom: 12,
                    ),
                    child: _buildDailyCard(data.values[index], isDark),
                  );
                },
                childCount: data.values.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  // ─── Summary Section ────────────────────────────────────────────────────────

  Widget _buildSummarySection(ActualTimeReportSummary s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period Summary',
            style: boldTextStyle(
              size: 16,
              color: isDark ? Colors.white : AppDesignSystem.neutral800,
            ),
          ),
          12.height,

          // Attendance summary row (days)
          Row(
            children: [
              _summaryPill('Present', s.presentDays, Colors.green, isDark),
              8.width,
              _summaryPill('Absent', s.absentDays, Colors.red, isDark),
              8.width,
              _summaryPill('Half Day', s.halfDays, Colors.orange, isDark),
              8.width,
              _summaryPill('Holiday', s.holidayDays, const Color(0xFF696CFF), isDark),
            ],
          ),
          12.height,

          // Hours breakdown
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Actual Working',
                  '${s.totalWorkingHours.toStringAsFixed(1)}h',
                  Iconsax.clock,
                  Colors.green,
                  isDark,
                ),
              ),
              8.width,
              Expanded(
                child: _buildSummaryCard(
                  'Total Breaks',
                  '${s.totalBreakHours.toStringAsFixed(1)}h',
                  Iconsax.coffee,
                  Colors.orange,
                  isDark,
                ),
              ),
              8.width,
              Expanded(
                child: _buildSummaryCard(
                  'Overtime',
                  '${s.totalOvertimeHours.toStringAsFixed(1)}h',
                  Iconsax.timer,
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
          12.height,

          // Late / Early / Compliance row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Late (min)',
                  '${s.totalLateMinutes}m',
                  Iconsax.warning_2,
                  Colors.red,
                  isDark,
                ),
              ),
              8.width,
              Expanded(
                child: _buildSummaryCard(
                  'Early Out',
                  '${s.totalEarlyCheckoutMinutes}m',
                  Iconsax.info_circle,
                  Colors.deepOrange,
                  isDark,
                ),
              ),
              8.width,
              Expanded(
                child: _buildSummaryCard(
                  'Compliance',
                  '${s.avgComplianceScore.toStringAsFixed(0)}%',
                  Iconsax.chart_2,
                  const Color(0xFF696CFF),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            2.height,
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          6.height,
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          2.height,
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Daily Card ─────────────────────────────────────────────────────────────

  Widget _buildDailyCard(ActualTimeReport r, bool isDark) {
    // Determine card accent based on key events
    Color cardAccent = Colors.green;
    if (r.isAbsent) cardAccent = Colors.red;
    else if (r.isHoliday) cardAccent = const Color(0xFF696CFF);
    else if (r.isWeekend) cardAccent = Colors.indigo;
    else if (r.isHalfDay) cardAccent = Colors.orange;
    else if (r.lateMinutes > 0) cardAccent = Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: _dayLeading(r, cardAccent),
          title: _dayTitle(r, isDark),
          subtitle: _daySubtitle(r, isDark),
          children: [_buildDayDetails(r, isDark)],
        ),
      ),
    );
  }

  Widget _dayLeading(ActualTimeReport r, Color accent) {
    IconData icon = Iconsax.logout;
    if (r.isAbsent) icon = Iconsax.close_circle;
    else if (r.isHoliday) icon = Iconsax.calendar_tick;
    else if (r.isWeekend) icon = Iconsax.calendar;
    else if (r.isHalfDay) icon = Iconsax.sun_1;
    else if (r.actualCheckIn != null) icon = Iconsax.login;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.8), accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _dayTitle(ActualTimeReport r, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.date,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              2.height,
              Text(
                r.dayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusChip(r.status, r.statusLabel),
            if (r.overtimeHours > 0) ...[
              4.height,
              _flag('+${r.overtimeHours.toStringAsFixed(1)}h OT', Colors.blue),
            ],
            if (r.lateMinutes > 0) ...[
              4.height,
              _flag('${r.lateMinutes}m late', Colors.red),
            ],
          ],
        ),
      ],
    );
  }

  Widget _daySubtitle(ActualTimeReport r, bool isDark) {
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Iconsax.login, size: 13, color: Colors.green),
          4.width,
          Text(r.actualCheckIn ?? '--',
              style: TextStyle(fontSize: 12, color: subColor)),
          12.width,
          Icon(Iconsax.logout, size: 13, color: Colors.red),
          4.width,
          Text(r.actualCheckOut ?? '--',
              style: TextStyle(fontSize: 12, color: subColor)),
          const Spacer(),
          Icon(Iconsax.clock, size: 13, color: Colors.green),
          4.width,
          Text(
            r.actualWorkingHoursFormatted,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(ActualTimeReport r, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: isDark ? Colors.grey[700] : const Color(0xFFE5E7EB),
          height: 20,
        ),

        // Shift Information
        if (r.shiftName != null) ...[
          _sectionTitle('Shift', isDark),
          8.height,
          _infoRow(Iconsax.buildings, 'Shift Name', r.shiftName!, isDark),
          if (r.shiftStartTime != null)
            _infoRow(Iconsax.timer_1, 'Shift Hours',
                '${r.shiftStartTime} - ${r.shiftEndTime ?? '--'} (${r.shiftExpectedHours}h expected)',
                isDark),
          12.height,
        ],

        // Actual vs Expected time comparison
        _sectionTitle('Time Analysis', isDark),
        8.height,
        Row(
          children: [
            Expanded(
              child: _comparisonCard(
                'Actual Work',
                r.actualWorkingHoursFormatted,
                Colors.green,
                Iconsax.clock,
                isDark,
              ),
            ),
            8.width,
            Expanded(
              child: _comparisonCard(
                'Break Time',
                r.actualBreakHoursFormatted,
                Colors.orange,
                Iconsax.coffee,
                isDark,
              ),
            ),
            if (r.overtimeHours > 0) ...[
              8.width,
              Expanded(
                child: _comparisonCard(
                  'Overtime',
                  '${r.overtimeHours.toStringAsFixed(1)}h',
                  Colors.blue,
                  Iconsax.timer,
                  isDark,
                ),
              ),
            ],
          ],
        ),
        12.height,

        // Compliance score
        _sectionTitle('Compliance Score', isDark),
        8.height,
        _buildComplianceBar(r.complianceScore, isDark),
        12.height,

        // Shift Policy Allowances
        _sectionTitle('Shift Allowances', isDark),
        8.height,
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _allowTag('Late Check-In', r.allowLateCheckIn,
                r.allowedLateMinutes > 0 ? '+${r.allowedLateMinutes}m' : '',
                isDark),
            _allowTag('Early Checkout', r.allowEarlyCheckout,
                r.allowedEarlyCheckoutMinutes > 0
                    ? '-${r.allowedEarlyCheckoutMinutes}m'
                    : '',
                isDark),
            _allowTag(
                'Break Time', r.allowBreakTime,
                r.allowedBreakMinutes > 0 ? '${r.allowedBreakMinutes}m' : '',
                isDark),
            _allowTag('Extra Break', r.allowExtraBreakTime,
                r.allowedExtraBreakMinutes > 0
                    ? '+${r.allowedExtraBreakMinutes}m'
                    : '',
                isDark),
            _allowTag('Half Day Rule', r.halfDayRule, '', isDark),
            _allowTag('Overtime', r.overtimeAllowed, '', isDark),
          ],
        ),
        12.height,

        // Deviations (if any)
        if (r.lateMinutes > 0 ||
            r.earlyCheckoutMinutes > 0 ||
            r.extraBreakMinutes > 0) ...[
          _sectionTitle('Deviations', isDark),
          8.height,
          if (r.lateMinutes > 0)
            _infoRow(
              Iconsax.warning_2,
              'Late By',
              '${r.lateMinutes} min${r.lateReason != null ? "  •  ${r.lateReason}" : ""}',
              isDark,
              valueColor: Colors.red,
            ),
          if (r.earlyCheckoutMinutes > 0)
            _infoRow(
              Iconsax.timer_start,
              'Early Checkout',
              '${r.earlyCheckoutMinutes} min${r.earlyCheckoutReason != null ? "  •  ${r.earlyCheckoutReason}" : ""}',
              isDark,
              valueColor: Colors.deepOrange,
            ),
          if (r.extraBreakMinutes > 0)
            _infoRow(
              Iconsax.coffee,
              'Extra Break',
              '${r.extraBreakMinutes} min',
              isDark,
              valueColor: Colors.orange,
            ),
          12.height,
        ],

        // Overtime task note
        if (r.overtimeTask == true && r.overtimeTaskNote != null) ...[
          _sectionTitle('Overtime Details', isDark),
          8.height,
          _infoRow(Iconsax.task_square, 'Overtime Note',
              r.overtimeTaskNote!, isDark),
          12.height,
        ],
      ],
    );
  }

  Widget _buildComplianceBar(double score, bool isDark) {
    final clipped = score.clamp(0.0, 100.0);
    Color color;
    if (clipped >= 90) color = Colors.green;
    else if (clipped >= 70) color = Colors.amber;
    else color = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${clipped.toStringAsFixed(0)}% compliance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              clipped >= 90
                  ? '✅ Excellent'
                  : clipped >= 70
                      ? '⚠️ Moderate'
                      : '❌ Poor',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
        6.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clipped / 100.0,
            backgroundColor:
                isDark ? Colors.grey[700] : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _comparisonCard(
      String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          4.height,
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          2.height,
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allowTag(String label, bool allowed, String extra, bool isDark) {
    final color = allowed ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 12,
            color: color,
          ),
          4.width,
          Text(
            extra.isNotEmpty ? '$label ($extra)' : label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label) {
    Color color;
    switch (status) {
      case 'checked_in':
        color = Colors.blue;
        break;
      case 'checked_out':
        color = Colors.green;
        break;
      case 'absent':
        color = Colors.red;
        break;
      case 'leave':
        color = Colors.orange;
        break;
      case 'holiday':
        color = const Color(0xFF696CFF);
        break;
      case 'weekend':
        color = Colors.indigo;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _flag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF696CFF),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF696CFF)),
          8.width,
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty / Error / Shimmer ────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.chart_2,
            size: 64,
            color: isDark
                ? Colors.grey[600]
                : const Color(0xFF696CFF).withOpacity(0.5),
          ),
          20.height,
          Text(
            'No Report Data',
            style: boldTextStyle(
              size: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          8.height,
          Text(
            'No attendance records for the selected period.',
            style: secondaryTextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          24.height,
          ElevatedButton.icon(
            onPressed: _showFilterSheet,
            icon: const Icon(Iconsax.filter),
            label: const Text('Change Period'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF696CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 56, color: Colors.red[400]),
          16.height,
          Text('Failed to load report', style: boldTextStyle(size: 16)),
          8.height,
          Text(
            errorMessage ?? 'Unknown error',
            style: secondaryTextStyle(),
            textAlign: TextAlign.center,
          ),
          20.height,
          ElevatedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF696CFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
          highlightColor: isDark ? Colors.grey[700]! : const Color(0xFFF9FAFB),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
