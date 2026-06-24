-- Migration: 008_create_copilot_tables.sql
-- Description: AI Copilot, RAG retrieval, and fact-checking tables
-- Created: 2024-01-01

-- Create copilot sessions table
CREATE TABLE copilot_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE SET NULL,
  session_type VARCHAR(50) NOT NULL CHECK (session_type IN ('summarization', 'gap_analysis', 'synthesis', 'q&a')),
  started_at TIMESTAMP DEFAULT NOW(),
  ended_at TIMESTAMP,
  paper_count INTEGER,
  total_messages INTEGER,
  total_tokens_used INTEGER,
  model_used VARCHAR(50),
  cost DECIMAL(10,4)
);

-- Create copilot messages table
CREATE TABLE copilot_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES copilot_sessions(id) ON DELETE CASCADE,
  message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('user', 'assistant')),
  message_text TEXT NOT NULL,
  tokens_used INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create RAG retrievals table
CREATE TABLE rag_retrievals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES copilot_sessions(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES copilot_messages(id) ON DELETE CASCADE,
  query VARCHAR(500),
  retrieved_paper_ids UUID[],
  retrieval_strategy VARCHAR(50) NOT NULL CHECK (retrieval_strategy IN ('semantic', 'keyword', 'graph')),
  retrieval_latency_ms INTEGER,
  result_quality_score FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create fact checks table
CREATE TABLE fact_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES copilot_sessions(id) ON DELETE CASCADE,
  claim TEXT,
  supporting_papers UUID[],
  confidence_score FLOAT CHECK (confidence_score >= 0 AND confidence_score <= 1),
  status VARCHAR(50) NOT NULL CHECK (status IN ('verified', 'uncertain', 'contradicted')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for copilot sessions
CREATE INDEX idx_copilot_sessions_user ON copilot_sessions(user_id);
CREATE INDEX idx_copilot_sessions_type ON copilot_sessions(session_type);
CREATE INDEX idx_copilot_sessions_date ON copilot_sessions(started_at DESC);

-- Create indexes for copilot messages
CREATE INDEX idx_copilot_messages_session ON copilot_messages(session_id);
CREATE INDEX idx_copilot_messages_type ON copilot_messages(message_type);

-- Create indexes for RAG retrievals
CREATE INDEX idx_rag_retrievals_session ON rag_retrievals(session_id);
CREATE INDEX idx_rag_retrievals_strategy ON rag_retrievals(retrieval_strategy);
CREATE INDEX idx_rag_retrievals_latency ON rag_retrievals(retrieval_latency_ms);

-- Create indexes for fact checks
CREATE INDEX idx_fact_checks_session ON fact_checks(session_id);
CREATE INDEX idx_fact_checks_status ON fact_checks(status);
