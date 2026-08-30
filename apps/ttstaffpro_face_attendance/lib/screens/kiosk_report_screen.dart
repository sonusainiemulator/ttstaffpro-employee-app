import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_core_hr/models/face_attendance/kiosk_model.dart';

import '../kiosk/kiosk_theme.dart';
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
          'Daily Attendance Report',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        backgroundColor: c.background,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: KioskColors.primaryLight,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat(
                              'dd MMM yyyy (EEEE)',
                            ).format(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          // Summary chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Present',
                  value: _report?.presentCount?.toString() ?? '${rows.length}',
                  color: KioskColors.success,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Late',
                  value: rows.where((r) => r.isLate == true).length.toString(),
                  color: KioskColors.warning,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Early',
                  value: rows.where((r) => r.isEarly == true).length.toString(),
                  color: KioskColors.primaryLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Table
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
                    child: Text(
                      'No attendance for this day.',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _ReportRowCard(row: rows[index]),
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

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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

  const _ReportRowCard({required this.row});

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '--:--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: KioskColors.primary.withValues(alpha: 0.18),
              child: Text(
                (row.employeeName ?? '?').isNotEmpty
                    ? (row.employeeName!.trim().isNotEmpty
                          ? row.employeeName!.trim()[0].toUpperCase()
                          : '?')
                    : '?',
                style: TextStyle(
                  color: KioskColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.employeeName ?? 'Employee ${row.employeeId}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TimePill(
                        icon: Icons.login,
                        label: 'In',
                        time: _fmt(row.checkIn),
                      ),
                      const SizedBox(width: 8),
                      _TimePill(
                        icon: Icons.logout,
                        label: 'Out',
                        time: _fmt(row.checkOut),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (row.isLate == true)
                  _Badge(text: 'Late', color: KioskColors.warning),
                if (row.isEarly == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _Badge(
                      text: 'Early',
                      color: KioskColors.primaryLight,
                    ),
                  ),
              ],
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

  const _TimePill({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label $time',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
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
