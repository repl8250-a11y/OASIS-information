-- Migration: 001_create_users_tables.sql
-- Description: Core user, session, and authentication tables
-- Created: 2024-01-01

-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  profile_picture_url VARCHAR(500),
  bio TEXT,
  research_interests TEXT[],
  orcid_id VARCHAR(50) UNIQUE,
  researcher_profile_verified BOOLEAN DEFAULT false,
  h_index INTEGER,
  institution_id UUID,
  position_title VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB,
  CONSTRAINT valid_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Create sessions table
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ip_address INET,
  user_agent VARCHAR(500),
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  last_activity TIMESTAMP DEFAULT NOW(),
  metadata JSONB
);

-- Create MFA settings table
CREATE TABLE mfa_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  mfa_type VARCHAR(20) CHECK (mfa_type IN ('totp', 'sms', 'email')),
  secret_key VARCHAR(255),
  backup_codes TEXT[],
  enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  verified_at TIMESTAMP
);

-- Create OAuth connections table
CREATE TABLE oauth_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,
  provider_user_id VARCHAR(255) NOT NULL,
  provider_email VARCHAR(255),
  access_token VARCHAR(1000),
  refresh_token VARCHAR(1000),
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(provider, provider_user_id),
  CONSTRAINT valid_provider CHECK (provider IN ('google', 'github', 'orcid'))
);

-- Create API keys table
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  key_hash VARCHAR(255) NOT NULL UNIQUE,
  last_used_at TIMESTAMP,
  rate_limit_requests_per_minute INTEGER DEFAULT 100,
  rate_limit_requests_per_day INTEGER DEFAULT 10000,
  scopes VARCHAR(255)[],
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create auth audit logs table
CREATE TABLE auth_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type VARCHAR(50) NOT NULL,
  ip_address INET,
  user_agent VARCHAR(500),
  status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failure')),
  failure_reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create user preferences table
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  theme VARCHAR(20) DEFAULT 'auto',
  language VARCHAR(20) DEFAULT 'en',
  email_digest_frequency VARCHAR(20) DEFAULT 'weekly',
  email_alerts_enabled BOOLEAN DEFAULT true,
  paper_recommendations_enabled BOOLEAN DEFAULT true,
  trending_topics_enabled BOOLEAN DEFAULT true,
  notification_preferences JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_orcid ON users(orcid_id);
CREATE INDEX idx_users_institution ON users(institution_id);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Create indexes for sessions table
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_user_active ON sessions(user_id) WHERE expires_at > NOW();

-- Create indexes for OAuth connections
CREATE INDEX idx_oauth_provider ON oauth_connections(provider, provider_user_id);
CREATE INDEX idx_oauth_user ON oauth_connections(user_id);

-- Create indexes for API keys
CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_active ON api_keys(user_id) WHERE is_active = true;

-- Create indexes for audit logs
CREATE INDEX idx_auth_logs_user_date ON auth_audit_logs(user_id, created_at DESC);
CREATE INDEX idx_auth_logs_event_date ON auth_audit_logs(event_type, created_at DESC);

-- Create partial index for failed login attempts
CREATE INDEX idx_auth_logs_failed_recent ON auth_audit_logs(user_id, created_at)
WHERE status = 'failure' AND created_at > NOW() - INTERVAL '1 hour';
