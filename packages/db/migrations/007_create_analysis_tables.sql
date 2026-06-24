-- Migration: 007_create_analysis_tables.sql
-- Description: Novelty scores, gaps, portfolio, and competitive analysis
-- Created: 2024-01-01

-- Create novelty scores table
CREATE TABLE novelty_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  novelty_score FLOAT NOT NULL CHECK (novelty_score >= 0 AND novelty_score <= 100),
  conceptual_novelty FLOAT,
  methodological_novelty FLOAT,
  empirical_novelty FLOAT,
  semantic_distance FLOAT,
  trend_velocity FLOAT,
  saturation_penalty FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(paper_id, metric_date)
);

-- Create topic trends table
CREATE TABLE topic_trends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic VARCHAR(255) NOT NULL,
  metric_date DATE NOT NULL,
  paper_count INTEGER,
  new_authors_count INTEGER,
  avg_novelty_score FLOAT,
  trending_velocity FLOAT,
  field VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(topic, metric_date)
);

-- Create research gaps table
CREATE TABLE research_gaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gap_title VARCHAR(255) NOT NULL,
  gap_description TEXT,
  field VARCHAR(100),
  subfield VARCHAR(100),
  gap_type VARCHAR(50) NOT NULL CHECK (gap_type IN ('topic_combination', 'method', 'cross_disciplinary', 'empirical')),
  impact_score FLOAT CHECK (impact_score >= 0 AND impact_score <= 100),
  difficulty_score FLOAT CHECK (difficulty_score >= 0 AND difficulty_score <= 100),
  resource_requirement_score FLOAT CHECK (resource_requirement_score >= 0 AND resource_requirement_score <= 100),
  opportunity_score FLOAT CHECK (opportunity_score >= 0 AND opportunity_score <= 100),
  detected_date DATE,
  status VARCHAR(50) NOT NULL CHECK (status IN ('emerging', 'active', 'saturating', 'solved')),
  related_papers INTEGER,
  detected_by_algorithm VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create gap opportunities table
CREATE TABLE gap_opportunities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gap_id UUID NOT NULL REFERENCES research_gaps(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  alignment_score FLOAT,
  feasibility_score FLOAT,
  strategic_importance_score FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(gap_id, team_id)
);

-- Create competitive analysis table
CREATE TABLE competitive_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  competitor_organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  metric_date DATE NOT NULL,
  competing_on_topic VARCHAR(255),
  competitor_paper_count INTEGER,
  our_paper_count INTEGER,
  competitor_avg_novelty FLOAT,
  our_avg_novelty FLOAT,
  competitive_intensity FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, competitor_organization_id, metric_date, competing_on_topic)
);

-- Create portfolio entries table
CREATE TABLE portfolio_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id UUID REFERENCES research_projects(id) ON DELETE SET NULL,
  paper_id UUID REFERENCES papers(id) ON DELETE SET NULL,
  entry_type VARCHAR(50) NOT NULL CHECK (entry_type IN ('internal_project', 'funded_paper', 'collaboration')),
  status VARCHAR(50) NOT NULL CHECK (status IN ('active', 'completed', 'archived')),
  investment_amount DECIMAL(15,2),
  start_date DATE,
  end_date DATE,
  expected_impact_score FLOAT,
  actual_impact_score FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create portfolio analysis table
CREATE TABLE portfolio_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  total_active_projects INTEGER,
  total_investment DECIMAL(15,2),
  avg_project_novelty FLOAT,
  portfolio_diversity_score FLOAT,
  gap_coverage_score FLOAT,
  competitive_comparison_score FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, metric_date)
);

-- Create indexes for novelty scores
CREATE INDEX idx_novelty_scores_paper_date ON novelty_scores(paper_id, metric_date DESC);
CREATE INDEX idx_novelty_scores_date ON novelty_scores(metric_date DESC);
CREATE INDEX idx_novelty_scores_score ON novelty_scores(novelty_score DESC);

-- Create indexes for topic trends
CREATE INDEX idx_topic_trends_date ON topic_trends(metric_date DESC);
CREATE INDEX idx_topic_trends_topic ON topic_trends(topic);
CREATE INDEX idx_topic_trends_field ON topic_trends(field);
CREATE INDEX idx_topic_trends_velocity ON topic_trends(trending_velocity DESC);

-- Create indexes for research gaps
CREATE INDEX idx_research_gaps_field ON research_gaps(field, subfield);
CREATE INDEX idx_research_gaps_status ON research_gaps(status);
CREATE INDEX idx_research_gaps_impact ON research_gaps(impact_score DESC);
CREATE INDEX idx_research_gaps_opportunity ON research_gaps(opportunity_score DESC);

-- Create indexes for gap opportunities
CREATE INDEX idx_gap_opportunities_gap ON gap_opportunities(gap_id);
CREATE INDEX idx_gap_opportunities_team ON gap_opportunities(team_id);

-- Create indexes for competitive analysis
CREATE INDEX idx_competitive_analysis_org ON competitive_analysis(organization_id, metric_date DESC);
CREATE INDEX idx_competitive_analysis_competitor ON competitive_analysis(competitor_organization_id);

-- Create indexes for portfolio entries
CREATE INDEX idx_portfolio_entries_org ON portfolio_entries(organization_id);
CREATE INDEX idx_portfolio_entries_project ON portfolio_entries(project_id);
CREATE INDEX idx_portfolio_entries_status ON portfolio_entries(status);

-- Create indexes for portfolio analysis
CREATE INDEX idx_portfolio_analysis_org_date ON portfolio_analysis(organization_id, metric_date DESC);
