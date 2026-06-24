# Documentation Index — OASIS

This folder contains the canonical documentation used to operate, maintain, and develop OASIS in production. All files in this directory are considered authoritative and must remain production-grade: no placeholders, no TODOs, no sample or mock instructions. Any change to these files must meet the requirements in docs/process below.

Important files in this directory

- INDEX.md — Documentation index and navigation (source of truth for end-user documentation). See ./INDEX.md
- CHANGELOG.md — Release and version history. See ./CHANGELOG.md
- ENTERPRISE-SPEC.md — Enterprise production specification. See ./ENTERPRISE-SPEC.md
- enterprise-production-spec.md — Complementary enterprise production spec (operational details). See ./enterprise-production-spec.md
- api_gateway.md — API Gateway design and operational guidance. See ./api_gateway.md
- data_flow.md — Data flow and integration patterns. See ./data_flow.md
- monitoring.md — Monitoring, metrics, alerts, and verification steps. See ./monitoring.md
- security.md — High-level security guidance. See ./security.md

Directories (structured content)

- docs/api-reference/ — API reference artifacts and OpenAPI specifications (if present). This directory is part of the published docs; do not change the published path without coordinating with release engineering.
- docs/api/ — Service-level API guides and service runbooks.
- docs/architecture/ — Architecture diagrams and rationale.
- docs/database/ — Database schema, migrations, backup and restore procedures.
- docs/development/ — Development workflows, local environment, and test guidance.
- docs/infrastructure/ — IaC, deployments and secrets management.
- docs/operations/ — Operational runbooks and on-call procedures.
- docs/runbooks/ — Concrete, actionable runbooks for incidents.
- docs/security/ — Security playbooks and vulnerability handling.

Docs change process (mandatory)

1. Every change to files under docs/ must be made via a pull request. The PR must include:
   - Link to the issue or incident that requires the change (or `N/A` if editorial).
   - A checklist verifying the document contains no placeholder keywords (search for `TODO`, `FIXME`, `placeholder`, `sample`, `mock`, `demo`).
   - A smoke test list that an approver can run (link checks, build-preview link).
2. CI checks required for docs PRs:
   - Link validation (no broken internal links).
   - Static site generation preview (if we use a doc site builder in CI).
   - Accessibility scan (automated a11y checks) on generated preview.
3. Approvals required:
   - Technical owner(s) for the area (architecture, infra, security) must approve.
   - Engineering manager or senior engineer must provide final sign-off for production changes.

Versioning and publication

- Docs are versioned alongside releases. Each production release must update INDEX.md and CHANGELOG.md with the release notes.
- Published site is rebuilt by the CI/CD pipeline. Ensure changes are validated against the published site job before merging.

How to propose new documents or structure changes

- Add a GitHub issue describing the need and attach a draft in a branch. Do not create new top-level docs files in the default branch without a PR.
- For new public-facing docs that affect customers, create an accompanying test plan and QA checklist.

Verification & quality gates

- All links in the docs must resolve in CI preview.
- Every docs file must include contact/owner metadata (at the top or bottom) so reviewers know who to ask.
- Any procedural document with operational steps must include a safety/rollback section and the exact commands to run, along with the required observability checks (metrics/logs/traces) to verify success.

Owner metadata (update when you edit)

Maintainers: docs-team@oasis.io
Technical owner(s): architecture-team@oasis.io, infra-team@oasis.io
Security contact: security@oasis.io

Last updated: 2026-06-24

