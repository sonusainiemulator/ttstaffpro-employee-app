import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_core_hr/models/face_attendance/kiosk_model.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_time.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';

/// Requirement 6: date-wise staff attendance report with check-in / check-out
/// times and late / early indicators (computed server-side from shift rules).
class KioskReportScreen extends StatefulWidget {
  const KioskReportScreen({super.key});

  @override
  State<KioskReportScreen> createState() => _KioskReportScreenState();
}

class _KioskReportScreenState extends State<KioskReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _error;
  KioskDailyReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final report = await kioskService.getDailyReport(dateStr);
      if (!mounted) return;
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load report. Check connectivity.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _report?.rows ?? [];
    final c = KioskTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance report',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: c.background,
        iconTheme: IconThemeData(color: c.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: KioskColors.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: c.softGlow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY ATTENDANCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Present',
                  value: _report?.presentCount?.toString() ?? '${rows.length}',
                  color: KioskColors.success,
                  icon: Icons.people_alt_rounded,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Late',
                  value: rows.where((r) => r.isLate == true).length.toString(),
                  color: KioskColors.warning,
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Early',
                  value: rows.where((r) => r.isEarly == true).length.toString(),
                  color: KioskColors.primaryLight,
                  icon: Icons.wb_twilight_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: KioskColors.error),
                    ),
                  )
                : rows.isEmpty
                ? Center(
                    child: _EmptyReport(date: _selectedDate),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) => _ReportRowCard(
                      row: rows[index],
                      index: index,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          const KioskVersionFooter(),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  final KioskReportRow row;
  final int index;

  const _ReportRowCard({required this.row, required this.index});

  String _fmt(String? iso) => formatKioskTime(iso);

  String _fmtDateTime(String? iso) => formatKioskDateTime(iso);

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    final primaryDate = row.markedAt ?? row.checkIn ?? row.checkOut ?? '';
    final name = row.employeeName?.trim();
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: KioskColors.primary.withValues(alpha: 0.14),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: KioskColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name?.isNotEmpty == true ? name! : 'Employee ${row.employeeId}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (row.isLate == true || row.isEarly == true)
                  _Badge(
                    text: row.isLate == true ? 'Late' : 'Early',
                    color: row.isLate == true
                        ? KioskColors.warning
                        : KioskColors.primaryLight,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MARKED ${_fmtDateTime(primaryDate)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePill(
                      icon: Icons.login_rounded,
                      label: 'CHECK IN',
                      time: _fmt(row.checkIn),
                      color: KioskColors.success,
                    ),
                  ),
                  Container(width: 1, height: 28, color: c.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _TimePill(
                        icon: Icons.logout_rounded,
                        label: 'CHECK OUT',
                        time: _fmt(row.checkOut),
                        color: KioskColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimePill({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                  letterSpacing: 0.45,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyReport extends StatelessWidget {
  final DateTime date;

  const _EmptyReport({required this.date});

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: KioskColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: KioskColors.primaryLight,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'No attendance yet',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMMM yyyy').format(date),
          style: TextStyle(color: c.textSecondary),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
