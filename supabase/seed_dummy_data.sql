-- Seed Dummy Data for HireLens Dashboard
-- This script populates the database with realistic dummy data for testing and demonstration
-- Run this AFTER running schema.sql, rls.sql, and seed.sql

-- ============================================================================
-- STEP 1: Ensure you have organizations and roles
-- ============================================================================
-- Make sure you've run seed.sql first to create organizations and roles
-- If not, uncomment and run:
/*
INSERT INTO organizations (organization_id, organization_name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Acme Corp')
ON CONFLICT (organization_id) DO NOTHING;

INSERT INTO roles (role_id, organization_id, role_name, department, seniority) VALUES
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Senior Software Engineer', 'Engineering', 'Senior'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Product Manager', 'Product', 'Mid'),
    ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'UX Designer', 'Design', 'Mid'),
    ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Data Scientist', 'Engineering', 'Senior'),
    ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Marketing Manager', 'Marketing', 'Mid')
ON CONFLICT (role_id) DO NOTHING;
*/

-- ============================================================================
-- STEP 2: Get a recruiter user_id (replace with your actual user_id)
-- ============================================================================
-- First, get a user_id from your users table:
-- SELECT user_id FROM users WHERE role = 'recruiter' LIMIT 1;
-- Then replace 'YOUR_RECRUITER_USER_ID' below with that UUID

