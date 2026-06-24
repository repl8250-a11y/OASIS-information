# Monitoring, Metrics & SLOs — OASIS

Owner: ops-team@oasis.io
Technical contacts: infra-team@oasis.io, monitoring@oasis.io
Last updated: 2026-06-24

Purpose

This document specifies the metrics, alerting, SLOs, logging format, retention policies, and operational runbooks required to operate OASIS in production. All services MUST expose the metrics, logs, and health endpoints described below. Monitoring configuration is part of infrastructure-as-code and must be reviewed in PRs.

1. Metrics (Prometheus)

Each service MUST expose a /metrics endpoint compatible with Prometheus. Metrics MUST use stable metric names and include service and instance labels.

Common labels (all metrics):
- service: logical service name (e.g., auth-service, paper-service)
- instance: pod or instance id
- handler: API handler or operation
- method: HTTP method
- status: HTTP status code or internal state
- tenant: tenant_id when applicable

Required metrics (per service):
- oasis_requests_total{service,handler,method,status,tenant} (counter)
- oasis_request_duration_seconds_bucket{service,handler,method} (histogram)
- oasis_request_active{service,handler} (gauge)
- oasis_db_query_seconds_bucket{service,query_type} (histogram)
- oasis_cache_hit_total{service,cache} (counter)
- oasis_cache_miss_total{service,cache} (counter)
- oasis_background_jobs_processed_total{service,job_name,result} (counter)
- oasis_errors_total{service,handler,level} (counter)
- oasis_worker_queue_depth{service,queue} (gauge)

Instrumentation guidance
- Use semantic, stable metric names and re-use the oasis_ prefix.
- Use histograms for request and DB latency to compute p50/p95/p99.
- Expose metrics for feature flags / experiment buckets where relevant.
- Include build_version and commit_sha in /metrics as gauges or info metrics for correlation.

2. SLOs & Error Budget

Global SLOs (default):
- Availability SLO (user-facing API): 99.99% uptime measured per month for critical endpoints.
- Latency SLO (read endpoints): p95 latency < 200ms.
- Error Rate SLO: <0.1% errors (5xx) per request across critical endpoints.

Calculating error budget
- Error budget = 1 - SLO_percentage over the measurement window. Track burn rate using Prometheus recording rules.
- When burn rate > 2x for a sustained period (10m), trigger on-call and initiate mitigation.

3. Alerting (Prometheus Alertmanager)

Alerting levels: P0 (critical), P1 (high), P2 (medium), P3 (low). Alerts MUST include runbook links and playbooks.

Example alert rules (PromQL):

- Critical: Service Down (no healthy pods)
  - expr: absent(up{job="oasis_gateway"}) or sum(up{job=~".*"}) by (service) == 0
  - for: 1m
  - severity: P0

- High: Error rate spike (5xx requests > 1% over 5 minutes for a service)
  - expr: sum(rate(oasis_requests_total{status=~"5.."}[5m])) by (service) / sum(rate(oasis_requests_total[5m])) by (service) > 0.01
  - for: 5m
  - severity: P1

- High: DB replication lag
  - expr: pg_replication_lag_seconds{role="replica"} > 30
  - for: 3m
  - severity: P1

- Medium: High CPU
  - expr: avg_over_time(node_cpu_seconds_total{mode="idle"}[5m]) < 0.2
  - for: 10m
  - severity: P2

- SLO breach: sustained error budget burn
  - expr: increase(oasis_errors_total[1h]) / increase(oasis_requests_total[1h]) > 0.001 and absent(reset)
  - for: 10m
  - severity: P1

4. Runbooks (operational playbooks)

Runbook: Service unavailable / 5xx spike
- Symptoms: Prometheus alert P0/P1 for error-rate spike or service down.
- Immediate actions:
  1. Acknowledge alert in Alertmanager and notify on-call.
  2. Check Kubernetes: kubectl -n <ns> get pods -l service=<service>; kubectl describe pod <pod>
  3. Inspect recent logs: kubectl -n <ns> logs deploy/<deployment> --since=10m | jq -c '.message'
  4. Check Prometheus graphs for oasis_request_duration_seconds_bucket and oasis_errors_total.
  5. If OOM / resource issues, scale replicas or increase resource requests; if unhealthy deployments, roll back to last known-good image: helm rollback <release> <revision>.
  6. If upstream DB is failing, fail fast and return 503 rather than retrying indefinitely.
- Post-mortem: collect logs, traces (Jaeger), relevant Prometheus queries, and open incident report within 48 hours.

Runbook: DB replication lag
- Symptoms: pg_replication_lag_seconds > threshold (default 5s for minor, 30s for critical)
- Immediate actions:
  1. Identify replication topology: psql -c "SELECT client_addr, state, sync_priority FROM pg_stat_replication;"
  2. Check replica resource usage (CPU, I/O), network latency, and disk pressure.
  3. If replica is overloaded, remove from load balancer, promote another replica if necessary, or scale up replica size.
  4. For severe corruption or long lag, restore from latest snapshot and funnel write traffic to primary only until replicas catch up.
- Validation: ensure replication lag drops to <1s and read endpoints return expected data consistency.

Runbook: SLO breach / error budget burn
- Symptoms: SLO alert fired (SLO breach or burn rate high).
- Immediate actions:
  1. Triage which endpoints contribute most to the burn: Prometheus query by handler.
  2. If a recent deployment correlates with the breach, immediately pause rollouts and consider rollback.
  3. Apply mitigations: reduce traffic via rate limiting, enable circuit breakers, divert traffic to previous version.
  4. Notify stakeholders and schedule a follow-up post-mortem.

5. Logging

Requirements
- All services must emit structured JSON logs with the following fields:
  - timestamp (RFC3339)
  - level (ERROR/WARN/INFO/DEBUG)
  - service
  - instance
  - request_id
  - trace_id
  - user_id (if authenticated)
  - tenant_id (if applicable)
  - message
  - error (object/string when level is ERROR)
  - duration_ms (when applicable)
- Correlate logs with traces using request_id and trace_id.

Log shipping
- Use a centralized log collector (Fluentd/Vector) to send logs to ELK or a managed logging service.
- Filter sensitive fields (PII) at the agent level and use redaction rules.

Retention & Access
- ERROR/WARN logs: retain 90 days
- INFO logs: retain 30 days
- DEBUG logs: retain 7 days (only collected in staging or with explicit toggle)

6. Dashboards & Reports

Required Grafana dashboards:
- Service overview: requests, latencies, error rates, CPU/Memory
- DB overview: query latency, connections, replication lag
- Cache overview: hit ratio, evictions, memory usage
- SLO dashboard: calculated SLOs and error budget burn rate

Weekly reports
- Send weekly SLO reports (availability, error rate, latency) to stakeholders and include major incidents.

7. Test & Verification

- Unit tests: verify metrics instrumentation is present with a metrics test harness.
- Integration tests: run against staging with Prometheus scraping the services and validate SLO calculations.
- Synthetic checks: uptime checks that run external HTTP requests every 30s and alert on failures.

8. CI & Automation

- All changes to monitoring rules must be in IaC and reviewed in PRs.
- CI must validate Prometheus alert syntax and render Grafana dashboards in preview.
- All runbook links must be embedded in Alertmanager notifications and include escalation steps.

9. Ownership & Escalation

- Primary on-call: ops-oncall@oasis.io
- Secondary: infra-oncall@oasis.io
- Pager: use PagerDuty with escalation policy defined in the on-call schedule.

