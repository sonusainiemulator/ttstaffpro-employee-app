import 'package:flutter/material.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_dashboard_model.dart';
import 'package:open_core_hr/models/face_attendance/face_settings_model.dart';

import '../../main.dart';

/// Face Attendance admin console.
///
/// One screen, six tabs — Dashboard / Audit Log / Failed / Spoof / Devices /
/// Settings — all backed by the face-attendance admin API endpoints so admins
/// can monitor kiosk activity and tweak the module settings from the app.
class FaceAttendanceAdminConsoleScreen extends StatefulWidget {
  const FaceAttendanceAdminConsoleScreen({super.key});

  @override
  State<FaceAttendanceAdminConsoleScreen> createState() =>
      _FaceAttendanceAdminConsoleScreenState();
}

class _FaceAttendanceAdminConsoleScreenState
    extends State<FaceAttendanceAdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FaceAttendanceRepository _repo = FaceAttendanceRepository();
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _auditKey = GlobalKey();
  final GlobalKey _failedKey = GlobalKey();
  final GlobalKey _spoofKey = GlobalKey();
  final GlobalKey _devicesKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    final keys = [
      _dashboardKey,
      _auditKey,
      _failedKey,
      _spoofKey,
      _devicesKey,
      _settingsKey,
    ];
    if (_tabController.index < keys.length) {
      _notify(keys[_tabController.index]);
    }
  }

  void _notify(GlobalKey key) {
    final state = key.currentState;
    if (state is _Reloadable) (state as _Reloadable).reload();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face Attendance Admin'),
          backgroundColor: appStore.appColorPrimary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Audit Log'),
              Tab(text: 'Failed'),
              Tab(text: 'Spoof'),
              Tab(text: 'Devices'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _DashboardTab(key: _dashboardKey, repo: _repo),
            _AuditLogTab(key: _auditKey, repo: _repo),
            _FailedTab(key: _failedKey, repo: _repo),
            _SpoofTab(key: _spoofKey, repo: _repo),
            _DevicesTab(key: _devicesKey, repo: _repo),
            _SettingsTab(key: _settingsKey, repo: _repo),
          ],
        ),
      ),
    );
  }
}

/// Common loading / error wrapper for every admin tab.
abstract class _Reloadable {
  void reload();
}

class _AsyncTabBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;

  const _AsyncTabBody({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return child;
  }
}

