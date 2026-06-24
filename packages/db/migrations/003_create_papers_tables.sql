-- Migration: 003_create_papers_tables.sql
-- Description: Papers, metadata, versions, and content tables
-- Created: 2024-01-01

-- Create papers table
CREATE TABLE papers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id VARCHAR(50) NOT NULL,
  source VARCHAR(50) NOT NULL CHECK (source IN ('arxiv', 'pubmed', 'biorxiv', 'chemrxiv', 'crossref', 'other')),
  source_url VARCHAR(500),
  title VARCHAR(500) NOT NULL,
  abstract TEXT,
  keywords VARCHAR(100)[],
  publication_date DATE,
  first_author_name VARCHAR(255),
  author_count INTEGER,
  journal_name VARCHAR(255),
  journal_issn VARCHAR(20),
  volume VARCHAR(20),
  issue VARCHAR(20),
  pages VARCHAR(50),
  doi VARCHAR(100) UNIQUE,
  pmid VARCHAR(50) UNIQUE,
  arxiv_id VARCHAR(50) UNIQUE,
  language VARCHAR(10) DEFAULT 'en',
  subject_areas VARCHAR(100)[],
  field VARCHAR(100),
  subfield VARCHAR(100),
  publication_status VARCHAR(50) CHECK (publication_status IN ('preprint', 'published', 'retracted')),
  is_open_access BOOLEAN DEFAULT false,
  open_access_url VARCHAR(500),
  pdf_available BOOLEAN DEFAULT false,
  pdf_s3_path VARCHAR(500),
  text_extracted BOOLEAN DEFAULT false,
  text_s3_path VARCHAR(500),
  citation_count INTEGER DEFAULT 0,
  h_index_score FLOAT,
  relevance_score FLOAT,
  novelty_score FLOAT,
  impact_score FLOAT,
  version VARCHAR(50),
  deduplication_master_id UUID REFERENCES papers(id) ON DELETE SET NULL,
  data_ingestion_timestamp TIMESTAMP DEFAULT NOW(),
  last_updated TIMESTAMP DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(source, source_id)
);

-- Create paper versions table
CREATE TABLE paper_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  source_id VARCHAR(50),
  version_number INTEGER NOT NULL,
  publication_date DATE,
  doi VARCHAR(100),
  title VARCHAR(500),
  abstract TEXT,
  version_type VARCHAR(50) CHECK (version_type IN ('preprint', 'published', 'corrected')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create paper authors table
CREATE TABLE paper_authors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  author_name VARCHAR(255) NOT NULL,
  author_order INTEGER NOT NULL,
  orcid_id VARCHAR(50),
  affiliation VARCHAR(500),
  researcher_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create paper citations table
CREATE TABLE paper_citations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  citing_paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  cited_paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  citation_context VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(citing_paper_id, cited_paper_id)
);

-- Create paper content table
CREATE TABLE paper_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL UNIQUE REFERENCES papers(id) ON DELETE CASCADE,
  full_text TEXT,
  section_texts JSONB,
  key_findings TEXT,
  key_limitations TEXT,
  future_work TEXT,
  extracted_concepts VARCHAR(255)[],
  extracted_methods VARCHAR(255)[],
  extracted_datasets VARCHAR(255)[],
  extracted_organisms VARCHAR(255)[],
  extracted_diseases VARCHAR(255)[],
  tables_and_figures JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create paper metadata table
CREATE TABLE paper_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL UNIQUE REFERENCES papers(id) ON DELETE CASCADE,
  is_indexed BOOLEAN DEFAULT false,
  index_timestamp TIMESTAMP,
  search_text_indexed BOOLEAN DEFAULT false,
  availability_status VARCHAR(50) CHECK (availability_status IN ('available', 'restricted', 'not_available')),
  license_type VARCHAR(50),
  institution_count INTEGER DEFAULT 0
);

-- Create indexes for papers table
CREATE INDEX idx_papers_source ON papers(source, source_id);
CREATE INDEX idx_papers_doi ON papers(doi);
CREATE INDEX idx_papers_pmid ON papers(pmid);
CREATE INDEX idx_papers_arxiv ON papers(arxiv_id);
CREATE INDEX idx_papers_title_tsvector ON papers USING gin(to_tsvector('english', title));
CREATE INDEX idx_papers_abstract_tsvector ON papers USING gin(to_tsvector('english', abstract));
CREATE INDEX idx_papers_field_subfield ON papers(field, subfield);
CREATE INDEX idx_papers_publication_date ON papers(publication_date DESC);
CREATE INDEX idx_papers_novelty_score ON papers(novelty_score DESC);
CREATE INDEX idx_papers_citation_count ON papers(citation_count DESC);
CREATE INDEX idx_papers_h_index ON papers(h_index_score DESC);
CREATE INDEX idx_papers_open_access ON papers(is_open_access);
CREATE INDEX idx_papers_language ON papers(language);

-- Create indexes for paper authors
CREATE INDEX idx_paper_authors_paper ON paper_authors(paper_id);
CREATE INDEX idx_paper_authors_orcid ON paper_authors(orcid_id);
CREATE INDEX idx_paper_authors_name ON paper_authors(author_name);

-- Create indexes for citations
CREATE INDEX idx_paper_citations_citing ON paper_citations(citing_paper_id);
CREATE INDEX idx_paper_citations_cited ON paper_citations(cited_paper_id);

-- Create indexes for content
CREATE INDEX idx_paper_content_paper ON paper_content(paper_id);

-- Create indexes for metadata
CREATE INDEX idx_paper_metadata_paper ON paper_metadata(paper_id);
CREATE INDEX idx_paper_metadata_availability ON paper_metadata(availability_status);
