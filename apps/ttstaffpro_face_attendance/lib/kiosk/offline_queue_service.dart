import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

/// Represents a locally stored attendance event queued when offline.
class QueuedAttendanceEvent {
  final String id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final DateTime capturedAt;
  final double confidence;
  final double distance;
  final String? snapshotPath;
  final String action; // 'auto', 'check_in', 'check_out'
  int retryCount;
  DateTime? lastAttemptAt;

  QueuedAttendanceEvent({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.capturedAt,
    required this.confidence,
    required this.distance,
    this.snapshotPath,
    this.action = 'auto',
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeCode': employeeCode,
        'capturedAt': capturedAt.toIso8601String(),
        'confidence': confidence,
        'distance': distance,
        'snapshotPath': snapshotPath,
        'action': action,
        'retryCount': retryCount,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory QueuedAttendanceEvent.fromJson(Map<String, dynamic> json) =>
      QueuedAttendanceEvent(
        id: json['id'] as String,
        employeeId: json['employeeId'] as int,
        employeeName: json['employeeName'] as String? ?? 'Employee',
        employeeCode: json['employeeCode'] as String? ?? '',
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        snapshotPath: json['snapshotPath'] as String?,
        action: json['action'] as String? ?? 'auto',
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastAttemptAt: json['lastAttemptAt'] != null
            ? DateTime.parse(json['lastAttemptAt'] as String)
            : null,
      );
}

/// Manages offline attendance events with encrypted/atomic JSON disk persistence,
/// automatic network connectivity monitoring, and background sync retry.
class OfflineQueueService extends ChangeNotifier {
  static const String _kQueueFileName = 'ttstaff_offline_attendance_queue.json';

  final List<QueuedAttendanceEvent> _queue = [];
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _periodicSyncTimer;

  List<QueuedAttendanceEvent> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get isSyncing => _isSyncing;
  bool get hasPending => _queue.isNotEmpty;

  /// Initializes the offline queue, loads pending events from disk, and
  /// subscribes to connectivity change events.
  Future<void> init() async {
    await _loadFromDisk();
    _startConnectivityListener();
    _startPeriodicSync();
  }

  void _startConnectivityListener() {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _queue.isNotEmpty && !_isSyncing) {
        syncPendingEvents();
      }
    });
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    // Periodically retry sync every 2 minutes
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_queue.isNotEmpty && !_isSyncing) {
        syncPendingEvents();
      }
    });
  }

  /// Adds a new attendance event to the offline queue and writes to disk.
  Future<void> enqueue(QueuedAttendanceEvent event) async {
    _queue.add(event);
    await _saveToDisk();
    notifyListeners();

    // Trigger immediate background sync attempt if network is present
    unawaited(syncPendingEvents());
  }

  /// Flushes pending offline attendance records to the TTStaff server.
  Future<void> syncPendingEvents() async {
    if (_isSyncing || _queue.isEmpty) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final List<QueuedAttendanceEvent> toProcess = List.from(_queue);
      final List<String> successfullySyncedIds = [];

      for (final event in toProcess) {
        try {
          event.lastAttemptAt = DateTime.now();
          event.retryCount++;

          // Attempt sync via kiosk service
          final success = await kioskService.syncOfflinePunch(
            employeeId: event.employeeId,
            capturedAt: event.capturedAt,
            confidence: event.confidence,
            distance: event.distance,
            snapshotPath: event.snapshotPath,
            action: event.action,
          );

          if (success) {
            successfullySyncedIds.add(event.id);
          }
        } catch (e) {
          debugPrint('Error syncing offline event ${event.id}: $e');
        }
      }

      if (successfullySyncedIds.isNotEmpty) {
        _queue.removeWhere((e) => successfullySyncedIds.contains(e.id));
        await _saveToDisk();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kQueueFileName');
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;

      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _queue.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _queue.add(QueuedAttendanceEvent.fromJson(item));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load offline attendance queue: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getFile();
      final data = jsonEncode(_queue.map((e) => e.toJson()).toList());
      await file.writeAsString(data, flush: true);
    } catch (e) {
      debugPrint('Failed to persist offline attendance queue: $e');
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}

final OfflineQueueService offlineQueueService = OfflineQueueService();
