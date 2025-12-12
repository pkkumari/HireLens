-- HireLens Database Schema
-- This file contains all table definitions, indexes, and constraints

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations Table
CREATE TABLE organizations (
    organization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Roles Table (Job Roles)
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    role_name TEXT NOT NULL,
    department TEXT,
    seniority TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users Table (extends Supabase auth.users)
-- NOTE: This table stores application-specific user data (organization, role, etc.)
-- Passwords are NOT stored here - they are managed by Supabase Auth in auth.users table
-- When a user signs up/logs in, Supabase Auth handles password authentication
-- The user_id here references auth.users(id) to link the two tables
CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('recruiter', 'admin', 'manager')),
    email TEXT NOT NULL,
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidates Table
CREATE TABLE candidates (
    candidate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(role_id) ON DELETE SET NULL,
    recruiter_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    source TEXT,
    location TEXT,
    current_stage TEXT NOT NULL DEFAULT 'Application Submitted',
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'rejected', 'withdrawn', 'hired')),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Stage Events Table (Event-sourced)
CREATE TABLE candidate_stage_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES candidates(candidate_id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(organization_id) ON DELETE CASCADE,
    from_stage TEXT,
    to_stage TEXT NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('advance', 'reject', 'withdraw')),
    reason_code TEXT NOT NULL,
    reason_text TEXT,
    moved_by UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    moved_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_users_organization ON users(organization_id);
CREATE INDEX idx_candidates_organization ON candidates(organization_id);
CREATE INDEX idx_candidates_stage ON candidates(organization_id, current_stage);
CREATE INDEX idx_candidates_status ON candidates(organization_id, status);
CREATE INDEX idx_events_organization ON candidate_stage_events(organization_id);
CREATE INDEX idx_events_candidate ON candidate_stage_events(candidate_id);
CREATE INDEX idx_events_moved_at ON candidate_stage_events(organization_id, moved_at DESC);
CREATE INDEX idx_events_stage ON candidate_stage_events(organization_id, to_stage);
CREATE INDEX idx_roles_organization ON roles(organization_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_candidates_updated_at BEFORE UPDATE ON candidates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

