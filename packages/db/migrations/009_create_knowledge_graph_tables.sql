-- Migration: 009_create_knowledge_graph_tables.sql
-- Description: Knowledge graph entities, relationships, and mentions
-- Created: 2024-01-01

-- Create knowledge graph entities table
CREATE TABLE knowledge_graph_entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('concept', 'method', 'dataset', 'organism', 'disease', 'researcher', 'organization')),
  entity_name VARCHAR(255) NOT NULL,
  entity_normalized_name VARCHAR(255) NOT NULL,
  description TEXT,
  field VARCHAR(100),
  subfield VARCHAR(100),
  paper_count INTEGER DEFAULT 0,
  first_mentioned_paper_date DATE,
  last_mentioned_paper_date DATE,
  entity_embeddings FLOAT[],
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(entity_type, entity_normalized_name)
);

-- Create knowledge graph relationships table
CREATE TABLE knowledge_graph_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_a_id UUID NOT NULL REFERENCES knowledge_graph_entities(id) ON DELETE CASCADE,
  entity_b_id UUID NOT NULL REFERENCES knowledge_graph_entities(id) ON DELETE CASCADE,
  relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN ('uses', 'develops', 'studies', 'extends', 'contradicts', 'similar_to', 'parent_of')),
  relationship_strength FLOAT CHECK (relationship_strength >= 0 AND relationship_strength <= 1),
  paper_count INTEGER DEFAULT 0,
  first_paper_date DATE,
  last_paper_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(entity_a_id, entity_b_id, relationship_type)
);

-- Create entity mentions table
CREATE TABLE entity_mentions (
  id BIGSERIAL PRIMARY KEY,
  entity_id UUID NOT NULL REFERENCES knowledge_graph_entities(id) ON DELETE CASCADE,
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  mention_count INTEGER DEFAULT 1,
  first_mention_position INTEGER,
  context_text VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for knowledge graph entities
CREATE INDEX idx_kg_entities_type ON knowledge_graph_entities(entity_type);
CREATE INDEX idx_kg_entities_name ON knowledge_graph_entities(entity_normalized_name);
CREATE INDEX idx_kg_entities_field ON knowledge_graph_entities(field, subfield);
CREATE INDEX idx_kg_entities_paper_count ON knowledge_graph_entities(paper_count DESC);

-- Create indexes for relationships
CREATE INDEX idx_kg_relationships_entity_a ON knowledge_graph_relationships(entity_a_id);
CREATE INDEX idx_kg_relationships_entity_b ON knowledge_graph_relationships(entity_b_id);
CREATE INDEX idx_kg_relationships_type ON knowledge_graph_relationships(relationship_type);
CREATE INDEX idx_kg_relationships_strength ON knowledge_graph_relationships(relationship_strength DESC);

-- Create composite index for efficient relationship traversal
CREATE INDEX idx_kg_relationships_ab_type ON knowledge_graph_relationships(entity_a_id, entity_b_id, relationship_type);

-- Create indexes for entity mentions
CREATE INDEX idx_entity_mentions_entity ON entity_mentions(entity_id);
CREATE INDEX idx_entity_mentions_paper ON entity_mentions(paper_id);
CREATE INDEX idx_entity_mentions_entity_paper ON entity_mentions(entity_id, paper_id);
