class RecognitionUploadResult {
  final String? eventUuid;
  final String? attendanceAction;
  final int? attendanceId;
  final String? message;

  RecognitionUploadResult({
    this.eventUuid,
    this.attendanceAction,
    this.attendanceId,
    this.message,
  });

  factory RecognitionUploadResult.fromJson(Map<String, dynamic> json) {
    return RecognitionUploadResult(
      eventUuid: json['eventUuid'] as String?,
      attendanceAction: json['attendanceAction'] as String?,
      attendanceId: json['attendanceId'] as int?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'attendanceAction': attendanceAction,
      'attendanceId': attendanceId,
      'message': message,
    };
  }
}

class OfflineSyncEvent {
  final String eventUuid;
  final String eventType;
  final int? employeeId;
  final String recognitionStatus;
  final double? confidenceScore;
  final String occurredAt;

  OfflineSyncEvent({
    required this.eventUuid,
    required this.eventType,
    this.employeeId,
    required this.recognitionStatus,
    this.confidenceScore,
    required this.occurredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'eventType': eventType,
      if (employeeId != null) 'employeeId': employeeId,
      'recognitionStatus': recognitionStatus,
      if (confidenceScore != null) 'confidenceScore': confidenceScore,
      'occurredAt': occurredAt,
    };
  }

  factory OfflineSyncEvent.fromJson(Map<String, dynamic> json) {
    return OfflineSyncEvent(
      eventUuid: json['eventUuid'] as String,
      eventType: json['eventType'] as String,
      employeeId: json['employeeId'] as int?,
      recognitionStatus: json['recognitionStatus'] as String,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      occurredAt: json['occurredAt'] as String,
    );
  }
}

class OfflineSyncBatchRequest {
  final String batchUuid;
  final String sentAt;
  final List<OfflineSyncEvent> events;

  OfflineSyncBatchRequest({
    required this.batchUuid,
    required this.sentAt,
    required this.events,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchUuid': batchUuid,
      'sentAt': sentAt,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

class OfflineSyncResultItem {
  final String? eventUuid;
  final String? status;

  OfflineSyncResultItem({
    this.eventUuid,
    this.status,
  });

  factory OfflineSyncResultItem.fromJson(Map<String, dynamic> json) {
    return OfflineSyncResultItem(
      eventUuid: json['eventUuid'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventUuid': eventUuid,
      'status': status,
    };
  }
}

class OfflineSyncBatchResult {
  final String? batchUuid;
  final int? recordsTotal;
  final int? recordsSuccess;
  final int? recordsFailed;
  final List<OfflineSyncResultItem>? results;

  OfflineSyncBatchResult({
    this.batchUuid,
    this.recordsTotal,
    this.recordsSuccess,
    this.recordsFailed,
    this.results,
  });

  factory OfflineSyncBatchResult.fromJson(Map<String, dynamic> json) {
    return OfflineSyncBatchResult(
      batchUuid: json['batchUuid'] as String?,
      recordsTotal: json['recordsTotal'] as int?,
      recordsSuccess: json['recordsSuccess'] as int?,
      recordsFailed: json['recordsFailed'] as int?,
      results: (json['results'] as List?)
          ?.map((e) => OfflineSyncResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchUuid': batchUuid,
      'recordsTotal': recordsTotal,
      'recordsSuccess': recordsSuccess,
      'recordsFailed': recordsFailed,
      'results': results?.map((e) => e.toJson()).toList(),
    };
  }
}
