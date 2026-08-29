import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_profile_model.dart';

import '../../main.dart';

/// Requirement 3: list of done (approved) and pending face registrations.
///
/// Uses the admin profile API with a status filter and lets an admin approve
/// or reject pending registrations directly.
class FaceRegistrationAdminScreen extends StatefulWidget {
  const FaceRegistrationAdminScreen({super.key});

  @override
  State<FaceRegistrationAdminScreen> createState() =>
      _FaceRegistrationAdminScreenState();
}

class _FaceRegistrationAdminScreenState
    extends State<FaceRegistrationAdminScreen>
    with SingleTickerProviderStateMixin {
  final FaceAttendanceRepository _repo = FaceAttendanceRepository();

  late final TabController _tabController;
  bool _loading = false;
  String? _error;
  final Map<String, List<FaceProfileSummary>> _byStatus = {
    'pending': [],
    'approved': [],
    'rejected': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getAdminProfiles(status: 'pending'),
        _repo.getAdminProfiles(status: 'approved'),
        _repo.getAdminProfiles(status: 'rejected'),
      ]);
      if (!mounted) return;
      setState(() {
        _byStatus['pending'] = results[0];
        _byStatus['approved'] = results[1];
        _byStatus['rejected'] = results[2];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load registrations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(FaceProfileSummary profile) async {
    final confirmed = await _confirm(
      title: 'Approve registration?',
      message:
          'Approve face registration for ${profile.employeeName ?? profile.employeeId}.',
    );
    if (confirmed != true) return;
    try {
      await _repo.approveProfile(profile.id!, remarks: 'Approved from employee app');
      toast('Registration approved');
      _loadAll();
    } catch (e) {
      toast('Approval failed');
    }
  }

  Future<void> _reject(FaceProfileSummary profile) async {
    final remarks = await _promptRemarks();
    if (remarks == null) return;
    try {
      await _repo.rejectProfile(profile.id!, remarks: remarks);
      toast('Registration rejected');
      _loadAll();
    } catch (e) {
      toast('Rejection failed');
    }
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRemarks() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject registration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            hintText: 'Reason for rejection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Registrations'),
        backgroundColor: appStore.appColorPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Pending (${_byStatus['pending']!.length})',
            ),
            Tab(
              text: 'Done (${_byStatus['approved']!.length})',
            ),
            Tab(
              text: 'Rejected (${_byStatus['rejected']!.length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadAll,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList('pending'),
                    _buildList('approved'),
                    _buildList('rejected'),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh',
        onPressed: _loadAll,
        backgroundColor: appStore.appColorPrimary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildList(String status) {
    final items = _byStatus[status] ?? [];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Center(child: Text('No registrations here.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final profile = items[index];
          return _ProfileCard(
            profile: profile,
            isPending: status == 'pending',
            onApprove: status == 'pending' ? () => _approve(profile) : null,
            onReject: status == 'pending' ? () => _reject(profile) : null,
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final FaceProfileSummary profile;
  final bool isPending;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ProfileCard({
    required this.profile,
    required this.isPending,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.employeeName ?? 'Employee ${profile.employeeId}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: appStore.appColorPrimary.withValues(alpha: 0.12),
              child: Text(
                name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                style: TextStyle(
                  color: appStore.appColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID: ${profile.employeeId ?? '-'}  •  ${profile.registrationMode ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (profile.lastSyncedAt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Synced: ${profile.lastSyncedAt}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            if (isPending) ...[
              IconButton(
                tooltip: 'Approve',
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32)),
              ),
              IconButton(
                tooltip: 'Reject',
                onPressed: onReject,
                icon: const Icon(Icons.cancel, color: Color(0xFFB3261E)),
              ),
            ] else
              Chip(
                label: Text(profile.approvalStatus ?? ''),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: profile.approvalStatus == 'approved'
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFB3261E),
                ),
                backgroundColor:
                    (profile.approvalStatus == 'approved'
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFB3261E))
                        .withValues(alpha: 0.1),
              ),
          ],
        ),
      ),
    );
  }
}
