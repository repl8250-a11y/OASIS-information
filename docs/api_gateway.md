# API Gateway Contract (Production)

Owner: infra-team@oasis.io
Last updated: 2026-06-24

Purpose

The API Gateway is the single public entrypoint for HTTP(s) traffic into OASIS. It enforces authentication and authorization, TLS termination, routing, request/response normalization, rate limiting, and observability. The gateway implementation may be Envoy, Kong, Apigee, or a managed API Gateway — the operational contract described here must be satisfied by the chosen implementation.

Responsibilities

- TLS termination with mTLS support for service-to-service where required.
- Validate Bearer JWTs issued by the auth-service (issuer, audience, signature, expiry, and required claims).
- Enforce per-API-key and per-user rate limits and burst limits.
- Route traffic to appropriate backend services with retry/backoff and circuit-breaker policies.
- Add and propagate correlation IDs for full-traceability (X-Request-Id, traceparent).
- Reject/redirect requests that violate contract (invalid auth, malformed payloads, unsupported TLS ciphers).
- Emit access logs and Prometheus metrics.

Authentication & Authorization

- JWT validation:
  - Verify token signature using JWKS from the auth-service or identity provider.
  - Validate `iss` (issuer), `aud` (audience), `exp` (expiration), and `nbf` claims.
  - Enforce token revocation via a revocation list or short-lived access tokens + refresh tokens.

- Authorization:
  - Gateway performs coarse-grained authorization (route-level checks) and injects principal claims into the request for downstream services to enforce fine-grained RBAC.
  - Required token claims for gateway-level checks: `sub`, `scope` or `roles`, `tenant_id` (for multi-tenant installs).
  - Deny by default. Any route that allows anonymous access must be explicitly permitted in gateway config.

Rate Limiting & Quotas

- Rate limits must support per-user, per-org (tenant), and per-IP quotas.
- Default production limits:
  - Standard: 1000 requests/hour per API key
  - Burst: up to 200 requests/minute with smoothing token bucket
  - Enterprise/custom limits configured per tenant
- Enforce server-side quotas backed by a distributed store (Redis or central quota service) to avoid inconsistent enforcement on scale.

Routing & Resilience

- Route examples (path -> upstream):
  - /api/v1/auth -> auth-service
  - /api/v1/papers -> paper-service
  - /api/v1/kg -> knowledge-graph-service

- Retries and circuit breakers:
  - Retries: idempotent GET/HEAD requests may retry up to 2 times with exponential backoff. Non-idempotent operations MUST NOT be retried by the gateway.
  - Circuit breaker: open when 5xx rate > 10% over 1 minute or consecutive failures > 10 for a target instance.

Health Checks & Failover

- Gateway must perform active upstream health checks and avoid routing to unhealthy pods/instances.
- Health check endpoints: /healthz (returns 200 plus JSON {"status":"ok","component":"<name>","version":"<semver>"}).
- Failover across AZs/regions handled by DNS+load balancer layer; gateway should prefer local healthy endpoints when possible.

Observability (Logging & Metrics)

- Access logs must be structured JSON including these fields: timestamp, request_id, method, path, status, latency_ms, upstream, user_id (if authenticated), tenant_id, client_ip, user_agent.
- Exposed Prometheus metrics (scrape /metrics):
  - gateway_requests_total{method,route,status}
  - gateway_request_duration_seconds_bucket{route}
  - gateway_active_connections
  - gateway_rate_limit_denied_total{reason}
  - gateway_upstream_latency_seconds_bucket{upstream}

- Trace propagation: accept traceparent and/or x-cloud-trace-context; add trace headers to upstream requests.

Logging retention

- Access logs: 90 days for ERROR/WARN, 30 days for INFO, 7 days for DEBUG (debug level only in dev or ephemeral runs).

Security

- Enforce TLS 1.2+ and prefer 1.3. Disable RC4, DES, and other weak ciphers.
- Use mTLS for traffic between API Gateway and internal critical services (auth-service, paper-service by default) when possible.
- Ensure gateway configuration is stored in an IaC repo and reviewed in PRs with architecture and security approvers.

Configuration examples

- Envoy JWT verification config (conceptual snippet, do not embed secrets):

  - jwt_provider:
      name: oasis_jwt
      issuer: https://auth.oasis.io/
      audiences:
        - api://default
      jwks_uri: https://auth.oasis.io/.well-known/jwks.json

- Rate limit config backed by Redis (example): configure a central rate limit service that the gateway calls per-request.

Operational runbook (gateway incidents)

1. Alert: High 5xx rate or gateway unavailable.
2. Triage: check gateway pods, restart if crashlooping, check upstream health and JWKS availability.
3. If JWT validation errors spike: verify JWKS endpoint reachable and not returning stale keys. Rotate keys via auth-service if needed.
4. If rate limit store unavailable: fail open only if safe; prefer returning 429 rather than allowing unlimited traffic.
5. Escalation: infra/ops oncall and security if keys or certs are compromised.

Testing & CI

- Gateway configuration changes must have automated tests:
  - Unit tests for route config generation
  - Integration tests that validate JWT validation, rate limiting, routing to mock upstreams
  - End-to-end smoke tests in staging hitting the gateway and verifying headers, auth, and metrics

Owner metadata

Maintainers: infra-team@oasis.io
Technical owner(s): architecture-team@oasis.io, security@oasis.io
