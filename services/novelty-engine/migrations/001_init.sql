-- 001_init.sql for novelty-engine

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS novelty_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID,
  score DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
