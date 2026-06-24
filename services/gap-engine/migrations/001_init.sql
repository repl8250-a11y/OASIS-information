-- 001_init.sql for gap-engine

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS gap_suggestions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic TEXT,
  details JSONB,
  score DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
