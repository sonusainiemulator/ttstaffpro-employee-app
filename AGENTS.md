# AGENTS.md

Rules for AI coding agents working in this repository. Follow these rules for **every task**.

## Project Context

- **TT Staff Pro** — Flutter HRMS app (`open_core_hr`), Laravel backend at `https://ttstaffpro.in/api/V1/`.
- Single git repo at the root. Sub-apps under `apps/` (e.g. `apps/ttstaffpro_face_attendance`) are tracked in this same repo — **do not** treat them as separate repos.
- Remote: `origin` → `https://github.com/sonusainiemulator/ttstaffpro-employee-app.git`
- Branch: `main`

---

## 🚀 Non-negotiable: Push after every task

After you complete **any** task (feature, fix, refactor, config change, docs, dependency change), you MUST:

1. Run `git status` — review all changes.
2. Stage **only relevant files** (never blindly `git add -A`).
3. Commit with a proper message (see convention below).
4. Push: `git push origin main`.
5. For release work, create and push the annotated tag: `git tag -a vX.Y.Z -m "release: vX.Y.Z - <short summary>" && git push origin vX.Y.Z`.
6. Verify it succeeded — `git status` should show "up to date", `git log origin/main..HEAD` should be empty, and the GitHub Releases page or tag list should show the new release.
7. If the task includes a release or version bump, confirm the new tag/release is visible on GitHub before ending the turn.

**Never end a turn with uncommitted or unpushed work**, unless the user explicitly says not to push.

---

## ✅ Commit message convention (Conventional Commits)

Use the same prefixes as this repo's history:

| Prefix      | Use for                                    |
|-------------|--------------------------------------------|
| `feat:`     | New feature                                |
| `fix:`      | Bug fix                                    |
| `refactor:` | Code change with no behavior change        |
| `chore:`    | Version bumps, build config, dependencies  |
| `ci:`       | CI/CD / GitHub Actions workflow changes    |
| `docs:`     | Documentation                             |
| `test:`     | Tests                                      |
| `release:`  | Release prep / version tag creation        |

Format: `<type>(<optional scope>): <short lowercase summary>`

Examples from this repo:
- `feat: integrate Face Attendance Kiosk API (V1) and update enrollment screen`
- `fix: correct overtime calculation and bump version to 5.0.3+6`
- `chore: bump version to 5.0.4+7 and fix salary structure route`
- `release: v5.0.1 - Payroll & Attendance fixes with build artifacts`

Keep the subject to one clear line. Add a body with bullet points only for large changes. When a change touches a feature or fixes a bug, bump the version (see below) and mention it in the commit.

---

## 🏷️ Version control workflow (proper versioning)

- Version lives in `pubspec.yaml`: `version: X.Y.Z+build` (e.g. `5.0.4+7`).
- Whenever you add a feature or fix a bug, **bump the version** and **update `CHANGELOG.md`** with a matching entry:

  ```markdown
  ## [X.Y.Z] - YYYY-MM-DD

  ### Added / Changed / Fixed / Removed
  - Description of the change.
  ```

- Keep `pubspec.yaml` version, `CHANGELOG.md`, and the commit message **in sync** — all in the same commit.
- **Releases:** after the version is bumped and pushed, create an annotated tag and push it:
  ```bash
  git tag -a vX.Y.Z -m "release: vX.Y.Z - <short summary>"
  git push origin vX.Y.Z
  ```
  Tags are used for GitHub Releases (see history: `v5.0.1`).

---

## 🚫 Never do

- **Never** push with `--force`. Use `--force-with-lease` only if truly necessary and only after user approval.
- **Never** commit secrets: tokens, API keys, `.env`, SSH keys/credentials, auth logs (`git_push_log.txt` is an auth-failure log — do not commit new secrets to it).
- **Never** commit build artifacts or local files: `build/`, `.dart_tool/`, `.pub-cache/`, `.idea/`, `.DS_Store`, `*.log`, root-level `*.apk` / `*.aab` binaries, `local.properties`.
- **Never** commit broken or WIP code. Before committing Dart changes:
  - Run `dart run build_runner build --delete-conflicting-outputs` after touching any MobX store (`*.g.dart` regeneration), otherwise the app won't compile.
  - Run `flutter analyze` and fix any new errors in the changed files.
- **Never** mix unrelated changes in one commit — split logically (feature vs. docs vs. version bump).
- **Never** commit real Firebase config `ios/Runner/GoogleService-Info.plist` (gitignored intentionally).

---

## 🔧 Common commands

```bash
git status                                  # review changes before committing
dart run build_runner build --delete-conflicting-outputs   # after MobX store edits
flutter analyze                             # lint check before committing
git add <relevant files>
git commit -m "<type>: <summary>"
git push origin main
git tag -a vX.Y.Z -m "release: vX.Y.Z - <summary>" && git push origin vX.Y.Z
```

---

## 🔁 Repeat after every task

> ✅ Task done → `flutter analyze` clean → version/CHANGELOG updated (if feature/fix) → stage relevant files → commit → **push to GitHub** → for release work, create/push tag and confirm GitHub Releases page shows it → confirm repo is up to date.
