# Authentication Architecture

## How Authentication Works in HireLens

HireLens uses **Supabase Auth** for authentication, which is a separate system from your application database. Here's how it works:

### Two-Table System

1. **`auth.users` (Supabase Managed)**
   - Managed by Supabase Auth
   - Stores: `id`, `email`, `encrypted_password`, `email_confirmed_at`, etc.
   - **Passwords are stored here** (encrypted/hashed)
   - You cannot directly query or modify this table
   - Accessible via Supabase Auth API

2. **`users` (Your Application Table)**
   - Your custom table for application data
   - Stores: `user_id` (references `auth.users.id`), `organization_id`, `role`, `full_name`, etc.
   - **Passwords are NOT stored here**
   - Links to `auth.users` via foreign key

### Authentication Flow

#### Login Process:
```
User enters email + password
    ↓
supabase.auth.signInWithPassword({ email, password })
    ↓
Supabase Auth checks auth.users table
    ↓
If valid → Returns JWT token + user data
    ↓
App uses user.id to query your users table for organization/role
```

#### Signup Process:
```
User enters email + password + name
    ↓
supabase.auth.signUp({ email, password })
    ↓
Supabase Auth creates record in auth.users (stores password)
    ↓
Trigger function (handle_new_user) creates record in users table
    ↓
User is linked to organization with default role
```

### Why This Design?

**Security Benefits:**
- Passwords are handled by Supabase (industry-standard security)
- Passwords are encrypted/hashed automatically
- You never handle raw passwords in your code
- Supabase handles password reset, email verification, etc.

**Separation of Concerns:**
- Authentication data (passwords) → Supabase Auth
- Application data (org, role) → Your database
- Clean separation makes the system more maintainable

### Accessing User Data

```typescript
// Get authenticated user (from Supabase Auth)
const { data: { user: authUser } } = await supabase.auth.getUser()

// Get application user data (from your users table)
const { data: appUser } = await supabase
  .from('users')
  .select('*')
  .eq('user_id', authUser.id)
  .single()

// Now you have:
// - authUser.email (from auth.users)
// - appUser.organization_id (from users table)
// - appUser.role (from users table)
```

### Creating Users

**Option 1: Via Supabase Dashboard**
- Go to Authentication → Users → Add User
- Enter email and password
- Supabase creates record in `auth.users`
- Your trigger creates record in `users` table

**Option 2: Via API (Signup)**
```typescript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securepassword123'
})
// Trigger automatically creates users table record
```

**Option 3: Via Admin API**
```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/admin/users' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

### Important Notes

- ✅ **Never store passwords** in your `users` table
- ✅ **Always use Supabase Auth** for authentication
- ✅ **Use the trigger function** to auto-create user records
- ❌ **Don't try to query auth.users directly** - use Supabase Auth API
- ❌ **Don't manually insert passwords** - let Supabase handle it

### Password Reset

Supabase Auth handles password reset automatically:
- User requests reset → Supabase sends email
- User clicks link → Supabase handles password change
- No code needed in your application!

### Summary

- **Passwords** → Stored in `auth.users` (Supabase managed)
- **User data** → Stored in `users` table (your application)
- **Authentication** → Handled by Supabase Auth
- **Your app** → Just uses the authenticated user's ID to fetch application data

This is a standard, secure pattern used by modern applications!

