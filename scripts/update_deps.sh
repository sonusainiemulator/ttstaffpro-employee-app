#!/usr/bin/env bash
#
# Daily dependency update helper — TTStaffPro monorepo.
#
# Checks for outdated packages, upgrades them, regenerates generated code and
# runs analyze + tests (root package and the face-attendance kiosk app).
#
# Usage:
#   ./scripts/update_deps.sh            # check + upgrade + verify
#   ./scripts/update_deps.sh --check    # only report outdated packages
#
# After it succeeds, review `git diff` and commit with:
#   git add pubspec.yaml pubspec.lock apps/ttstaffpro_face_attendance/{pubspec.yaml,pubspec.lock} <generated files>
#   git commit -m "chore: update dependencies" && git push origin main

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIOSK="$ROOT/apps/ttstaffpro_face_attendance"
CHECK_ONLY="${1:-}"

# Prefer the Flutter SDK on PATH; fall back to a known location.
FLUTTER="$(command -v flutter || true)"
if [ -z "$FLUTTER" ] && [ -x /Users/sonu/flutter/bin/flutter ]; then
  FLUTTER=/Users/sonu/flutter/bin/flutter
fi
if [ -z "$FLUTTER" ]; then
  echo "error: flutter not found on PATH" >&2
  exit 1
fi
echo "Using: $FLUTTER"

cd "$ROOT"

echo "== 1) Outdated packages (root) =="
"$FLUTTER" pub outdated || true
echo
echo "== 2) Outdated packages (kiosk) =="
(cd "$KIOSK" && "$FLUTTER" pub outdated) || true

if [ "$CHECK_ONLY" = "--check" ]; then
  echo
  echo "Check-only mode: done. No changes were made."
  exit 0
fi

echo
echo "== 3) Upgrade root dependencies =="
"$FLUTTER" pub upgrade

echo
echo "== 4) Upgrade kiosk dependencies =="
(cd "$KIOSK" && "$FLUTTER" pub upgrade)

echo
echo "== 5) Regenerate generated code (root) =="
dart run build_runner build --delete-conflicting-outputs || \
  echo "warning: build_runner failed — check .g.dart regeneration manually"

echo
echo "== 6) Analyze (root) =="
"$FLUTTER" analyze

echo
echo "== 7) Test (root) =="
"$FLUTTER" test

echo
echo "== 8) Test (kiosk) =="
(cd "$KIOSK" && "$FLUTTER" test)

echo
echo "== Done =="
git status --short
echo "Review the diff, then commit:  chore: update dependencies"