-- For this script, we'll use a placeholder - you need to replace it
DO $$
DECLARE
    v_org_id UUID := '00000000-0000-0000-0000-000000000001';
    v_recruiter_id UUID;
    v_role_ids UUID[];
    v_candidate_id UUID;
    v_stage TEXT;
    v_action_type TEXT;
    v_reason_code TEXT;
    v_from_stage TEXT;
    v_to_stage TEXT;
    i INTEGER;
    j INTEGER;
    v_first_names TEXT[] := ARRAY['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'James', 'Jessica', 'Robert', 'Amanda', 'William', 'Lisa', 'Richard', 'Michelle', 'Joseph'];
    v_last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Wilson', 'Anderson', 'Thomas'];
    v_sources TEXT[] := ARRAY['LinkedIn', 'Company Website', 'Referral', 'Indeed', 'Glassdoor', 'AngelList', 'University Career Fair', 'Recruitment Agency'];
    v_locations TEXT[] := ARRAY['San Francisco, CA', 'New York, NY', 'Austin, TX', 'Seattle, WA', 'Boston, MA', 'Chicago, IL', 'Los Angeles, CA', 'Denver, CO'];
    v_stages TEXT[] := ARRAY[
        'Application Submitted',
        'Recruiter Screening',
        'Hiring Manager Review',
        'Interview Round 1',
        'Interview Round 2',
        'Offer Extended',
        'Offer Accepted',
        'Background Check',
        'Joined'
    ];
    v_reasons TEXT[] := ARRAY[
        'Compensation mismatch',
        'Role mismatch',
        'Interview feedback',
        'Candidate withdrew',
        'Ghosted',
        'Failed background check',
        'Other'
    ];
    v_emails TEXT[];
    v_phones TEXT[];
BEGIN
    -- Get recruiter user_id (use the first recruiter found)
    SELECT user_id INTO v_recruiter_id
    FROM users
    WHERE organization_id = v_org_id AND role = 'recruiter'
    LIMIT 1;
    
    -- If no recruiter found, use the first user
    IF v_recruiter_id IS NULL THEN
        SELECT user_id INTO v_recruiter_id
        FROM users
        WHERE organization_id = v_org_id
        LIMIT 1;
    END IF;
    
    -- If still no user, raise an error
    IF v_recruiter_id IS NULL THEN
        RAISE EXCEPTION 'No users found in organization. Please create a user first.';
    END IF;
    
    -- Get all role IDs for this organization
    SELECT ARRAY_AGG(role_id) INTO v_role_ids
    FROM roles
    WHERE organization_id = v_org_id;
    
    IF v_role_ids IS NULL OR array_length(v_role_ids, 1) = 0 THEN
        RAISE EXCEPTION 'No roles found. Please create roles first using seed.sql';
    END IF;
    
    RAISE NOTICE 'Creating 15 candidates for each of % roles...', array_length(v_role_ids, 1);
    
    -- Generate email and phone arrays
    FOR i IN 1..225 LOOP
        v_emails[i] := 'candidate' || i || '@example.com';
        v_phones[i] := '+1-555-' || LPAD((1000 + i)::TEXT, 4, '0');
    END LOOP;
    
    -- Create 15 candidates for each role
    FOR i IN 1..array_length(v_role_ids, 1) LOOP
        FOR j IN 1..15 LOOP
            -- Calculate candidate index
            DECLARE
                candidate_idx INTEGER := (i - 1) * 15 + j;
                first_name TEXT := v_first_names[1 + (candidate_idx - 1) % array_length(v_first_names, 1)];
                last_name TEXT := v_last_names[1 + (candidate_idx - 1) % array_length(v_last_names, 1)];
                source TEXT := v_sources[1 + (candidate_idx - 1) % array_length(v_sources, 1)];
                location TEXT := v_locations[1 + (candidate_idx - 1) % array_length(v_locations, 1)];
                email TEXT := v_emails[candidate_idx];
                phone TEXT := v_phones[candidate_idx];
                
                -- Distribute candidates across stages
                stage_idx INTEGER := 1 + (candidate_idx - 1) % array_length(v_stages, 1);
                current_stage TEXT := v_stages[stage_idx];
                
                -- Determine status based on stage
                candidate_status TEXT;
                days_ago INTEGER;
            BEGIN
                -- Set status based on stage
                IF current_stage = 'Joined' THEN
                    candidate_status := 'hired';
                ELSIF current_stage IN ('Application Submitted', 'Recruiter Screening', 'Hiring Manager Review', 'Interview Round 1', 'Interview Round 2', 'Offer Extended', 'Offer Accepted', 'Background Check') THEN
                    -- Some candidates in earlier stages should be rejected/withdrawn
                    IF (candidate_idx % 7) = 0 THEN
                        candidate_status := 'rejected';
                    ELSIF (candidate_idx % 11) = 0 THEN
                        candidate_status := 'withdrawn';
                    ELSE
                        candidate_status := 'active';
                    END IF;
                ELSE
                    candidate_status := 'active';
                END IF;
                
                -- Calculate created_at (spread over last 90 days)
                days_ago := 90 - ((candidate_idx - 1) % 90);
                
                -- Insert candidate
                INSERT INTO candidates (
                    candidate_id,
                    organization_id,
                    role_id,
                    recruiter_id,
                    source,
                    location,
                    current_stage,
                    status,
                    first_name,
                    last_name,
                    email,
                    phone,
                    created_at,
                    updated_at
                ) VALUES (
                    gen_random_uuid(),
                    v_org_id,
                    v_role_ids[i],
                    v_recruiter_id,
                    source,
                    location,
                    current_stage,
                    candidate_status,
                    first_name,
                    last_name,
                    email,
                    phone,
                    NOW() - (days_ago || ' days')::INTERVAL,
                    NOW() - (days_ago || ' days')::INTERVAL
                ) RETURNING candidate_id INTO v_candidate_id;
                
                -- Create stage events for this candidate
                -- Start from Application Submitted and move through stages
                v_from_stage := NULL;
                
                FOR stage_idx IN 1..array_length(v_stages, 1) LOOP
                    v_to_stage := v_stages[stage_idx];
                    
                    -- Stop if we've reached the candidate's current stage
                    IF v_to_stage = current_stage THEN
                        -- Create event for current stage
                        IF candidate_status = 'rejected' THEN
                            v_action_type := 'reject';
                            v_reason_code := CASE 
                                WHEN (candidate_idx % 3) = 0 THEN 'Interview feedback'
                                WHEN (candidate_idx % 3) = 1 THEN 'Role mismatch'
                                ELSE 'Other'
                            END;
                        ELSIF candidate_status = 'withdrawn' THEN
                            v_action_type := 'withdraw';
                            v_reason_code := CASE 
                                WHEN (candidate_idx % 2) = 0 THEN 'Candidate withdrew'
                                ELSE 'Ghosted'
                            END;
                        ELSE
                            v_action_type := 'advance';
                            v_reason_code := 'Other';
                        END IF;
                        
                        INSERT INTO candidate_stage_events (
                            candidate_id,
                            organization_id,
                            from_stage,
                            to_stage,
                            action_type,
                            reason_code,
                            reason_text,
                            moved_by,
                            moved_at
                        ) VALUES (
                            v_candidate_id,
                            v_org_id,
                            v_from_stage,
                            v_to_stage,
                            v_action_type,
                            v_reason_code,
                            CASE WHEN v_reason_code = 'Other' THEN 'Moved to ' || v_to_stage ELSE NULL END,
                            v_recruiter_id,
                            NOW() - (days_ago || ' days')::INTERVAL + (stage_idx || ' hours')::INTERVAL
                        );
                        EXIT; -- Stop at current stage
                    ELSE
                        -- Create event for past stages
                        INSERT INTO candidate_stage_events (
                            candidate_id,
                            organization_id,
                            from_stage,
                            to_stage,
                            action_type,
                            reason_code,
                            reason_text,
                            moved_by,
                            moved_at
                        ) VALUES (
                            v_candidate_id,
                            v_org_id,
                            v_from_stage,
                            v_to_stage,
                            'advance',
                            'Other',
                            'Moved to ' || v_to_stage,
                            v_recruiter_id,
                            NOW() - (days_ago || ' days')::INTERVAL + (stage_idx || ' hours')::INTERVAL
                        );
                        v_from_stage := v_to_stage;
                    END IF;
                END LOOP;
                
            END;
        END LOOP;
        
        RAISE NOTICE 'Created 15 candidates for role %', i;
    END LOOP;
    
    RAISE NOTICE 'Successfully created % candidates with stage events!', array_length(v_role_ids, 1) * 15;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check candidate counts by role
SELECT 
    r.role_name,
    COUNT(c.candidate_id) as candidate_count,
    COUNT(CASE WHEN c.status = 'active' THEN 1 END) as active_count,
    COUNT(CASE WHEN c.status = 'hired' THEN 1 END) as hired_count,
    COUNT(CASE WHEN c.status = 'rejected' THEN 1 END) as rejected_count
FROM roles r
LEFT JOIN candidates c ON r.role_id = c.role_id
WHERE r.organization_id = '00000000-0000-0000-0000-000000000001'
GROUP BY r.role_id, r.role_name
ORDER BY r.role_name;

-- Check candidates by stage
SELECT 
    current_stage,
    COUNT(*) as count,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
    COUNT(CASE WHEN status = 'hired' THEN 1 END) as hired,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected
FROM candidates
WHERE organization_id = '00000000-0000-0000-0000-000000000001'
GROUP BY current_stage
ORDER BY 
    CASE current_stage
        WHEN 'Application Submitted' THEN 1
        WHEN 'Recruiter Screening' THEN 2
        WHEN 'Hiring Manager Review' THEN 3
        WHEN 'Interview Round 1' THEN 4
        WHEN 'Interview Round 2' THEN 5
        WHEN 'Offer Extended' THEN 6
        WHEN 'Offer Accepted' THEN 7
        WHEN 'Background Check' THEN 8
        WHEN 'Joined' THEN 9
    END;

-- Check stage events count
SELECT COUNT(*) as total_events
FROM candidate_stage_events
WHERE organization_id = '00000000-0000-0000-0000-000000000001';


