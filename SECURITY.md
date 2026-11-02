# Security policy

## Reporting

Do not publish exploitable vulnerabilities, customer data, credentials, or private keys in a public issue. Report security findings privately to the repository owner through an authenticated GitHub communication channel. Include the affected version, reproduction steps, impact, and a proposed mitigation when possible.

## Supported security scope

The current release target is Windows x64. Android and cloud functionality are retained as experimental/future-development components and must not be treated as production-ready.

## Known review requirements

The repository's technical review records the following areas as requiring additional verification before production deployment:

- Local HTTP/LAN transport protection and the trust boundary between the host and LAN clients.
- Cryptographic key derivation, secret storage, and protection of sensitive local data.
- Authentication and authorization across all local API routes.
- Firewall rule scope and network exposure.
- Backup integrity, restore correctness, and recovery after interrupted writes.
- Firebase rules and privacy requirements before any cloud feature is enabled.

These are review requirements, not a claim that a specific exploitable vulnerability has been confirmed in every deployment. Consult `docs/COMPREHENSIVE_PROJECT_STUDY.md`, `docs/PHASE2_QUALITY_REVIEW.md`, and `docs/INDEPENDENT_BRANDING_AUDIT.md` for the source-specific findings and their status.

## Deployment rules

- Do not expose the embedded local HTTP service to the public internet.
- Keep the host on a trusted, access-controlled LAN.
- Do not commit credentials, signing keys, Firebase service credentials, keystores, or `.env` files.
- Use a separately provisioned Firebase project if cloud work is approved.
- Test backup and restore before using live shop data.
- Keep dependencies updated through reviewed, scoped changes rather than unverified blanket upgrades.
