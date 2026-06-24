-- Migration: 010_create_access_control_tables.sql
-- Description: Compliance, audit logs, and access control
-- Created: 2024-01-01

-- Create paper access rights table
CREATE TABLE paper_access_rights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  access_type VARCHAR(50) NOT NULL CHECK (access_type IN ('open_access', 'institutional', 'paid', 'restricted')),
  license_type VARCHAR(50) CHECK (license_type IN ('cc-by', 'cc-by-nc', 'publisher_agreement', 'unknown')),
  legal_status VARCHAR(50) NOT NULL CHECK (legal_status IN ('verified_legal', 'likely_legal', 'restricted', 'unknown')),
  requires_authentication BOOLEAN DEFAULT false,
  can_redistribute BOOLEAN DEFAULT false,
  can_modify BOOLEAN DEFAULT false,
  last_verified_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(paper_id, organization_id)
);

-- Create data export requests table
CREATE TABLE data_export_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'processing', 'ready', 'downloaded')),
  request_date TIMESTAMP DEFAULT NOW(),
  completion_date TIMESTAMP,
  file_url VARCHAR(500),
  file_expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create audit logs table
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  action_type VARCHAR(100) NOT NULL,
  resource_type VARCHAR(50),
  resource_id UUID,
  resource_name VARCHAR(255),
  action_details JSONB,
  ip_address INET,
  status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failure')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create user consent table
CREATE TABLE user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  consent_type VARCHAR(50) NOT NULL CHECK (consent_type IN ('privacy_policy', 'terms_of_service', 'research_usage')),
  version VARCHAR(20),
  accepted BOOLEAN DEFAULT false,
  accepted_at TIMESTAMP,
  ip_address INET,
  user_agent VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create user data request table (GDPR)
CREATE TABLE user_data_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('export', 'delete', 'rectify')),
  status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
  reason TEXT,
  requested_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  result_url VARCHAR(500)
);

-- Create indexes for paper access rights
CREATE INDEX idx_paper_access_paper ON paper_access_rights(paper_id);
CREATE INDEX idx_paper_access_org ON paper_access_rights(organization_id);
CREATE INDEX idx_paper_access_legal_status ON paper_access_rights(legal_status);

-- Create indexes for data export requests
CREATE INDEX idx_data_export_user ON data_export_requests(user_id);
CREATE INDEX idx_data_export_status ON data_export_requests(status);
CREATE INDEX idx_data_export_date ON data_export_requests(request_date DESC);

-- Create indexes for audit logs
CREATE INDEX idx_audit_logs_user_date ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_org_date ON audit_logs(organization_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_action_date ON audit_logs(action_type, created_at DESC);
CREATE INDEX idx_audit_logs_date ON audit_logs(created_at DESC);

-- Create indexes for user consents
CREATE INDEX idx_user_consents_user ON user_consents(user_id);
CREATE INDEX idx_user_consents_type ON user_consents(consent_type);
CREATE INDEX idx_user_consents_accepted ON user_consents(accepted);

-- Create indexes for data requests
CREATE INDEX idx_user_data_requests_user ON user_data_requests(user_id);
CREATE INDEX idx_user_data_requests_status ON user_data_requests(status);
CREATE INDEX idx_user_data_requests_type ON user_data_requests(request_type);
