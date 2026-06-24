-- 001_init.sql for integration-service

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS connectors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  config JSONB,
  state JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
