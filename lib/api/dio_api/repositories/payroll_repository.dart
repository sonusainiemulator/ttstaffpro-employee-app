import 'package:dio/dio.dart';
import 'package:open_core_hr/api/api_routes.dart';
import '../base_repository.dart';
import '../../../models/payslip_model.dart';
import '../../../models/payroll_record_model.dart';

/// Repository for payroll and payslip related API calls.
///
/// Endpoint reference:
///   GET /api/V1/payroll                    → payroll list (mobile-optimised, skip/take)
///   GET /api/V1/payroll/payslip/{id}       → payslip detail
///   GET /api/V1/payroll/salary-structure   → active salary structure
///   GET /api/V1/payroll/modifiers          → salary modifiers
///   GET /api/V1/payroll/statistics         → payroll statistics
class PayrollRepository extends BaseRepository {
  // ── Payroll List ──────────────────────────────────────────────────────────

  /// Fetch paginated payroll list from GET /payroll.
  ///
  /// Always use this endpoint for the list screen (fields are properly typed).
  ///
  /// Returns a [PayrollListResponse] with `total`, `skip`, `take`, `items`.
  Future<PayrollListResponse> getMyPayrollRecords({
    int skip = 0,
    int take = 15,
    String? status,
    String? period, // optional, sent as month_year filter if provided
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'take': take,
    };
    if (status != null) params['status'] = status;
    if (period != null) params['month_year'] = period;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    return await safeApiCall(
      () => dioClient.get(APIRoutes.payrollList, queryParameters: params),
      parser: (data) {
        // Response envelope: { total, skip, take, items: [...] }
        final envelope = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        return PayrollListResponse.fromJson(envelope);
      },
    );
  }

  // ── Payslip Detail ────────────────────────────────────────────────────────

  /// Get full payslip detail from GET /payroll/payslip/{id}.
  Future<PayslipDetailModel?> getPayrollRecordDetails(int id) async {
    return await safeApiCall(
      () => dioClient.get('${APIRoutes.payrollDetail}/$id'),
      parser: (data) {
        final body = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        return PayslipDetailModel.fromJson(body);
      },
    );
  }

  // ── Salary Structure ──────────────────────────────────────────────────────

