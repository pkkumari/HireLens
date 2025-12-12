import DashboardPageClient from './page-client'

export default function DashboardPage() {
  return <DashboardPageClient />
}

// OLD SERVER COMPONENT CODE - Keeping for reference but using client component to avoid redirect loops
/*
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Users, TrendingUp, Clock, Target } from 'lucide-react'

export default async function DashboardPage() {
  try {
    const supabase = await createClient()
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()

    console.log('Dashboard: Auth check', { hasUser: !!authUser, error: authError?.message })

    if (authError) {
      console.error('Auth error:', authError)
      redirect('/login')
    }

    if (!authUser) {
      console.log('No auth user, redirecting to login')
      redirect('/login')
    }

  let user = null
  const { data: userData, error: userError } = await supabase
    .from('users')
    .select('*')
    .eq('user_id', authUser.id)
    .single()

  user = userData

  // If user doesn't exist, try to create it automatically
  if (!user && userError?.code === 'PGRST116') {
    // Get or create organization
    const { data: org } = await supabase
      .from('organizations')
      .select('organization_id')
      .order('created_at')
      .limit(1)
      .maybeSingle()

    let orgId = org?.organization_id

    if (!orgId) {
      const { data: newOrg } = await supabase
        .from('organizations')
        .insert({ organization_name: 'My Organization' })
        .select('organization_id')
        .single()
      orgId = newOrg?.organization_id
    }

    if (orgId) {
      const { data: newUser } = await supabase
        .from('users')
        .insert({
          user_id: authUser.id,
          organization_id: orgId,
          role: 'recruiter',
          email: authUser.email || '',
          full_name: authUser.user_metadata?.full_name || authUser.email?.split('@')[0] || 'User',
        })
        .select()
        .single()

      if (newUser) {
        user = newUser
      }
    }
  }

  if (!user) {
    // User record doesn't exist - try one more time to fetch it (might be a timing issue)
    console.warn('User record not found, retrying...')
    const { data: retryUser } = await supabase
      .from('users')
      .select('*')
      .eq('user_id', authUser.id)
      .single()
    
    if (retryUser) {
      user = retryUser
      console.log('User record found on retry')
    } else {
      // If still no user, show an error page instead of redirecting (to prevent loop)
      console.error('User record not found after auto-create attempt and retry')
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white rounded-xl shadow-lg p-8">
            <h1 className="text-2xl font-bold text-gray-900 mb-4">Setup Required</h1>
            <p className="text-gray-600 mb-6">
              Your account needs to be set up. Please contact support or try logging out and back in.
            </p>
            <a
              href="/login"
              className="block w-full text-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition"
            >
              Go to Login
            </a>
          </div>
        </div>
      )
    }
  }

  // Fetch key metrics
  const { data: candidates } = await supabase
    .from('candidates')
    .select('candidate_id, status, current_stage')
    .eq('organization_id', user.organization_id)

  const { data: events } = await supabase
    .from('candidate_stage_events')
    .select('event_id, action_type')
    .eq('organization_id', user.organization_id)
    .gte('moved_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())

  const totalCandidates = candidates?.length || 0
  const activeCandidates = candidates?.filter(c => c.status === 'active').length || 0
  const hiredCandidates = candidates?.filter(c => c.status === 'hired').length || 0
  const recentActivity = events?.length || 0

  const stats = [
    {
      name: 'Total Candidates',
      value: totalCandidates,
      icon: Users,
      color: 'primary',
    },
    {
      name: 'Active Pipeline',
      value: activeCandidates,
      icon: TrendingUp,
      color: 'accent',
    },
    {
      name: 'Hired',
      value: hiredCandidates,
      icon: Target,
      color: 'success',
    },
    {
      name: 'Activity (30d)',
      value: recentActivity,
      icon: Clock,
      color: 'warning',
    },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">Welcome back! Here's your hiring overview.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon
          const colorClasses = {
            primary: 'bg-primary-500',
            accent: 'bg-accent-500',
            success: 'bg-success-500',
            warning: 'bg-warning-500',
          }
          return (
            <div
              key={stat.name}
              className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="mt-2 text-3xl font-bold text-gray-900">{stat.value}</p>
                </div>
                <div className={`${colorClasses[stat.color as keyof typeof colorClasses]} p-3 rounded-lg`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
              </div>
            </div>
          )
        })}
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <a
            href="/dashboard/candidates"
            className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-primary-500 hover:bg-primary-50 transition text-center"
          >
            <Users className="w-8 h-8 mx-auto mb-2 text-gray-400" />
            <p className="font-medium text-gray-700">Manage Candidates</p>
          </a>
          <a
            href="/dashboard/analytics"
            className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-accent-500 hover:bg-accent-50 transition text-center"
          >
            <TrendingUp className="w-8 h-8 mx-auto mb-2 text-gray-400" />
            <p className="font-medium text-gray-700">View Analytics</p>
          </a>
          <a
            href="/dashboard/candidates?action=create"
            className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-success-500 hover:bg-success-50 transition text-center"
          >
            <Target className="w-8 h-8 mx-auto mb-2 text-gray-400" />
            <p className="font-medium text-gray-700">Add Candidate</p>
          </a>
        </div>
      </div>
    </div>
  )
  } catch (error) {
    console.error('Dashboard error:', error)
    redirect('/login?error=dashboard_error')
  }
}
*/

