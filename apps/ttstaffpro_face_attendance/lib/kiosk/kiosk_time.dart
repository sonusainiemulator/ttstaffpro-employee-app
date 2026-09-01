import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Kiosk time helpers.
///
/// The backend stores attendance times in the company timezone
/// (`Asia/Kolkata`) and serializes them as ISO-8601 with a `+05:30` offset.
/// `DateTime.parse` converts those to a UTC instant, and formatting that
/// instant with the device's own timezone shows the wrong wall-clock time when
/// the tablet is not set to IST. All kiosk screens therefore format through
/// these helpers, which always render in `Asia/Kolkata` regardless of the
/// device clock.

/// Company / server timezone used for all attendance display.
const String kKioskTimezone = 'Asia/Kolkata';

tz.Location? _kolkata;
bool _initialized = false;

/// Idempotent init of the tz database + Kolkata location. Safe to call from
/// any screen before formatting times.
void ensureKioskTimezone() {
  if (_initialized) return;
  tzdata.initializeTimeZones();
  _kolkata = tz.getLocation(kKioskTimezone);
  _initialized = true;
}

/// Parses an ISO-8601 string and returns the wall-clock DateTime as seen in
/// the company timezone (Asia/Kolkata). Null when unparseable.
///
/// Strings with an explicit offset (e.g. `+05:30`/`Z`) are converted from
/// their real instant into Kolkata time. Offset-less strings are treated as
/// ALREADY being Kolkata wall-clock time (the backend's convention) — they
/// must NOT go through `DateTime.parse`'s "naive = local device time"
/// behaviour, or the result depends on the device/CI host's own timezone.
final RegExp _isoOffsetPattern = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime? kioskDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final trimmed = iso.trim();
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  ensureKioskTimezone();
  if (_isoOffsetPattern.hasMatch(trimmed)) {
    return tz.TZDateTime.from(parsed, _kolkata!);
  }
  // No offset: reuse the literal y/m/d/h/m/s components as Kolkata time.
  return tz.TZDateTime(
    _kolkata!,
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

/// Formats an ISO-8601 attendance time as `hh:mm a` in Asia/Kolkata.
String formatKioskTime(String? iso, {String fallback = '--:--'}) {
  final dt = kioskDateTime(iso);
  if (dt == null) return fallback;
  return DateFormat('hh:mm a').format(dt);
}

/// Formats an ISO-8601 attendance time as `dd MMM yyyy, hh:mm a` in
/// Asia/Kolkata.
String formatKioskDateTime(String? iso, {String fallback = '—'}) {
  final dt = kioskDateTime(iso);
  if (dt == null) return fallback;
  return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
}
