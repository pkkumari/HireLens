# HireLens - Hiring Pipeline & Analytics Platform

A modern, analytics-first hiring pipeline management system built with Next.js, Supabase, and Tailwind CSS.

## Features

- 🎯 **Multi-Organization Support** - Isolated data per organization with Row Level Security
- 📊 **Real-Time Analytics** - Funnel analysis, drop-off insights, time metrics, and source performance
- 📋 **Kanban Pipeline** - Visual candidate management with drag-and-drop stage movement
- 🔐 **Role-Based Access** - Recruiter, Admin, and Manager roles with appropriate permissions
- 📱 **Responsive Design** - Beautiful, modern UI that works on all devices
- 🎨 **Modern Color Scheme** - Gradient-based design with primary and accent colors

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **Icons**: Lucide React
- **TypeScript**: Full type safety

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- A Supabase account and project

### Installation

1. **Clone and install dependencies**
   ```bash
   cd HireLens
   npm install
   ```

2. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Go to SQL Editor and run the files in `supabase/` folder in this order:
     1. `schema.sql` - Creates all tables and indexes
     2. `rls.sql` - Sets up Row Level Security policies (includes auto-user creation trigger)
     3. `views.sql` - Creates analytics views
     4. `seed.sql` - (Optional) Adds sample organizations and roles
     5. `seed_users.sql` - (Optional) Creates dummy users and auto-link trigger
     6. `seed_dummy_data.sql` - (Optional) Populates dashboard with 15 candidates per role

3. **Configure environment variables**
   ```bash
   cp .env.example .env.local
   ```
   
   Then edit `.env.local` and add your Supabase credentials:
   ```
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Create your first user**
   - **Option A: Automatic (Recommended)**
     - Sign up through the app at `/signup`
     - The app will automatically create your user record and organization
     - You'll be assigned to a default organization with 'recruiter' role
     - You can update your role later if needed
   
   - **Option B: Manual Setup**
     - Create an organization first:
       ```sql
       INSERT INTO organizations (organization_name)
       VALUES ('Your Company Name')
       RETURNING organization_id;
       ```
     - Sign up through the app at `/signup`
     - Then manually create a user record:
       ```sql
       INSERT INTO users (user_id, organization_id, role, email, full_name)
       SELECT 
         au.id,
         '<organization-id-from-above>',
         'admin',
         au.email,
         'Your Name'
       FROM auth.users au
       WHERE au.email = 'your-email@example.com';
       ```
   
   - **See `supabase/seed_users.sql`** for detailed instructions on creating multiple users

5. **Populate with dummy data (Optional)**
   - After creating your user, run `seed_dummy_data.sql` in Supabase SQL Editor
   - This will create 15 candidates per role with realistic stage events
   - Perfect for testing the dashboard and analytics

6. **Run the development server**
   ```bash
   # Using the helper script (auto-loads nvm)
   ./run.sh npm run dev
   
   # Or manually:
   export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" && nvm use --lts && npm run dev
   ```

7. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Project Structure

```
HireLens/
├── app/                    # Next.js app directory
│   ├── dashboard/         # Dashboard pages
│   ├── login/            # Authentication pages
│   └── layout.tsx        # Root layout
├── components/           # React components
│   ├── DashboardLayout.tsx
│   ├── CandidateCard.tsx
│   ├── StageColumn.tsx
│   ├── MoveStageModal.tsx
│   └── CreateCandidateModal.tsx
├── lib/                  # Utilities and types
│   ├── supabase/        # Supabase client setup
│   └── types.ts         # TypeScript types
├── supabase/            # Database setup files
│   ├── schema.sql       # Table definitions
│   ├── rls.sql          # Row Level Security policies
│   ├── views.sql        # Analytics views
│   ├── seed.sql         # Sample organizations and roles
│   ├── seed_users.sql   # Dummy users setup with auto-link trigger
│   ├── seed_dummy_data.sql  # Populate dashboard (15 candidates per role)
│   └── fix_existing_user.sql  # Helper script for existing users
└── README.md
```

## Key Features Explained

### Authentication & User Management

- **Automatic User Creation**: When you sign up, the app automatically creates your user record and assigns you to an organization
- **Auto-Organization Setup**: If no organization exists, one is created automatically
- **Seamless Login**: Login flow handles user setup automatically - no manual database configuration needed
- **Multi-Organization**: Each user belongs to one organization with complete data isolation

### Candidate Pipeline

The hiring pipeline consists of 9 stages:
1. Application Submitted
2. Recruiter Screening
3. Hiring Manager Review
4. Interview Round 1
5. Interview Round 2
6. Offer Extended
7. Offer Accepted
8. Background Check
9. Joined

Every stage movement requires:
- **Action Type**: Advance, Reject, or Withdraw
- **Reason Code**: Compensation mismatch, Role mismatch, Interview feedback, etc.
- **Reason Text**: Additional details (required for "Other")
- **Event Tracking**: All movements are logged in `candidate_stage_events` table for analytics

### Analytics Dashboards

- **Funnel Analysis**: Bar chart showing candidates at each stage
- **Drop-off Reasons**: Pie chart showing why candidates exit the pipeline
- **Time in Stage**: Line chart showing average time spent in each stage
- **Source Performance**: Horizontal bar chart comparing candidate sources
- **Real-Time Updates**: All analytics update automatically as candidates move through stages

### Security

- Row Level Security (RLS) ensures data isolation per organization
- All queries are automatically scoped to the user's organization
- Role-based access control for different user types

## Customization

### Colors

The color scheme is defined in `tailwind.config.ts`. You can customize:
- `primary`: Main brand color (blue)
- `accent`: Secondary color (purple)
- `success`, `warning`, `danger`: Status colors

### Stages

Modify the `STAGES` array in `lib/types.ts` to customize your pipeline stages.

## Development

```bash
# Run development server (using helper script with nvm)
./run.sh npm run dev

