-- Quick Fix: Create user record for existing auth user
-- Run this if you have an auth user but no record in the users table

-- Step 1: Find your auth user ID
-- Replace 'pk.20kumari@gmail.com' with your actual email
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'pk.20kumari@gmail.com';

-- Step 2: Get or create an organization
-- If you already have organizations, use one of them
-- Otherwise, this will create a default one
DO $$
DECLARE
    v_org_id UUID;
    v_user_id UUID;
    v_user_email TEXT;
BEGIN
    -- Get the first organization or create one
    SELECT organization_id INTO v_org_id
    FROM organizations
    ORDER BY created_at
    LIMIT 1;
    
    IF v_org_id IS NULL THEN
        INSERT INTO organizations (organization_name)
        VALUES ('My Organization')
        RETURNING organization_id INTO v_org_id;
    END IF;
    
    -- Get the user ID from auth.users (replace email with your email)
    SELECT id, email INTO v_user_id, v_user_email
    FROM auth.users
    WHERE email = 'pk.20kumari@gmail.com';
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found in auth.users. Please check the email address.';
    END IF;
    
    -- Create the user record
    INSERT INTO users (user_id, organization_id, role, email, full_name)
    VALUES (
        v_user_id,
        v_org_id,
        'admin', -- Change to 'recruiter' or 'manager' if needed
        v_user_email,
        'Pooja Kumari' -- Change to your actual name
    )
    ON CONFLICT (user_id) DO UPDATE SET
        organization_id = EXCLUDED.organization_id,
        role = EXCLUDED.role,
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name;
    
    RAISE NOTICE 'User record created successfully for %', v_user_email;
END $$;

-- Alternative: Simple INSERT (replace the UUID with your actual auth user ID)
-- First run: SELECT id FROM auth.users WHERE email = 'pk.20kumari@gmail.com';
-- Then use that ID below:

/*
INSERT INTO users (user_id, organization_id, role, email, full_name)
SELECT 
    au.id,
    COALESCE(
        (SELECT organization_id FROM organizations ORDER BY created_at LIMIT 1),
        (INSERT INTO organizations (organization_name) VALUES ('My Organization') RETURNING organization_id)
    ),
    'admin',
    au.email,
    'Pooja Kumari'
FROM auth.users au
WHERE au.email = 'pk.20kumari@gmail.com'
ON CONFLICT (user_id) DO NOTHING;
*/

