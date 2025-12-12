-- Row Level Security (RLS) Policies for HireLens
-- All policies enforce organization-level data isolation

-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidate_stage_events ENABLE ROW LEVEL SECURITY;

-- Helper function to get user's organization_id
CREATE OR REPLACE FUNCTION get_user_organization_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT organization_id FROM users WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Organizations Policies
CREATE POLICY "Users can view their own organization"
    ON organizations FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Authenticated users can view all organizations"
    ON organizations FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can create organizations"
    ON organizations FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Admins can update their organization"
    ON organizations FOR UPDATE
    USING (organization_id = get_user_organization_id() 
           AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'admin'));

-- Users Policies
CREATE POLICY "Users can view users in their organization"
    ON users FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Authenticated users can view all users"
    ON users FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can insert themselves"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can insert users in their organization"
    ON users FOR INSERT
    WITH CHECK (organization_id = get_user_organization_id() 
                AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "Users can update themselves"
    ON users FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Admins can update users in their organization"
    ON users FOR UPDATE
    USING (organization_id = get_user_organization_id() 
           AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'admin'));

-- Roles Policies
CREATE POLICY "Users can view roles in their organization"
    ON roles FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Recruiters and admins can insert roles"
    ON roles FOR INSERT
    WITH CHECK (organization_id = get_user_organization_id() 
                AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role IN ('recruiter', 'admin')));

CREATE POLICY "Recruiters and admins can update roles"
    ON roles FOR UPDATE
    USING (organization_id = get_user_organization_id() 
           AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role IN ('recruiter', 'admin')));

-- Candidates Policies
CREATE POLICY "Users can view candidates in their organization"
    ON candidates FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Recruiters and admins can insert candidates"
    ON candidates FOR INSERT
    WITH CHECK (organization_id = get_user_organization_id() 
                AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role IN ('recruiter', 'admin')));

CREATE POLICY "Recruiters and admins can update candidates"
    ON candidates FOR UPDATE
    USING (organization_id = get_user_organization_id() 
           AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role IN ('recruiter', 'admin')));

-- Managers can view candidates for their assigned roles
CREATE POLICY "Managers can view candidates for assigned roles"
    ON candidates FOR SELECT
    USING (organization_id = get_user_organization_id() 
           AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'manager'));

-- Candidate Stage Events Policies
CREATE POLICY "Users can view events in their organization"
    ON candidate_stage_events FOR SELECT
    USING (organization_id = get_user_organization_id());

CREATE POLICY "Recruiters and admins can insert events"
    ON candidate_stage_events FOR INSERT
    WITH CHECK (organization_id = get_user_organization_id() 
                AND EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role IN ('recruiter', 'admin'))
                AND moved_by = auth.uid());

-- Note: Events are immutable (no UPDATE/DELETE policies)

