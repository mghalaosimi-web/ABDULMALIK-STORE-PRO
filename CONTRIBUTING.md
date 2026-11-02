# Contributing

## Before changing code

1. Read `ARCHITECTURE.md`, `DEVELOPMENT.md`, and `SECURITY.md`.
2. Open an issue or document the scope of a substantial change.
3. Avoid unrelated dependency upgrades and broad refactors.
4. Preserve existing data and compatibility identifiers unless a tested migration is included.

## Change requirements

- Keep UI, API and database responsibilities separated.
- Add or update tests for behavior changes.
- Add versioned database migrations when schema changes are required.
- Keep Arabic and English strings aligned where localization exists.
- Do not add credentials, customer data, private keys or production dumps.
- Preserve third-party copyright, license and attribution notices.

## Validation

From `source/` run:

```bash
flutter pub get
flutter analyze
flutter test --reporter expanded
```

Windows packaging must be tested on a Windows x64 runner using `tool/build_release.ps1`. Describe any checks that could not be run in the pull request.

## Pull requests

Include purpose, scope, screenshots for UI changes, migration impact, tests run, known limitations and rollback considerations. Do not claim tests passed unless they were executed.
