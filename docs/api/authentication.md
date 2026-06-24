# Authentication & Authorization — ResearchOS / OASIS

This document describes the authentication and authorization model used by ResearchOS / OASIS in Production. It is written for engineers implementing or integrating with the API and for security reviewers.

Summary
- Primary auth mechanism: short-lived JWT access tokens (RS256) issued by the internal STS (Security Token Service).
- Refresh tokens are opaque, single-use, and rotated on refresh.
- OAuth 2.0 Authorization Code + PKCE is supported for third-party and SPA flows.
- Machine-to-machine (service) auth: short-lived client credentials issued via the internal STS, or mTLS for highly privileged communication.
- All traffic MUST be over TLS 1.2+ (recommend TLS 1.3).

Token types
- Access Token (JWT)
  - Signed by STS (RS256) and published via JWKS (/.well-known/jwks.json).
  - Claims: iss, sub, aud, exp, iat, jti, scope, roles, tenant (if multi-tenant).
  - Recommended lifetime: 15 minutes (adjustable per client type).
- Refresh Token
  - Opaque token stored server-side (or hashed) with one-time rotation policy.
  - Lifetime: configurable (default 30 days).
  - Each refresh operation returns a new refresh token and invalidates the previous one.
- Service Token / Client Credentials
  - Short-lived tokens issued to service identities; scope-limited.
  - Prefer dynamic short-lived credentials (STS) over long-lived static tokens.
- mTLS Certificates
  - Use for critical control-plane traffic where available (e.g., data-plane control, backup orchestration).

Primary flows
1) Native Login / Password
- Endpoint: POST /api/auth/login
- Input: { email, password }
- On success: returns access_token, refresh_token, expires_in.
- Security: rate-limit and device fingerprinting; enforce MFA for privileged accounts.

2) OAuth 2.0 (Authorization Code + PKCE)
- Standard Authorization Code flow for SPAs and server apps.
- Providers: Google, ORCID, institutional SSO (SAML/OIDC via broker).
- Map external claims to internal roles and tenant metadata during account linking.

3) Token Refresh
- Endpoint: POST /api/auth/refresh
- Input: { refresh_token }
- Behavior: atomically exchange and rotate refresh token; issue new access token.

4) Logout / Revocation
- Endpoint: POST /api/auth/logout
- Behavior: revoke refresh_token and blacklist related access tokens for immediate effect (short TTL cache plus persisted blacklist).

5) Service Authentication
- CI/CD and automation should obtain tokens from STS using client credentials and ephemeral tokens.
- Use least-privilege scopes and short TTLs.

Authorization model
- Role-Based Access Control (RBAC) with optional resource-level authorization.
- Scopes are coarse-grained for the API gateway and map to roles in the microservices.
- Policy enforcement is centralized in an Authorization Middleware / Policy Service; services call the policy service for complex decisions.

Security controls & best practices
- JWKS endpoint provides rotating public keys; services must refresh keys regularly.
- Validate all JWT standard claims: iss, aud, exp, nbf, jti.
- Enforce audience (aud) checking to avoid token reuse across services.
- Apply rate limits to auth endpoints and monitor failed authentication trends.
- Use HSTS and secure cookie attributes when cookies used for sessions.
- Store refresh tokens hashed with a secure KDF if persisted.
- Use CAPTCHAs or device-based protections on suspicious login flows.
- Log auth events (success/failure, IP, client_id, user-agent) to the centralized audit store; redact sensitive details.

MFA & privileged flows
- Enforce MFA (TOTP or WebAuthn) for admin and sensitive roles.
- Provide recovery codes and hardware-key enrollment; ensure recovery flow is auditable.

Compromise & rotation
- Provide emergency token revocation APIs for compromised accounts.
- Rotate STS signing keys regularly; maintain multi-key support for smooth rotation.
- Maintain short-lived credentials for automation and rotate at policy intervals.

Operational requirements
- Audit logs retention per compliance requirements.
- Alerts for anomalous auth spikes or mass failed logins.
- Pen-testing coverage of auth flows annually (or per release for major changes).
