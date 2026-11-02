# ABDULMALIK ERP

**Windows x64 desktop ERP for phone repair and retail shops.**

ABDULMALIK ERP combines repair-ticket management, POS, general inventory, a dedicated accessories section, IMEI-tracked phones, purchases, customers, cash drawer, shop services, reports, users/roles, audit history, and backup/restore.

The Windows PC hosts the local application and SQLite database. A local HTTP service supports shop-LAN clients. Core Windows workflows are offline-first.

## Release scope and limitations

- Windows x64 is the current release target.
- Android source and a manual experimental build workflow remain, but Android is not declared production-ready.
- Firebase/Firestore code is retained as a future development base; configuration is empty and cloud sync/public tracking are disabled by default.
- Activation, subscription, trial, and device-limit features are deferred.
- LAN transport and cryptographic handling need additional security review before use on untrusted networks.

## Build

On Windows 10/11 x64 install Flutter stable, Visual Studio 2022 Build Tools with Desktop development with C++, and Inno Setup 6. Then run:

```powershell
cd source
flutter doctor -v
powershell -ExecutionPolicy Bypass -File .\tool\build_release.ps1
```

The script runs dependency restoration, static analysis, tests, Windows release compilation, and Inno Setup packaging.

## Safety

Test backup/restore before production use, keep the host on a trusted LAN, do not expose the local HTTP service publicly, and never commit credentials or signing keys. Read [SECURITY.md](SECURITY.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PROVENANCE.md](PROVENANCE.md).

Product branding does not replace or erase source-code authorship. No open-source license was found in the inspected upstream snapshot; see [LICENSE_STATUS.md](LICENSE_STATUS.md).
