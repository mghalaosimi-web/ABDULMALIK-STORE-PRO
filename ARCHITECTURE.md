# Architecture

## 1. System shape

ABDULMALIK ERP is currently a Windows-first Flutter desktop application with an embedded local service. The shop PC is the host; its SQLite database is the primary operational data store. LAN clients may communicate with the host through the local HTTP API.

```text
Windows shop PC
  Flutter UI
    ├── Riverpod state/providers
    ├── feature modules (repairs, POS, inventory, accessories, customers, reports)
    └── local service host
          ├── shelf / shelf_router HTTP API
          ├── authentication and authorization
          ├── SQLite database + versioned migrations
          └── local files (product images, exports, backups)

Optional future integration (disabled by default)
  Firebase Authentication / Firestore / Hosting
```

## 2. Application layers

- `source/lib/main.dart`: Flutter entry point.
- `source/lib/src/app.dart`: app composition and top-level navigation.
- `source/lib/src/core/`: app configuration, models, locale, formatting, session, API client, cryptographic helpers and shared utilities.
- `source/lib/src/features/`: user-facing feature modules.
- `source/lib/src/server/`: local API, database, routes, discovery, backup and optional cloud synchronization.
- `source/lib/src/widgets/`: shared UI components.

## 3. Persistence

SQLite is the primary local store. Schema changes are versioned and applied by migration code in the server/database layer. Product images and backup archives are stored as local files, with references held in the database. Preserve compatibility identifiers and migration logic: changing legacy database names or key-derivation labels without a verified migration can make existing data unreadable.

## 4. Accessories model

The accessories section is a distinct presentation/filtering domain over the shared products model. The current implementation uses the `products.category` field with an internal `الأكسسوارات::` prefix and server-side section filtering. Accessories remain ordinary saleable products, so the existing POS and stock movement flows are reused. No separate accessories table is required by this implementation.

## 5. Network boundary

The embedded `shelf` service exposes local HTTP endpoints for shop operations. The host should remain on a trusted, access-controlled LAN. Do not port-forward or expose the local API to the public internet. Review authentication, authorization, transport protection, and firewall behavior before deployment.

## 6. Cloud boundary

Firebase/Firestore source and rules are retained for future development. The checked-in Firebase project configuration is empty, and cloud synchronization is disabled by default in the current delivery profile. Do not populate production credentials or enable sync until the owner provisions a separate project and the security rules and privacy requirements are reviewed.

## 7. Platform boundary

Windows x64 is the current supported release target. Android-specific source is present, but its build and device-level acceptance are not evidence of production readiness. The Android workflow is manual and experimental.

## 8. Key invariants

- Existing SQLite records must survive application upgrades.
- Accessories and general inventory must remain correctly separated in their respective views.
- POS sales must continue to use the shared stock and sales logic.
- Backups must be restorable and validated before a production release.
- No secrets, signing keys, or private credentials belong in the repository.
