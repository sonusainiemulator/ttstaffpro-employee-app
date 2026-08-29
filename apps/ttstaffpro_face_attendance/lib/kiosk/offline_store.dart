import 'package:hive/hive.dart';

/// A single face-recognition attendance event queued for upload.
///
/// Stored in the Hive box `kiosk_pending_events` as a map so no codegen is
/// required in this standalone app.
class PendingFaceEvent {
  final String eventUuid;
  final String eventType; // check_in / check_out / unknown
  final int? employeeId;
  final String recognitionStatus; // matched / unknown
  final double? confidenceScore;
  final String occurredAt;
  final String? snapshotPath;

  PendingFaceEvent({
    required this.eventUuid,
    required this.eventType,
    this.employeeId,
    required this.recognitionStatus,
    this.confidenceScore,
    required this.occurredAt,
    this.snapshotPath,
  });

  Map<String, dynamic> toMap() => {
        'eventUuid': eventUuid,
        'eventType': eventType,
        'employeeId': employeeId,
        'recognitionStatus': recognitionStatus,
        'confidenceScore': confidenceScore,
        'occurredAt': occurredAt,
        'snapshotPath': snapshotPath,
      };

  factory PendingFaceEvent.fromMap(Map<dynamic, dynamic> map) {
    return PendingFaceEvent(
      eventUuid: map['eventUuid'] as String,
      eventType: map['eventType'] as String,
      employeeId: map['employeeId'] as int?,
      recognitionStatus: (map['recognitionStatus'] as String?) ?? 'unknown',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble(),
      occurredAt: (map['occurredAt'] as String?) ?? '',
      snapshotPath: map['snapshotPath'] as String?,
    );
  }
}

/// Offline-first queue for kiosk recognition events.
///
/// Events are appended locally on every scan and flushed to the server
/// (`POST face-attendance/device/sync-batch`) when connectivity returns.
class OfflineStore {
  static const String _boxName = 'kiosk_pending_events';
  late final Box<Map> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  int get pendingCount => _box.length;

  Future<void> enqueue(PendingFaceEvent event) async {
    await _box.put(event.eventUuid, event.toMap());
  }

  List<PendingFaceEvent> allPending() {
    return _box.values
        .map((e) => PendingFaceEvent.fromMap(e))
        .where((e) => e.eventUuid.isNotEmpty)
        .toList();
  }

  Future<void> remove(String eventUuid) async {
    await _box.delete(eventUuid);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
