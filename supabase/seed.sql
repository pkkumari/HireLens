-- Seed Data for HireLens
-- This file contains sample data for testing and development

-- Insert sample organizations
INSERT INTO organizations (organization_id, organization_name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Acme Corp'),
    ('00000000-0000-0000-0000-000000000002', 'TechStart Inc')
ON CONFLICT (organization_id) DO NOTHING;

-- Note: Users should be created through Supabase Auth first
-- See seed_users.sql for detailed instructions on creating dummy users
-- The seed_users.sql file includes:
-- 1. Instructions for creating auth users
-- 2. SQL to insert user records
-- 3. A trigger function to auto-create user records when auth users are created

-- Insert sample roles
INSERT INTO roles (role_id, organization_id, role_name, department, seniority) VALUES
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Senior Software Engineer', 'Engineering', 'Senior'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Product Manager', 'Product', 'Mid'),
    ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'UX Designer', 'Design', 'Mid'),
    ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Data Scientist', 'Engineering', 'Senior'),
    ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Marketing Manager', 'Marketing', 'Mid')
ON CONFLICT (role_id) DO NOTHING;

-- Helper function to create test data (run after users are created)
-- This is a template - adjust user_id values based on your auth setup

/*
-- Example: Insert sample candidates (uncomment and adjust after creating users)
INSERT INTO candidates (
    candidate_id, organization_id, role_id, recruiter_id, 
    source, location, current_stage, status,
    first_name, last_name, email, phone
) VALUES
    (
        gen_random_uuid(),
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '<recruiter-user-id>',
        'LinkedIn',
        'San Francisco, CA',
        'Interview Round 1',
        'active',
        'John',
        'Doe',
        'john.doe@example.com',
        '+1-555-0101'
    ),
    (
        gen_random_uuid(),
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000002',
        '<recruiter-user-id>',
        'Company Website',
        'New York, NY',
        'Recruiter Screening',
        'active',
        'Jane',
        'Smith',
        'jane.smith@example.com',
        '+1-555-0102'
    );
*/

