# Data Flow — OASIS

Owner: architecture-team@oasis.io
Technical contacts: data-platform@oasis.io, ops-team@oasis.io
Last updated: 2026-06-24

Purpose

This document describes production data flows for OASIS: ingestion, transformation, storage, eventing, search indexing, backups, DR, and recovery procedures. It includes event contracts, idempotency strategies, monitoring requirements, and concrete recovery steps.

1. High-level architecture

ASCII diagram (simplified):

  +------------+    +-------------+    +-----------+    +-------------+
  | Ingest G/W | -> | paper-svc   | -> | Postgres  | -> | consumers   |
  | (API/GCS)  |    | (transform) |    | (OLTP)    |    | (kg, search) |
  +------------+    +-------------+    +-----------+    +-------------+
                         |   \                       
                         |    -> message bus (Kafka) -> search-indexer
                         v
                      audit/logs

Key flows
- Ingestion: External clients upload papers via API or direct object storage. paper-service validates, normalizes, stores primary record in Postgres, and emits a paper.ingested event to the event bus (Kafka).
- Transformation: Consumers (knowledge-graph-service, analytics, indexer) consume events and perform downstream processing. Consumers must be idempotent and resilient to re-delivery.
- Indexing/Search: Search indexer consumes events and updates Elasticsearch/managed search index. Index updates are asynchronous but must meet eventual consistency guarantees (< 30s under normal load).

2. Event contract & schema

All events MUST conform to a versioned JSON Schema stored in the schema registry (e.g., Confluent Schema Registry or Git-backed registry). Event names and examples:

- Topic: paper.ingested v1
  - Key: paper_id (UUID)
  - Value (JSON):
    {
      "version": "1",
      "paper_id": "uuid-...",
      "title": "...",
      "authors": [{"name":"...","orcid":"..."}],
      "ingested_at": "2026-06-24T12:00:00Z",
      "source": {"type":"api","endpoint":"/api/v1/papers/upload"},
      "checksum": "sha256:...",
      "metadata": {...}
    }

Versioning rules
- Use semantic versioning in topic name or embed a version field. Changes are backward compatible where possible (additive fields). For breaking changes, create a new topic version (paper.ingested.v2) and coordinate consumer migration.
- Schema registry MUST validate compatibility (BACKWARD or FULL as defined by the team).

3. Idempotency & deduplication

- Producers MUST set a deterministic key (paper_id). Consumers must use the message key to detect duplicates.
- For HTTP ingestion endpoints that may be retried by clients, support an Idempotency-Key header. The server stores idempotency keys in a bounded deduplication table with TTL (default 24 hours) keyed by idempotency-key + client_id.
- For message consumers, implement upsert semantics with stable unique constraints (e.g., INSERT ... ON CONFLICT DO UPDATE) and record the event offset/processed_version to avoid reprocessing.

4. Delivery guarantees

- At-least-once delivery is the operational default for Kafka consumers. To approach exactly-once semantics for critical updates, implement idempotent consumer logic and transactionally update state in Postgres using event offset as part of the transactional insert.
- Consumers must commit offsets only after successful processing and storing of the result.

5. Data storage and schemas

- Primary OLTP store: PostgreSQL 14+ with schemas for core entities (papers, users, permissions). Use strong constraints and FK relationships to preserve data integrity.
- Long-term object storage: S3/GCS with server-side encryption (SSE-KMS). Store object metadata in Postgres referencing the object key.
- Analytical store: Data warehouse (e.g., Snowflake, BigQuery) populated via scheduled ETL/CDC jobs. CDC may be implemented via Debezium or built-in RDS logical replication.

6. Backup & DR procedures

Postgres backups
- Daily logical backups (pg_dump) and hourly incremental snapshots (cloud provider snapshots) retained per retention policy.
- Backups stored encrypted in a designated S3 bucket with cross-region replication.

Restore verification
1. Restore snapshot to a staging RDS instance: follow cloud provider restore steps.
2. Run verification queries: record counts for key tables and selected integrity checks:
   - SELECT COUNT(*) FROM papers WHERE created_at > now() - interval '7 days';
   - SELECT count(*) from users where last_login is not null;
3. Run smoke tests against restored instance to validate application read flows.

Disaster recovery
- RPO: <5 minutes for critical data via logical replication or WAL shipping.
- RTO: recover to a functional state within 15 minutes for primary services using automated restore runbooks.

7. Consistency & reconciliation

- Implement periodic reconciliation jobs that compare authoritative Postgres state and derived indexes (search, KG). Reconcile by re-emitting events or performing targeted repairs.
- Example reconcile job: for each paper_id in Postgres, verify search index contains matching document; if missing, re-index paper via indexer API.

8. Operational observability

Required metrics (in addition to service metrics):
- event_bus_produced_total{topic}
- event_bus_consumed_total{topic,consumer_group}
- event_bus_lag{topic,partition}
- event_processing_duration_seconds_bucket{service,handler}
- last_successful_offset{topic,consumer_group}

Required logs
- Producers log event production with event_id, topic, key, and checksum.
- Consumers log processing outcome with event_offset, event_id, duration_ms, error (if any).

9. Recovery playbooks (concrete steps)

Playbook: Consumer backlog / consumer lag
- Symptoms: event_bus_lag rising and not decreasing; search index stale.
- Steps:
  1. Identify affected consumer group: kafka-consumer-groups --bootstrap-server <kafka> --describe --group <group>
  2. Check consumer pod logs for errors and stack traces.
  3. If consumer is crashed, restart deployment: kubectl -n <ns> rollout restart deployment/<consumer>
  4. If consumer is slow due to processing, scale consumer replicas or increase resources.
  5. If offsets are corrupted, consider resetting offsets carefully: kafka-consumer-groups --reset-offsets --to-earliest/--to-latest with --execute (only after approval).

Playbook: Corrupted data detected in downstream index
- Symptoms: search returns inconsistent results or missing documents.
- Steps:
  1. Pause consumers to stop further writes (if necessary) — set feature flag or scale to zero.
  2. Export list of affected IDs from Postgres.
  3. Re-run indexer with the list (indexer supports bulk reindex endpoint) or re-emit events for those IDs: update papers set reindex_requested = true; and consumer reads this flag.
  4. Verify index contents and monitor event_bus_lag until resolved.

10. Compliance & audit

- All write operations to production data stores MUST be logged and auditable. Enable Postgres audit logging for DDL/DML on sensitive tables.
- Maintain an immutable audit trail for security-sensitive operations (permission changes, role assignments) stored separately and replicated.

11. Testing & CI

- Schema changes MUST be validated with unit tests and integration tests. Run migrations against a disposable test DB and include a migration smoke test in CI.
- Event contract changes MUST be validated with contract tests between producer and consumers.