// ---------------------------------------------------------------------------
// Dashboard tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _DashboardTab({super.key, required this.repo});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> implements _Reloadable {
  FaceDashboardSummary? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repo.getDashboardSummary();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: d == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statCard(Icons.groups, 'Present', d.presentEmployees,
                    const Color(0xFF2E7D32)),
                _statCard(Icons.person_off, 'Absent', d.absentEmployees,
                    const Color(0xFFB3261E)),
                _statCard(Icons.schedule, 'Late', d.lateEmployees,
                    const Color(0xFFF9A825)),
                _statCard(Icons.beach_access, 'On Leave', d.onLeaveEmployees,
                    const Color(0xFF1565C0)),
                _statCard(Icons.badge, 'Workforce', d.currentWorkforce,
                    const Color(0xFF6A1B9A)),
                _statCard(Icons.face_retouching_natural, 'Unknown today',
                    d.unknownFacesToday, const Color(0xFFE65100)),
                _statCard(Icons.security, 'Spoof attempts', d.spoofAttemptsToday,
                    const Color(0xFFB3261E)),
                _statCard(Icons.devices_other, 'Offline devices',
                    d.offlineDevices, const Color(0xFF455A64)),
              ],
            ),
    );
  }

  Widget _statCard(IconData icon, String label, int? value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Text(
          '${value ?? 0}',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audit log tab
// ---------------------------------------------------------------------------

class _AuditLogTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _AuditLogTab({super.key, required this.repo});

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> implements _Reloadable {
  List<RecognitionAuditEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repo.getRecognitionAuditLog(perPage: 50);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load audit log.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: _items.isEmpty
          ? const Center(child: Text('No recognition events yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = _items[i];
                final matched = e.recognitionStatus == 'matched';
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Icon(
                      matched ? Icons.check_circle : Icons.cancel,
                      color:
                          matched ? const Color(0xFF2E7D32) : const Color(0xFFB3261E),
                    ),
                    title: Text(
                      e.employeeName ?? 'Employee ${e.employeeId ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.eventType ?? ''} • ${e.recognitionStatus ?? ''} '
                          '• ${e.confidenceScore?.toStringAsFixed(1) ?? '-'}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (e.occurredAt != null)
                          Text(e.occurredAt!,
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Failed / Spoof / Devices tabs (simple list variants)
// ---------------------------------------------------------------------------

class _FailedTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _FailedTab({super.key, required this.repo});

  @override
  State<_FailedTab> createState() => _FailedTabState();
}

class _FailedTabState extends State<_FailedTab> implements _Reloadable {
  List<FailedRecognitionEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repo.getFailedRecognitions();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load failed recognitions.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: _items.isEmpty
          ? const Center(child: Text('No failed recognitions.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = _items[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.person_search,
                        color: Color(0xFFB3261E)),
                    title: Text(e.failureReason ?? 'unknown'),
                    subtitle: Text(
                      '${e.deviceName ?? e.deviceId ?? '-'}\n${e.occurredAt ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class _SpoofTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _SpoofTab({super.key, required this.repo});

  @override
  State<_SpoofTab> createState() => _SpoofTabState();
}

class _SpoofTabState extends State<_SpoofTab> implements _Reloadable {
  List<SpoofEventEntry> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repo.getSpoofEvents();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load spoof events.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: _items.isEmpty
          ? const Center(child: Text('No spoof attempts.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = _items[i];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading:
                        const Icon(Icons.gpp_bad, color: Color(0xFFB3261E)),
                    title: Text(e.employeeName ?? 'Employee ${e.employeeId ?? '-'}'),
                    subtitle: Text(
                      '${e.deviceName ?? e.deviceId ?? '-'} • ${e.occurredAt ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DevicesTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _DevicesTab({super.key, required this.repo});

  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab> implements _Reloadable {
  List<DeviceHealthStatus> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repo.getDevicesHealthList();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load devices.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: _items.isEmpty
          ? const Center(child: Text('No kiosk devices registered.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = _items[i];
                final online = d.status == 'active';
                final battery = d.batteryLevel;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Icon(
                      online ? Icons.devices : Icons.devices_other,
                      color: online
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB3261E),
                    ),
                    title: Text(d.deviceName ?? d.deviceId ?? '-'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${d.status ?? '-'}'
                            '${battery != null ? ' • Battery: $battery%' : ''}'),
                        if (d.lastHeartbeatAt != null)
                          Text('Last ping: ${d.lastHeartbeatAt}',
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tab
// ---------------------------------------------------------------------------

class _SettingsTab extends StatefulWidget {
  final FaceAttendanceRepository repo;
  const _SettingsTab({super.key, required this.repo});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> implements _Reloadable {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;

  final TextEditingController _defaultThreshold = TextEditingController();
  final TextEditingController _minThreshold = TextEditingController();
  final TextEditingController _maxThreshold = TextEditingController();
  final TextEditingController _retentionDays = TextEditingController();
  bool _requireLiveness = true;
  bool _allowSelfRegistration = true;
  bool _selfRegistrationRequiresApproval = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reload() => _load();

  @override
  void dispose() {
    _defaultThreshold.dispose();
    _minThreshold.dispose();
    _maxThreshold.dispose();
    _retentionDays.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final s = await widget.repo.getSettings();
      if (!mounted) return;
      setState(() {
        _defaultThreshold.text = '${s.defaultThreshold ?? 90}';
        _minThreshold.text = '${s.minThreshold ?? 80}';
        _maxThreshold.text = '${s.maxThreshold ?? 99}';
        _retentionDays.text = '${s.snapshotRetentionDays ?? 30}';
        _requireLiveness = s.requireLiveness ?? true;
        _allowSelfRegistration = s.allowSelfRegistration ?? true;
        _selfRegistrationRequiresApproval =
            s.selfRegistrationRequiresApproval ?? true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load settings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final updated = FaceModuleSettings(
        defaultThreshold: int.tryParse(_defaultThreshold.text.trim()),
        minThreshold: int.tryParse(_minThreshold.text.trim()),
        maxThreshold: int.tryParse(_maxThreshold.text.trim()),
        requireLiveness: _requireLiveness,
        allowSelfRegistration: _allowSelfRegistration,
        selfRegistrationRequiresApproval: _selfRegistrationRequiresApproval,
        snapshotRetentionDays: int.tryParse(_retentionDays.text.trim()),
      );
      final ok = await widget.repo.updateSettings(updated);
      if (!mounted) return;
      setState(() => _message = ok ? 'Settings saved.' : 'Save failed.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Could not save settings.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Default threshold (1-100)', _defaultThreshold),
          _field('Min threshold (1-100)', _minThreshold),
          _field('Max threshold (1-100)', _maxThreshold),
          _field('Snapshot retention (days)', _retentionDays),
          SwitchListTile(
            title: const Text('Require liveness'),
            value: _requireLiveness,
            onChanged: (v) => setState(() => _requireLiveness = v),
          ),
          SwitchListTile(
            title: const Text('Allow self registration'),
            value: _allowSelfRegistration,
            onChanged: (v) => setState(() => _allowSelfRegistration = v),
          ),
          SwitchListTile(
            title: const Text('Self registration requires approval'),
            value: _selfRegistrationRequiresApproval,
            onChanged: (v) =>
                setState(() => _selfRegistrationRequiresApproval = v),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF2E7D32)),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
