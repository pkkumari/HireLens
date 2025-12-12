-- Seed Dummy Users for HireLens
-- This script creates dummy users for testing and development
-- 
-- IMPORTANT: Before running this script, you need to create the auth users first.
-- Option 1: Use Supabase Dashboard -> Authentication -> Add User
-- Option 2: Use the Supabase CLI or API to create users
-- Option 3: Use the helper function below (requires service_role key)

-- ============================================================================
-- STEP 1: Create Auth Users (Choose one method)
-- ============================================================================

-- Method A: Create users via Supabase Dashboard
-- 1. Go to Authentication -> Users -> Add User
-- 2. Create users with these emails and set passwords:
--    - admin@acmecorp.com (password: admin123)
--    - recruiter1@acmecorp.com (password: recruiter123)
--    - recruiter2@acmecorp.com (password: recruiter123)
--    - manager1@acmecorp.com (password: manager123)
--    - admin@techstart.com (password: admin123)
--    - recruiter1@techstart.com (password: recruiter123)

-- Method B: Use Supabase Management API (requires service_role key)
-- You can use the Supabase client or curl to create users:
-- Example curl command:
/*
curl -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/admin/users' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@acmecorp.com",
    "password": "admin123",
    "email_confirm": true,
    "user_metadata": {
      "full_name": "Admin User"
    }
  }'
*/

-- ============================================================================
-- STEP 2: Get Auth User IDs and Insert into users table
-- ============================================================================

-- IMPORTANT: You MUST create the auth users FIRST before running the INSERT statements below!
-- The foreign key constraint requires that user_id exists in auth.users table.

-- After creating auth users via Supabase Dashboard or API, run this query to get their IDs:
/*
SELECT 
    id as user_id,
    email,
    raw_user_meta_data->>'full_name' as full_name
FROM auth.users 
WHERE email IN (
    'admin@acmecorp.com',
    'recruiter1@acmecorp.com',
    'recruiter2@acmecorp.com',
    'manager1@acmecorp.com',
    'admin@techstart.com',
    'recruiter1@techstart.com'
)
ORDER BY email;
*/

-- ============================================================================
-- METHOD 1: Insert users by email (RECOMMENDED - Auto-fetches IDs from auth.users)
-- ============================================================================
-- This function-based approach automatically gets the user_id from auth.users

-- Dummy Users for Acme Corp (Organization 1)
INSERT INTO users (user_id, organization_id, role, email, full_name)
SELECT 
    au.id,
    '00000000-0000-0000-0000-000000000001'::UUID,
    CASE 
        WHEN au.email = 'admin@acmecorp.com' THEN 'admin'
        WHEN au.email = 'manager1@acmecorp.com' THEN 'manager'
        ELSE 'recruiter'
    END,
    au.email,
    CASE 
        WHEN au.email = 'admin@acmecorp.com' THEN 'Admin User'
        WHEN au.email = 'recruiter1@acmecorp.com' THEN 'Sarah Johnson'
        WHEN au.email = 'recruiter2@acmecorp.com' THEN 'Michael Chen'
        WHEN au.email = 'manager1@acmecorp.com' THEN 'Emily Rodriguez'
        ELSE au.email
    END
FROM auth.users au
WHERE au.email IN (
    'admin@acmecorp.com',
    'recruiter1@acmecorp.com',
    'recruiter2@acmecorp.com',
    'manager1@acmecorp.com'
)
ON CONFLICT (user_id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

-- Dummy Users for TechStart Inc (Organization 2)
INSERT INTO users (user_id, organization_id, role, email, full_name)
SELECT 
    au.id,
    '00000000-0000-0000-0000-000000000002'::UUID,
    CASE 
        WHEN au.email = 'admin@techstart.com' THEN 'admin'
        ELSE 'recruiter'
    END,
    au.email,
    CASE 
        WHEN au.email = 'admin@techstart.com' THEN 'Admin User'
        WHEN au.email = 'recruiter1@techstart.com' THEN 'David Kim'
        ELSE au.email
    END
FROM auth.users au
WHERE au.email IN (
    'admin@techstart.com',
    'recruiter1@techstart.com'
)
ON CONFLICT (user_id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

-- ============================================================================
-- METHOD 2: Manual Insert (If you prefer to use specific UUIDs)
-- ============================================================================
-- Only use this if you want to manually specify UUIDs
-- First, get the actual IDs from auth.users, then replace the UUIDs below:

/*
-- Step 1: Get the actual user IDs
SELECT id, email FROM auth.users WHERE email = 'admin@acmecorp.com';
-- Copy the id value

-- Step 2: Use the actual ID in the INSERT
INSERT INTO users (user_id, organization_id, role, email, full_name) VALUES
    ('<paste-actual-id-here>', '00000000-0000-0000-0000-000000000001', 'admin', 'admin@acmecorp.com', 'Admin User')
ON CONFLICT (user_id) DO UPDATE SET
    organization_id = EXCLUDED.organization_id,
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;
*/

-- ============================================================================
-- HELPER FUNCTION: Auto-link auth users to users table
-- ============================================================================
-- This function automatically creates user records when auth users are created
-- Run this AFTER creating the auth users

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_org_id UUID;
BEGIN
    -- Get the first organization (or create a default one)
    SELECT organization_id INTO default_org_id
    FROM organizations
    ORDER BY created_at
    LIMIT 1;
    
    -- If no organization exists, create a default one
    IF default_org_id IS NULL THEN
        INSERT INTO organizations (organization_name)
        VALUES ('Default Organization')
        RETURNING organization_id INTO default_org_id;
    END IF;
    
    -- Insert into users table with default role 'recruiter'
    INSERT INTO public.users (user_id, organization_id, role, email, full_name)
    VALUES (
        NEW.id,
        default_org_id,
        'recruiter',
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- QUICK SETUP SCRIPT: Create users with specific organization assignment
-- ============================================================================
-- If you want to assign users to specific organizations after creation,
-- use this update script (replace UUIDs with actual auth user IDs):

/*
UPDATE users 
SET organization_id = '00000000-0000-0000-0000-000000000001',
    role = 'admin'
WHERE email = 'admin@acmecorp.com';

UPDATE users 
SET organization_id = '00000000-0000-0000-0000-000000000001',
    role = 'recruiter'
WHERE email IN ('recruiter1@acmecorp.com', 'recruiter2@acmecorp.com');

UPDATE users 
SET organization_id = '00000000-0000-0000-0000-000000000001',
    role = 'manager'
WHERE email = 'manager1@acmecorp.com';

UPDATE users 
SET organization_id = '00000000-0000-0000-0000-000000000002',
    role = 'admin'
WHERE email = 'admin@techstart.com';

UPDATE users 
SET organization_id = '00000000-0000-0000-0000-000000000002',
    role = 'recruiter'
WHERE email = 'recruiter1@techstart.com';
*/

