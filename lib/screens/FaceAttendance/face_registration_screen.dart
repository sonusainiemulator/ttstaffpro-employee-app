import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_eligibility_model.dart';

import '../../main.dart';
import 'face_attendance_screen.dart';

/// Requirement 2 & 4: staff self-service face registration.
///
/// Shows the current registration status and an "Add your face" button that
/// launches the guided capture flow. On success the profile is linked to the
/// staff member's TTStaffPro login (server-side via employee_id), so their
/// face is available at every kiosk.
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final FaceAttendanceRepository _repo = FaceAttendanceRepository();

  bool _loading = true;
  FaceEligibility? _eligibility;
  OwnFaceProfileStatus? _status;
  String? _error;

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
      final eligibility = await _repo.checkSelfEligibility();
      OwnFaceProfileStatus? status;
      try {
        status = await _repo.getSelfProfileStatus();
      } catch (_) {
        status = null;
      }
      if (!mounted) return;
      setState(() {
        _eligibility = eligibility;
        _status = status;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load face registration status.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Launches the guided multi-angle face capture (V1 self-registration).
  Future<void> _addFace() async {
    final registered = await const FaceAttendanceScreen().launch(context);
    if (registered == true) {
      toast('Face registered successfully');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.lblFaceAttendance),
        backgroundColor: appStore.appColorPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildAddFaceButton(),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = _status?.profileStatus;
    final isRegistered = status != null && status != 'not_registered';
    final isApproved = _status?.approvalStatus == 'approved';

    final Color color;
    final String label;
    if (!isRegistered) {
      color = const Color(0xFFE65100);
      label = 'Not registered';
    } else if (isApproved) {
      color = const Color(0xFF2E7D32);
      label = 'Approved';
    } else if (_status?.approvalStatus == 'rejected') {
      color = const Color(0xFFB3261E);
      label = 'Rejected';
    } else {
      color = const Color(0xFFF9A825);
      label = 'Pending approval';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                isApproved ? Icons.verified_user : Icons.face,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _status?.lastRegisteredAt != null
                        ? 'Registered on ${_status!.lastRegisteredAt}'
                        : 'No face profile linked to your login yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFaceButton() {
    final canRegister = _eligibility?.canRegister ?? false;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: canRegister ? _addFace : null,
        icon: const Icon(Icons.face_retouching_natural),
        label: Text(
          canRegister
              ? 'Add your face'
              : 'Face registration is not available',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: appStore.appColorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: appStore.appColorPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appStore.appColorPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _InfoRow(icon: Icons.camera_alt_outlined, text: 'Look straight into the camera and capture Front, Left and Right angles.'),
            const SizedBox(height: 8),
            const _InfoRow(icon: Icons.admin_panel_settings_outlined, text: 'Your registration is reviewed and approved by the admin.'),
            const SizedBox(height: 8),
            const _InfoRow(icon: Icons.sync_outlined, text: 'Once approved, your face works for check-in / check-out on every kiosk linked to this company.'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
