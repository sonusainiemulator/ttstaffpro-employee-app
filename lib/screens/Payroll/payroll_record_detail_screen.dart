import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../main.dart';
import '../../models/payroll_record_model.dart';

/// Payroll Record Detail Screen
///
/// Displays complete breakdown of a payslip (PayslipDetailModel) using the
/// new /payroll/payslip/{id} API structure.
class PayrollRecordDetailScreen extends StatefulWidget {
  final int recordId;

  const PayrollRecordDetailScreen({
    super.key,
    required this.recordId,
  });

  @override
  State<PayrollRecordDetailScreen> createState() =>
      _PayrollRecordDetailScreenState();
}

class _PayrollRecordDetailScreenState
    extends State<PayrollRecordDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadRecordDetails();
  }

  Future<void> _loadRecordDetails() async {
    await payrollStore.fetchPayrollRecordById(widget.recordId);
  }

  String _fmt(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? const Color(0xFF111827)
          : const Color(0xFFF3F4F6),
      body: Observer(
        builder: (_) {
          if (payrollStore.isLoading &&
              payrollStore.selectedPayrollRecord == null) {
            return _buildLoadingState();
          }

          if (payrollStore.error != null &&
              payrollStore.selectedPayrollRecord == null) {
            return _buildErrorState();
          }

          final record = payrollStore.selectedPayrollRecord;
          if (record == null) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadRecordDetails,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(record),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSalarySummaryCard(record),
                        const SizedBox(height: 16),
                        if (record.attendance != null)
                          _buildAttendanceCard(record.attendance!),
                        if (record.attendance != null)
                          const SizedBox(height: 16),
                        _buildEarningsCard(record),
                        const SizedBox(height: 16),
                        _buildDeductionsCard(record),
                        if (record.payPeriod != null) ...[
                          const SizedBox(height: 16),
                          _buildPeriodCard(record),
                        ],
                        if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildNotesCard(record.notes!),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(PayslipDetailModel record) {
    Color statusColor = _statusColor(record.status);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF696CFF),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Text(
          record.month,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF696CFF), Color(0xFF5457E6)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.lblNetSalary,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(record.netSalary),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.statusLabel ?? record.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Salary Summary ────────────────────────────────────────────────────────

  Widget _buildSalarySummaryCard(PayslipDetailModel record) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Iconsax.wallet_money, const Color(0xFF696CFF),
              language.lblSalaryBreakdown),
          const SizedBox(height: 16),
          _salaryRow(language.lblBasicSalary, _fmt(record.basicSalary)),
          const SizedBox(height: 12),
          _salaryRow(language.lblGrossSalary, _fmt(record.grossSalary)),
          const SizedBox(height: 12),
          _salaryRow(language.lblTotalDeductions, _fmt(record.totalDeductions),
              isNegative: true),
          const SizedBox(height: 12),
          Divider(
            color: appStore.isDarkModeOn
                ? Colors.grey[700]
                : const Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 12),
          _salaryRow(language.lblNetSalary, _fmt(record.netSalary),
              isHighlighted: true, isLarge: true),
          if (record.paymentDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.calendar_tick, size: 16, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Paid on ${record.paymentDate}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _salaryRow(
    String label,
    String amount, {
    bool isHighlighted = false,
    bool isNegative = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            color: appStore.isDarkModeOn
                ? (isHighlighted ? Colors.white : Colors.grey[400])
                : (isHighlighted
                    ? const Color(0xFF111827)
                    : const Color(0xFF6B7280)),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isNegative
                ? Colors.red
                : (isHighlighted
                    ? const Color(0xFF4CAF50)
                    : (appStore.isDarkModeOn
                        ? Colors.white
                        : const Color(0xFF111827))),
          ),
        ),
      ],
    );
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  Widget _buildAttendanceCard(PayslipAttendance att) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
              Iconsax.calendar, const Color(0xFF696CFF), language.lblAttendanceSummary),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _attStat(Iconsax.tick_circle, Colors.green,
                    att.effectiveDays.toStringAsFixed(1), language.lblWorkedDays),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attStat(Iconsax.close_circle, Colors.red,
                    '${att.absentDays}', language.lblAbsentDays),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _attStat(Iconsax.note_remove, Colors.orange,
                    '${att.leaveDays}', language.lblLeaveDays),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attStat(Iconsax.clock, Colors.blue,
                    att.overtimeHours.toStringAsFixed(1), language.lblOvertimeHours),
              ),
            ],
          ),
          if (att.halfDays > 0 || att.lateDays > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (att.halfDays > 0)
                  Expanded(
                    child: _attStat(Iconsax.sun_1, Colors.amber,
                        '${att.halfDays}', 'Half Days'),
                  ),
                if (att.halfDays > 0 && att.lateDays > 0)
                  const SizedBox(width: 12),
                if (att.lateDays > 0)
                  Expanded(
                    child: _attStat(Iconsax.timer_pause, Colors.deepOrange,
                        '${att.lateDays}', 'Late Days'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _attStat(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn
            ? const Color(0xFF374151)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: appStore.isDarkModeOn
                  ? Colors.white
                  : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: appStore.isDarkModeOn
                  ? Colors.grey[400]
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ── Earnings ──────────────────────────────────────────────────────────────

  Widget _buildEarningsCard(PayslipDetailModel record) {
    final items = record.nonZeroEarnings;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconBox(Iconsax.add_circle, Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    language.lblEarnings,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appStore.isDarkModeOn
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Text(
                _fmt(record.totalEarnings),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _emptyLine(language.lblNoEarningsRecorded)
          else
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _lineItem(e.name, _fmt(e.amount), Colors.green),
                )),
        ],
      ),
    );
  }

  // ── Deductions ────────────────────────────────────────────────────────────

  Widget _buildDeductionsCard(PayslipDetailModel record) {
    final items = record.nonZeroDeductions;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconBox(Iconsax.minus_cirlce, Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    language.lblDeductions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appStore.isDarkModeOn
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Text(
                _fmt(record.totalDeductions),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _emptyLine(language.lblNoDeductionsRecorded)
          else
            ...items.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _lineItem(d.name, _fmt(d.amount), Colors.red),
                )),
        ],
      ),
    );
  }

  // ── Pay Period ────────────────────────────────────────────────────────────

  Widget _buildPeriodCard(PayslipDetailModel record) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Iconsax.calendar_1, const Color(0xFF696CFF),
              language.lblPayrollCycle),
          const SizedBox(height: 16),
          if (record.payPeriod != null)
            _infoRow('Period', record.payPeriod!),
          if (record.paymentMethod != null) ...[
            const SizedBox(height: 10),
            _infoRow('Payment Method', record.paymentMethod!),
          ],
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotesCard(String notes) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Iconsax.note_text, Colors.amber, 'Notes'),
          const SizedBox(height: 12),
          Text(
            notes,
            style: TextStyle(
              fontSize: 14,
              color: appStore.isDarkModeOn
                  ? Colors.grey[300]
                  : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ── Common helpers ────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(appStore.isDarkModeOn ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _cardHeader(IconData icon, Color color, String title) {
    return Row(
      children: [
        _iconBox(icon, color),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                appStore.isDarkModeOn ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _lineItem(String name, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn
            ? const Color(0xFF374151)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: appStore.isDarkModeOn
                    ? Colors.white
                    : const Color(0xFF111827),
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLine(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 14,
            color: appStore.isDarkModeOn
                ? Colors.grey[400]
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: appStore.isDarkModeOn
                ? Colors.grey[400]
                : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: appStore.isDarkModeOn
                ? Colors.white
                : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'partially_paid':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  // ── Loading / Error / Empty ───────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: appStore.isDarkModeOn ? Colors.grey[800]! : const Color(0xFFE5E7EB),
      highlightColor: appStore.isDarkModeOn ? Colors.grey[700]! : const Color(0xFFF9FAFB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              payrollStore.error ?? language.lblSomethingWentWrong,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: appStore.isDarkModeOn
                    ? Colors.grey[400]
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecordDetails,
              icon: const Icon(Iconsax.refresh),
              label: Text(language.lblRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF696CFF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No payslip found.'));
  }
}
