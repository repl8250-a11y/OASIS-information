# Quick Start — OASIS (Production-grade)

This Quick Start walks an engineer through provisioning a production-like environment, performing database migrations, validating the service, and running the verification checks required before a release to production. These steps are written for operators with access to the organization's infrastructure (cloud account, CI/CD, secrets, and monitoring). Do not run commands in production without approval from on-call and confirming maintenance windows where applicable.

Owner: ops-team@oasis.io
Last updated: 2026-06-24

Prerequisites

- AWS/Azure/GCP account with sufficient permissions.
- Kubernetes cluster (Kubernetes 1.24+) or access to EKS/AKS/GKE.
- Terraform and kubectl configured with the target cluster context.
- PostgreSQL 14+ database accessible from the cluster.
- Redis 7+ cluster for caching.
- Secrets available in Vault or cloud KMS; DO NOT store secrets in plaintext.

Environment variables (examples — set from your secrets manager):

- PGHOST (hostname)
- PGPORT (5432)
- PGUSER (app user)
- PGPASSWORD (from Vault/KMS)
- REDIS_URL (redis://...)
- S3_BUCKET (artifact storage)
- OAUTH_CLIENT_ID / OAUTH_CLIENT_SECRET

Step 1 — Provision infrastructure (Terraform)

1. Review the Terraform plan in the infra repository for changes. Example:

   export TF_VAR_region=us-east-1
   terraform init
   terraform plan -var-file=prod.tfvars

2. Apply in a controlled manner using an automated pipeline (do not run apply locally unless approved):

   terraform apply -var-file=prod.tfvars

Verification:
- Confirm RDS/Postgres is available and in correct subnet groups.
- Confirm Redis cluster status is healthy.
- Confirm S3 bucket created and encryption is enabled (SSE-KMS).

Step 2 — Prepare database and run migrations

Migrations are managed with a SQL migration tool (e.g., Flyway, Goose, or sqitch). Example using `sqitch`:

1. Ensure migration tool is configured to read DB credentials from the environment (do not hardcode credentials).

2. Validate pending migrations locally against a staging DB:

   export PGHOST=staging-db.mycompany.internal
   export PGUSER=oasis_migrator
   export PGPASSWORD="$(vault kv get -field=password secret/oasis/prod/db)"
   sqitch verify db:pg://${PGUSER}@${PGHOST}:${PGPORT}/oasis

3. Apply migrations via CI pipeline with a pre-deploy safety check and a backup snapshot taken immediately prior to applying:

   # Create a logical backup (pg_dump) or snapshot depending on cloud
   aws rds create-db-snapshot --db-instance-identifier oasis-db --db-snapshot-identifier pre-migration-$(date -u +%Y%m%dT%H%M%SZ)

   # Apply migrations (through CI-run job)
   sqitch deploy db:pg://${PGUSER}@${PGHOST}:${PGPORT}/oasis

Verification:
- Run smoke queries against key tables to validate schema and counts.
- Confirm no downtime by checking health endpoints and monitoring dashboards (p95 latency and error rate baseline).
- Monitor replication lag and connection counts during migration.

Rollback plan:
- If migrations fail, stop new deployments and restore from the snapshot, then open a post-mortem.
- For additive-only migrations with backward compatibility, use feature flags and a two-step migration where required.

Step 3 — Deploy services (Kubernetes / Helm)

1. Use CI pipeline to build and push images to the registry. Images must be signed and scans must pass.
2. Deploy via Helm with a canary rollout strategy (5% → 25% → 100%). Example:

   helm upgrade --install oasis-core ./charts/oasis-core --namespace oasis --values prod-values.yaml --wait

3. Verify pods start successfully and pass readiness probes. Example checks:

   kubectl -n oasis get pods --selector app=oasis-core
   kubectl -n oasis logs deploy/oasis-core --since=5m | tail -n 200

Verification:
- Health endpoints return 200 (e.g., /healthz, /metrics)
- Prometheus scraping is healthy for the new pods
- Traces are showing in Jaeger for sample requests

Step 4 — Connectivity and authentication checks

1. Confirm API Gateway routes are healthy and JWT validation works.
2. Use an authorized service account to perform an authenticated API call (do not use hard-coded tokens):

   ACCESS_TOKEN=$(vault kv get -field=token secret/oasis/ci/service-account)
   curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" https://api.oasis.io/v1/health

Expected result: 200 with JSON body containing service status and version.

Step 5 — Run verification tests (CI-driven)

1. Run the full test suite via CI including:
   - Unit tests
   - Integration tests against staging DB and mocked external dependencies where required
   - Contract tests for API compatibility
   - Smoke tests that exercise core user flows

2. Run performance and load tests on a staging environment sized to match production.

Step 6 — Observability and metrics validation

Before promoting to production, validate:

- Prometheus metrics are present and within expected baselines (latency, error rate, DB metrics).
- Grafana dashboards reflect expected behavior for p95/p99 latency.
- Logs contain structured JSON entries with request IDs for correlation.

Safety and rollback

- Do not promote to production until a snapshot/backup is available and quick rollback steps are documented in the deployment ticket.
- For schema changes, prefer backward-compatible migrations and feature flags.
- Maintain a canary window and probe for 15–30 minutes at each canary step before progressing.

Post-deployment checks

- Validate user-facing functionality and critical API endpoints.
- Confirm no new critical alerts in Prometheus/Alertmanager.
- Check error budgets and SLO compliance in the last 24 hours.

Contacts & Escalation

- On-call: oncall@oasis.io
- Operations: ops-team@oasis.io
- Security: security@oasis.io

