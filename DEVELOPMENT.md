# Development and build guide

## Prerequisites

For Windows release builds, use Windows 10/11 x64 with:

- Flutter stable SDK compatible with `source/pubspec.yaml` (`environment.sdk`).
- Visual Studio 2022 Build Tools and the **Desktop development with C++** workload.
- Inno Setup 6.
- Git.

For local analysis/tests on Linux, install Flutter stable and the SQLite development package required by the `sqlite3` Dart package. Windows installer packaging itself must run on Windows.

## Setup

```bash
cd source
flutter doctor -v
flutter pub get
```

## Run on Windows

```powershell
cd source
flutter run -d windows
```

## Quality checks

```bash
cd source
flutter analyze
flutter test --reporter expanded
```

Cloud tests under `test_cloud/` may require explicitly provisioned credentials and a test Firebase project. Do not run them against production data.

## Build Windows installer

```powershell
cd source
powershell -ExecutionPolicy Bypass -File .\tool\build_release.ps1
```

The script is the canonical local release path. It creates a versioned Windows x64 installer under `source/builds/` (confirm the exact path from the script output for the checked-out revision). CI additionally performs a silent install, PE/x64 verification, and silent uninstall smoke test.

## Android (experimental)

Android source is retained but is not a supported production release in the current scope. A manual GitHub Actions workflow can create a debug APK for diagnostics; this is not a signed production APK/AAB. A release Android build requires a verified signing configuration, device testing, data migration planning, and a separate release approval.

## Secrets and local configuration

- Keep `.env`, Firebase credentials, signing keys, `android/key.properties`, keystores and private keys outside Git.
- Use `.env.example` only for non-secret variable names and safe placeholders.
- Never copy production credentials from the previous repository or developer machine.
- Keep private signing material in an owner-controlled secret manager.

## Database changes

- Add a versioned migration for every schema change.
- Test fresh database creation and upgrades from supported prior versions.
- Include preservation tests for existing shop records.
- Test backup and restore using a disposable copy.

## Release checklist

1. `flutter pub get` succeeds.
2. `flutter analyze` succeeds.
3. `flutter test` succeeds.
4. Windows x64 release bundle builds.
5. Installer installs and uninstalls silently.
6. Application launches on a clean Windows profile.
7. Existing database upgrade and backup/restore are tested.
8. LAN access, authentication and firewall behavior are verified.
9. Release notes and SHA-256 checksum are generated.