# Or manually with nvm:
export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" && nvm use --lts && npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint code
npm run lint
```

### Troubleshooting

**Login redirects back to login page:**
- Make sure you've run `rls.sql` which includes policies for authenticated users
- Check that your user record exists in the `users` table
- The app will auto-create your user record on first login

**Dashboard shows 307 redirect:**
- This was fixed by converting dashboard to client component
- Make sure you've restarted your dev server after recent changes

**Can't create candidates:**
- Verify RLS policies are set up correctly
- Check that you have a role assigned in the `users` table
- Ensure your organization has roles created (run `seed.sql`)

**Environment variables not loading:**
- Make sure `.env.local` exists (not just `.env.example`)
- Restart your dev server after adding environment variables
- Check that variable names start with `NEXT_PUBLIC_` for client-side access

## Database Schema

See `supabase/README.md` for detailed database documentation.

### Quick Setup Summary

1. **Run SQL files in order:**
   - `schema.sql` → `rls.sql` → `views.sql` → `seed.sql` → `seed_users.sql` (optional) → `seed_dummy_data.sql` (optional)

2. **Key Files:**
   - `seed_dummy_data.sql` - Creates 15 candidates per role with full stage event history
   - `seed_users.sql` - Includes auto-link trigger for seamless user creation
   - `fix_existing_user.sql` - Helper script if you need to manually fix a user record

## Recent Updates

### v1.1 - Latest Changes

- ✅ **Auto-User Creation**: Login flow automatically creates user records and organizations
- ✅ **Client-Side Dashboard**: Converted to client component to prevent redirect loops
- ✅ **Improved RLS Policies**: Added policies for authenticated users to create organizations and user records
- ✅ **Dummy Data Script**: New `seed_dummy_data.sql` to populate dashboard with realistic data
- ✅ **Better Error Handling**: Graceful error pages instead of redirect loops
- ✅ **Fixed Redirect Issues**: Resolved login/dashboard redirect loop problems
- ✅ **Suspense Support**: Fixed Next.js Suspense requirements for `useSearchParams`
- ✅ **Input Styling**: All form inputs now have proper text color (black) for better visibility

## Populating Test Data

To quickly populate your dashboard with realistic data for testing:

1. **Run the dummy data script:**
   ```sql
   -- In Supabase SQL Editor, run:
   -- supabase/seed_dummy_data.sql
   ```

2. **What it creates:**
   - 15 candidates for each role in your organization
   - Candidates distributed across all 9 pipeline stages
   - Complete stage event history for each candidate
   - Realistic names, emails, sources, and locations
   - Mix of active, rejected, withdrawn, and hired candidates
   - Data spread over the last 90 days

3. **Verification:**
   The script includes queries at the end to verify the data was created correctly.

## Future Enhancements

- Automated email notifications
- ATS integrations
- Resume parsing
- AI-powered candidate recommendations
- Predictive drop-off risk analysis
- Interviewer scorecards
- SLA alerts
- Drag-and-drop Kanban board interactions

## License

MIT

## Support

For issues or questions, please open an issue on the repository.