  /// Get employee's active salary structure from GET /payroll/salary-structure.
  Future<SalaryStructureModel?> getMySalaryStructure() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.salaryStructure),
      parser: (data) {
        final body = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        return SalaryStructureModel.fromJson(body);
      },
    );
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getMyPayrollStatistics({int? year}) async {
    return await safeApiCall(
      () => dioClient.get(
        APIRoutes.getMyPayrollStatistics,
        queryParameters: year != null ? {'year': year, 'months': 12} : {'months': 12}, // Default to 12 months for trend
      ),
      parser: (data) => data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>? ?? {},
    );
  }

  // ── Payslips (legacy wrapper — uses PayslipModel for existing payslip list screen) ──

  /// Get paginated list of payslips.
  ///
  /// This wraps [getMyPayrollRecords] and converts the items to [PayslipModel]
  /// so existing payslip-list screens continue to work without change.
  Future<Map<String, dynamic>> getMyPayslips({
    int skip = 0,
    int take = 20,
    int? year,
    int? month,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'take': take,
    };
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;
    if (status != null) params['status'] = status;
    if (year != null && month != null) {
      final m = month.toString().padLeft(2, '0');
      params['month_year'] = '$year-$m';
    }

    return await safeApiCall(
      () => dioClient.get(APIRoutes.payrollList, queryParameters: params),
      parser: (data) {
        final envelope = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        final items = (envelope['items'] as List<dynamic>? ?? [])
            .map((e) => _payrollItemToPayslipModel(e as Map<String, dynamic>))
            .toList();
        return {
          'totalCount': envelope['total'] ?? items.length,
          'values': items,
        };
      },
    );
  }

  /// Get single payslip by ID — wraps [getPayrollRecordDetails] and returns [PayslipModel].
  Future<PayslipModel?> getPayslipDetails(int id) async {
    final detail = await getPayrollRecordDetails(id);
    if (detail == null) return null;
    return _payslipDetailToLegacyModel(detail);
  }

  /// Download payslip as PDF file.
  Future<Response> downloadPayslip(
    int id,
    String savePath, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return await dioClient.downloadFile(
      '${APIRoutes.downloadPayslipPdf}/$id',
      savePath,
      onReceiveProgress: onProgress != null
          ? (received, total) {
              if (total != -1) onProgress(received / total);
            }
          : null,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  /// Returns the download URL for a payslip PDF.
  String getPayslipDownloadUrl(int id) {
    final base = dioClient.dio.options.baseUrl;
    return '$base${APIRoutes.downloadPayslipPdf}/$id';
  }

  // ── Salary Modifiers ──────────────────────────────────────────────────────

  Future<List<dynamic>> getMyAdjustments() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.getMyAdjustments),
      parser: (data) {
        final envelope = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        // Section 6.1: items list should contain the modifiers
        return envelope['items'] as List<dynamic>? ?? (data['data'] is List ? data['data'] as List : []);
      },
    );
  }

  // ── Wrapper methods for store compatibility ────────────────────────────────

  Future<Map<String, dynamic>> getPayslips({
    int skip = 0,
    int take = 20,
    int? year,
    String? status,
  }) =>
      getMyPayslips(skip: skip, take: take, year: year, status: status);

  Future<PayslipModel?> getPayslipById(int id) => getPayslipDetails(id);

  Future<SalaryStructureModel?> getSalaryStructure() => getMySalaryStructure();

  Future<Map<String, dynamic>?> getPayrollStatistics({int? year}) =>
      getMyPayrollStatistics(year: year);

  Future<String?> downloadPayslipPdf(int id) async {
    throw UnimplementedError('downloadPayslipPdf: provide a save path first.');
  }

  // Convenience helpers

  Future<Map<String, dynamic>> getPayslipsForMonth(
      {required int year, required int month}) =>
      getMyPayslips(year: year, month: month, take: 10);

  Future<Map<String, dynamic>> getCurrentYearPayslips() =>
      getMyPayslips(year: DateTime.now().year, take: 12);

  Future<Map<String, dynamic>> getCurrentMonthPayslip() {
    final now = DateTime.now();
    return getMyPayslips(year: now.year, month: now.month, take: 1);
  }

  Future<Map<String, dynamic>> getPayrollRecordsForMonth(
      {required int year, required int month}) {
    return getMyPayslips(
      year: year,
      month: month,
      take: 10,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Convert a /payroll `items` entry into the legacy [PayslipModel].
  PayslipModel _payrollItemToPayslipModel(Map<String, dynamic> json) {
    return PayslipModel(
      id: json['id'] as int?,
      code: json['monthYear'] as String?,
      basicSalary: _num(json['basicSalary']),
      netSalary: _num(json['netSalary']),
      totalDeductions: null,
      totalBenefits: null,
      totalWorkedDays: null,
      totalAbsentDays: null,
      totalLeaveDays: null,
      totalLateDays: null,
      totalEarlyCheckoutDays: null,
      totalOvertimeDays: null,
      totalHolidays: null,
      totalWeekends: null,
      totalWorkingDays: null,
      payrollModifiers: [],
      status: json['status'] as String?,
      payrollPeriod: json['month'] as String?,
      createdAt: json['paymentDate'] as String?,
    );
  }

  /// Convert [PayslipDetailModel] into the legacy [PayslipModel].
  PayslipModel _payslipDetailToLegacyModel(PayslipDetailModel d) {
    return PayslipModel(
      id: d.id,
      code: d.month,
      basicSalary: d.basicSalary,
      netSalary: d.netSalary,
      totalDeductions: d.totalDeductions,
      totalBenefits: d.totalEarnings,
      totalWorkedDays: d.attendance?.effectiveDays,
      totalAbsentDays: d.attendance?.absentDays.toDouble(),
      totalLeaveDays: d.attendance?.leaveDays.toDouble(),
      totalLateDays: d.attendance?.lateDays.toDouble(),
      totalEarlyCheckoutDays: null,
      totalOvertimeDays: null,
      totalHolidays: null,
      totalWeekends: null,
      totalWorkingDays: d.attendance?.totalWorkingDays.toDouble(),
      payrollModifiers: [],
      status: d.status,
      payrollPeriod: d.month,
      createdAt: d.paymentDate,
    );
  }

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }
}
