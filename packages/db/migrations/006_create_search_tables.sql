-- Migration: 006_create_search_tables.sql
-- Description: Search queries, trending, and analytics tables
-- Created: 2024-01-01

-- Create search queries table
CREATE TABLE search_queries (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  query_text VARCHAR(500) NOT NULL,
  search_type VARCHAR(50) NOT NULL CHECK (search_type IN ('keyword', 'semantic', 'hybrid')),
  result_count INTEGER,
  clicked_result_count INTEGER,
  saved_from_results BOOLEAN DEFAULT false,
  execution_time_ms INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create trending searches table
CREATE TABLE trending_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  search_query VARCHAR(500) NOT NULL,
  metric_date DATE NOT NULL,
  query_count INTEGER,
  unique_users INTEGER,
  trend_direction VARCHAR(20) CHECK (trend_direction IN ('up', 'down', 'stable')),
  trend_strength FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(search_query, metric_date)
);

-- Create user search behavior table
CREATE TABLE user_search_behavior (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  searches_per_day INTEGER,
  papers_clicked INTEGER,
  papers_saved INTEGER,
  papers_read_count INTEGER,
  most_searched_topics VARCHAR(255)[],
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, metric_date)
);

-- Create indexes for search queries
CREATE INDEX idx_search_queries_user_date ON search_queries(user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_search_queries_org_date ON search_queries(organization_id, created_at DESC) WHERE organization_id IS NOT NULL;
CREATE INDEX idx_search_queries_type ON search_queries(search_type);
CREATE INDEX idx_search_queries_created ON search_queries(created_at DESC);

-- Create indexes for trending searches
CREATE INDEX idx_trending_searches_date ON trending_searches(metric_date DESC);
CREATE INDEX idx_trending_searches_query ON trending_searches(search_query);
CREATE INDEX idx_trending_searches_strength ON trending_searches(trend_strength DESC);

-- Create indexes for user search behavior
CREATE INDEX idx_user_search_behavior_user_date ON user_search_behavior(user_id, metric_date DESC);
CREATE INDEX idx_user_search_behavior_date ON user_search_behavior(metric_date DESC);
