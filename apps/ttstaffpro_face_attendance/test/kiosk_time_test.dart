// Verifies the kiosk time helpers render attendance times in Asia/Kolkata
// regardless of the device's own timezone setting.

import 'package:flutter_test/flutter_test.dart';

import 'package:ttstaffpro_face_attendance/kiosk/kiosk_time.dart';

void main() {
  test('formatKioskTime renders Asia/Kolkata wall-clock time', () {
    // Server stores 2026-08-31 00:51:46 IST and serializes with +05:30 offset.
    // This must render as 12:51 AM in IST — not the UTC shifted value.
    expect(formatKioskTime('2026-08-31T00:51:46+05:30'), '12:51 AM');
    expect(formatKioskTime('2026-08-31T12:40:10+05:30'), '12:40 PM');
  });

  test('formatKioskDateTime renders IST date with correct day', () {
    // 2026-08-31 00:51 IST must NOT appear as 30 Aug (UTC shift).
    expect(
      formatKioskDateTime('2026-08-31T00:51:46+05:30'),
      '31 Aug 2026, 12:51 AM',
    );
    expect(
      formatKioskDateTime('2026-08-31T12:40:10+05:30'),
      '31 Aug 2026, 12:40 PM',
    );
  });

  test('handles null and malformed input with fallbacks', () {
    expect(formatKioskTime(null), '--:--');
    expect(formatKioskTime(''), '--:--');
    expect(formatKioskTime('not-a-date'), '--:--');
    expect(formatKioskDateTime(null), '—');
    expect(formatKioskDateTime('nope'), '—');
  });

  test('tz-only strings (no offset) are treated as Kolkata time', () {
    // Backend sometimes returns plain datetime; Asia/Kolkata is the source of
    // truth so no day shift occurs.
    expect(formatKioskDateTime('2026-08-31T00:51:46'), '31 Aug 2026, 12:51 AM');
  });
}
