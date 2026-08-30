# Face Attendance Kiosk — Core Security Features (Roadmap)

Ranked by value. **#1 is the recommended first implementation.**

## 🏆 Best idea — Liveness / anti-spoofing (blink challenge)

Replace the current single-frame "eyes open" check + hardcoded `livenessStatus: pass` with a real liveness check:

- **Blink challenge**: ask user to blink (eye-open → closed → open across frames) before accepting.
- **Head movement prompt**: e.g. "turn slightly left/right" — ML Kit provides head Euler angles.
- **Multi-frame + time check**: require N consecutive frames with consistent landmarks (defeats printed photos & screens).
- Only then send the real result: `livenessStatus: pass/fail`, `spoofStatus: none/suspected`.

**Impact: High · Effort: Medium**

---

## Prioritized list

| # | Feature | What it does | Impact | Effort |
|---|---------|--------------|--------|--------|
| 1 | **Liveness / blink challenge** | Blocks photo/video spoofing | 🔥 High | Medium |
| 2 | **Snapshot audit trail** | Store every scan's snapshot server-side + show in admin — deterrence & review | High | Low–Med |
| 3 | **Server-side confidence enforcement** | Don't trust client "matched"; server re-validates min confidence score & rejects weak matches | High | Low |
| 4 | **Secure token storage** | Move device token + admin token to `flutter_secure_storage` (EncryptedSharedPreferences) instead of plain SharedPreferences | High | Low |
| 5 | **Per-employee cooldown / anti-passback** | Prevent double check-in/out by same person (e.g. 60s) | Medium | Low |
| 6 | **Device token rotation** | Rotate device token periodically; revoke stolen/old devices server-side | Medium | Medium |
| 7 | **HTTPS cert pinning** | Pin the kiosk to `ttstaffpro.in` cert — blocks MITM on login/events | Medium | Low–Med |
| 8 | **Profile-package integrity** | Sign/checksum the downloaded face profiles so a tampered package can't be loaded | Medium | Low |
| 9 | **Kiosk lockdown mode** | Lock to the app (block status bar / home button), disable USB debugging, single-app mode for wall tablets | Medium | Medium |
| 10 | **Admin session timeout + PIN** | Auto-lock admin session after idle; require PIN to open Register Face / Report / Logout | Medium | Low |

---

**Recommendation:** Start with **#1 (liveness)** — it's the core biometric security feature. Pair it with **#4 (secure storage)** since it's quick and closes a real gap.
