# Supabase Database Setup for HireLens

This folder contains all the SQL files needed to set up the HireLens database in Supabase.

## Setup Instructions

1. **Create a Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note your project URL and anon key

2. **Run SQL Files in Order**
   - Open the Supabase SQL Editor
   - Run files in this order:
     1. `schema.sql` - Creates all tables, indexes, and triggers
     2. `rls.sql` - Sets up Row Level Security policies
     3. `views.sql` - Creates analytics views
     4. `seed.sql` - (Optional) Adds sample organizations and roles
     5. `seed_users.sql` - (Optional) Creates dummy users and auto-link trigger

3. **Configure Environment Variables**
   - Copy `.env.example` to `.env.local` in the project root
   - Add your Supabase URL and anon key

4. **Create Users**
   - Option A: Use `seed_users.sql` which includes a trigger to auto-create user records
   - Option B: Manually create users via Supabase Auth, then link them in the `users` table
   - See `seed_users.sql` for detailed instructions and dummy user data

## File Descriptions

- **schema.sql**: Core database schema with all tables, indexes, and triggers
- **rls.sql**: Row Level Security policies for multi-tenant data isolation
- **views.sql**: Pre-built analytics views for dashboard queries
- **seed.sql**: Sample organizations and roles for development and testing
- **seed_users.sql**: Dummy users setup with auto-link trigger function

## Database Structure

### Core Tables
- `organizations` - Multi-tenant organization data
- `users` - User accounts linked to organizations
- `roles` - Job roles/positions
- `candidates` - Candidate profiles
- `candidate_stage_events` - Event-sourced stage movement history

### Analytics Views
- `funnel_analytics` - Stage-level candidate counts
- `stage_conversion` - Conversion rates between stages
- `dropoff_reasons` - Drop-off analysis by reason
- `time_in_stage` - Time metrics per stage
- `offer_analytics` - Offer acceptance metrics
- `source_performance` - Source channel performance

## Security

All tables have Row Level Security (RLS) enabled. Users can only access data from their own organization. The `get_user_organization_id()` function is used to enforce this isolation.

