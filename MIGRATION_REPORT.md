# Independent repository preparation report

Date: 2026-11-02

## Source selection

- Source repository: `mghalaosimi-web/ABDULMALIK-ERP`
- Selected source ref: `maintenance/independent-branding-audit`
- Selected source commit: `7b3489d618b8d0691a1ac266443f8e15dff52683`
- The selected ref contains `abdulmalik/development` and `feature/accessories-module` as ancestors.
- The source `main` branch has one later Windows-CI commit that is not an ancestor of the selected ref. The more complete validation/installer workflow from the selected maintenance ref was reviewed and adapted to the new repository's `main` branch.
- The source repository was not modified by this preparation.

## Changes prepared

- Rewrote the root README and created separate Arabic and English READMEs.
- Added architecture, development, security, roadmap, changelog, contribution and conduct documents.
- Added provenance and license-status records rather than inventing a software license.
- Preserved the accessories module, existing app modules, tests, visual assets, load tests, installer files, Firebase development base, and original project documents.
- Renamed internal Flutter app/server symbols and the paired Android SMS method-channel/action identifiers to the ABDULMALIK namespace. The legacy database filename and cryptographic derivation labels remain unchanged to protect existing data compatibility.
- Updated Windows CI to target `main` rather than historical source branches.
- Changed Android APK CI to manual-only and explicitly experimental; it produces a debug artifact, not a production release.
- Kept legal copyright and third-party attribution notices. Internal legacy identifiers are retained where they protect database, cryptographic, or platform-channel compatibility.

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| Flutter dependency restore | PASS | `flutter pub get` completed with Flutter 3.47.9 / Dart 3.13.7 |
| Static analysis | PASS | `flutter analyze` — no issues found |
| Automated Flutter tests | PASS | `flutter test --reporter expanded` — all 86 tests passed |
| Common secret-pattern scan | PASS, limited | No matching common API/private-key patterns found; this is not a complete secret audit |
| README relative links | PASS | Checked links in the new root documentation |
| Dart formatter check | WARNING | 102 Dart files would be changed by `dart format`; no formatter changes were applied |
| Windows x64 build/installer | NOT RUN | Preparation host is Debian Linux ARM64; Windows/Visual Studio/Inno Setup build environment is unavailable here |
| Android build | NOT RUN | Java/Android SDK are not installed in this host; Android remains experimental and is not declared production-ready |
| Live LAN/device acceptance | NOT RUN | Requires a Windows shop host and real client devices |
| Backup/restore field acceptance | NOT RUN | Requires a disposable Windows test profile and database |

## Security and legal findings

- The checked-in Firebase project file has an empty project mapping; Firebase sync is documented as disabled by default.
- No root `LICENSE`, `NOTICE`, or `COPYING` file was found in the selected source snapshot. No license was invented. Verify written permission and third-party terms before redistribution, sublicensing, or making a public release.
- The upstream README states that permission for a single-shop adaptation was obtained, but the written permission document was not present in the repository snapshot.
- The Windows resource file contains an existing `Copyright (C) 2026 FixTrack` notice. It was not removed or rewritten because a repository rebrand is not proof of a copyright transfer.
- The About screen contains named team biographies and academic/professional credentials. Their accuracy and permission for public display should be verified by the owner before a public commercial release.
- The LAN HTTP transport, cryptographic handling, and backup/restore workflow remain security/acceptance review items. No production security certification is claimed.

## Publication status

The source preparation and local validation are complete. A new GitHub repository has **not** been created or pushed: the connected GitHub actions available in this session can read and write files in existing repositories but do not expose the GitHub `create repository` operation. The intended destination is `mghalaosimi-web/ABDULMALIK-STORE-PRO`, preferably private until redistribution permission and license status are verified. The new independent Git history and source archive can be uploaded once that empty destination repository exists.

The old repository remains unchanged.
