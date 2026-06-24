-- 001_init.sql for export-service

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS export_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  params JSONB,
  status TEXT,
  artifact_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
