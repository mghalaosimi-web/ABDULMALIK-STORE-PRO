# Roadmap

This roadmap separates current source capabilities from work that still requires implementation, testing, or operational approval. It is not a promise that every item is already complete.

## Current baseline

- Windows x64 Flutter desktop application.
- Local SQLite persistence and embedded LAN HTTP service.
- Repair, POS, inventory, accessories, phones/IMEI, purchases, customers, services, reports, users/roles, audit, backup and restore modules in source.
- Arabic/English localization foundation.
- Windows installer and CI smoke-test workflow.

## Priority 0 — release safety

- Complete security review of LAN transport, authentication/authorization, cryptographic storage and firewall behavior.
- Run backup/restore acceptance tests on clean and upgraded databases.
- Validate the complete Windows workflow on a clean Windows 10/11 x64 machine.
- Confirm the accuracy and authorization of names, roles, credentials and biographies displayed in the About screen.
- Confirm redistribution rights and third-party license obligations.

## Priority 1 — shop acceptance

- Exercise the full accessories lifecycle: create, edit, archive, search, barcode, stock movement and POS sale.
- Test repair intake, customer approval, parts consumption, warranty and delivery.
- Test purchase receipt, returns, cash drawer close and report reconciliation.
- Test printer configurations and Arabic receipts on supported hardware.

## Priority 2 — Android client

- Establish a supported Android release scope and signing ownership.
- Validate host discovery, authentication, LAN connectivity and reconnect behavior on real devices.
- Define data migration and package identity policy before distributing upgrades.
- Produce and test a signed release APK/AAB only after acceptance criteria pass.

## Priority 3 — cloud and multi-branch

- Provision a separately owned Firebase project.
- Review Firestore rules with emulator tests and privacy requirements.
- Design conflict handling, retries, offline queues and observability.
- Enable branch synchronization only after security and data consistency tests.

## Priority 4 — operational maturity

- Add structured diagnostics and crash reporting with privacy controls.
- Define support, backup retention, upgrade and rollback procedures.
- Automate release notes, checksums and signed Windows distribution.
- Add regression tests for database migrations and high-risk workflows.
