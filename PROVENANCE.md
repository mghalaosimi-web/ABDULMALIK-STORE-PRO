# Source provenance and attribution

## Imported source

- Upstream repository: https://github.com/mghalaosimi-web/ABDULMALIK-ERP
- Imported ref: `maintenance/independent-branding-audit`
- Imported commit: `7b3489d618b8d0691a1ac266443f8e15dff52683`
- Snapshot date recorded by Git: 2026-11-02

The selected ref contains the accessories-module work and the subsequent maintenance, localization, project-profile, quality-review and security-documentation changes. It also contains the `abdulmalik/development` and `feature/accessories-module` lines of work. The default `main` branch had one later Windows CI commit not present in this ref; the selected maintenance workflow was reviewed as the more complete CI definition and is being adapted for the new repository's `main` branch.

## Authorship and product branding

A new repository identity or a new initial Git commit does not transfer authorship of existing source code. The upstream Git history recorded the following commit identities in the inspected snapshot:

- MHAMMED AL-AOSIMI — 236 commits
- Ahshika — 6 commits
- Higordtona — 2 commits

These are Git commit counts, not a legal determination of copyright ownership or the percentage of copyright held by any contributor. Preserve any applicable written assignments, permissions, agreements, copyright notices and third-party license files alongside project records.

The product name, icon, marketing copy and current maintainer profile may be updated independently of source-code authorship. The old internal Flutter app/server class names and paired Android SMS channel/action identifiers were renamed to the ABDULMALIK namespace. The legacy `fixtrack.db` filename and `fixtrack-enc` / `fixtrack-mac` derivation labels remain unchanged because existing customer data may depend on them. The Windows resource still contains the original `Copyright (C) 2026 FixTrack` notice; it is retained unless a valid rights transfer or written authorization explicitly permits its replacement. Do not remove or falsify legal attribution, upstream provenance, or third-party notices.

## Permission and redistribution

The upstream project documentation states that permission for a single-shop adaptation was obtained, but the written instrument was not included in the inspected source snapshot. Keep the actual written permission in the owner's private project records and verify that it covers the intended new repository visibility, redistribution, modification and commercial use. This file is not itself a license or proof of a rights transfer.

## Third-party components

The application depends on Flutter/Dart packages and platform tooling. Their license obligations remain applicable. Generate and review the dependency license inventory from the exact release build environment, and include required notices in distributed packages.
