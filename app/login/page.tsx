'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import Link from 'next/link'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()
  
  // Initialize supabase client
  const supabase = createClient()
  
  // Reset loading state on mount (in case it got stuck from previous session)
  useEffect(() => {
    setLoading(false)
    setError(null)
  }, [])

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    e.stopPropagation()
    
    console.log('Login form submitted', { 
      email: email ? 'provided' : 'missing', 
      password: password ? 'provided' : 'missing',
      loading,
      supabaseInitialized: !!supabase
    })
    
    // Validate inputs
    if (!email || !password) {
      setError('Please enter both email and password')
      setLoading(false)
      return
    }

    // Check if Supabase client is initialized
    if (!supabase) {
      setError('Supabase client not initialized. Please check your environment variables.')
      setLoading(false)
      return
    }

    setLoading(true)
    setError(null)

    try {

      console.log('Attempting to sign in...')
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      })

      if (authError) {
        console.error('Login error:', authError)
        throw authError
      }

      if (data?.user) {
        console.log('Login successful, user:', data.user.id)
        
        // Check if user exists in users table, create if missing
        try {
          const { data: userData, error: userError } = await supabase
            .from('users')
            .select('*')
            .eq('user_id', data.user.id)
            .single()

          if (userError && userError.code === 'PGRST116') {
            // User doesn't exist in users table, create it
            console.log('User not found in users table, creating record...')
            
            // Get the first organization (or create a default one)
            let organizationId: string | null = null
            
            try {
              const { data: orgs, error: orgSelectError } = await supabase
                .from('organizations')
                .select('organization_id')
                .order('created_at')
                .limit(1)
                .maybeSingle()

              if (!orgSelectError && orgs) {
                organizationId = orgs.organization_id
              }
            } catch (err) {
              console.log('Could not fetch organizations, will create new one')
            }

            // If no organization exists, create a default one
            if (!organizationId) {
              console.log('Creating new organization...')
              const { data: newOrg, error: orgError } = await supabase
                .from('organizations')
                .insert({ organization_name: 'My Organization' })
                .select('organization_id')
                .single()

              if (orgError) {
                console.error('Error creating organization:', orgError)
                // Try to get any organization as fallback
                const { data: fallbackOrg } = await supabase
                  .from('organizations')
                  .select('organization_id')
                  .limit(1)
                  .maybeSingle()
                
                if (fallbackOrg) {
                  organizationId = fallbackOrg.organization_id
                  console.log('Using existing organization as fallback')
                } else {
                  throw new Error(`Failed to set up organization: ${orgError.message}. Please create an organization manually in the database.`)
                }
              } else {
                organizationId = newOrg.organization_id
                console.log('Organization created successfully:', organizationId)
              }
            }

            // Create user record
            const { data: newUser, error: createUserError } = await supabase
              .from('users')
              .insert({
                user_id: data.user.id,
                organization_id: organizationId,
                role: 'recruiter', // Default role
                email: data.user.email || email,
                full_name: data.user.user_metadata?.full_name || data.user.email?.split('@')[0] || 'User',
              })
              .select()
              .single()

            if (createUserError) {
              console.error('Error creating user record:', createUserError)
              throw new Error('Failed to create user profile. Please contact support.')
            }

            console.log('User record created successfully:', newUser)
            
            // Verify the user record was created by fetching it
            const { data: verifyUser } = await supabase
              .from('users')
              .select('*')
              .eq('user_id', data.user.id)
              .single()
            
            if (!verifyUser) {
              console.warn('User record not immediately available, waiting...')
              // Wait a bit for the database to sync
              await new Promise(resolve => setTimeout(resolve, 500))
            }
          } else if (userError) {
            console.warn('Error checking user data:', userError)
          } else {
            console.log('User data found:', userData)
          }
        } catch (userCheckError: any) {
          console.error('Error handling user data:', userCheckError)
          // If it's not a critical error, continue with login
          if (userCheckError.message?.includes('contact support')) {
            throw userCheckError
          }
        }

        // Wait a moment for auth session and user record to be fully established
        console.log('Login successful, waiting for session to establish...')
        await new Promise(resolve => setTimeout(resolve, 500))
        
        // Verify user record exists one more time before redirecting
        const { data: finalUserCheck } = await supabase
          .from('users')
          .select('user_id')
          .eq('user_id', data.user.id)
          .single()
        
        if (!finalUserCheck) {
          console.error('User record still not found after creation, this should not happen')
          setError('User setup incomplete. Please refresh and try again.')
          setLoading(false)
          return
        }
        
        console.log('User record verified, redirecting to dashboard...')
        
        // Set loading to false immediately
        setLoading(false)
        
        // IMMEDIATE redirect - no delays, no async, just go
        console.log('REDIRECTING NOW to /dashboard')
        if (typeof window !== 'undefined') {
          // Use assign which is more reliable than href
          window.location.assign('/dashboard')
        }
        
        // Exit immediately
        return
      } else {
        throw new Error('Login failed. Please try again.')
      }
    } catch (err: any) {
      console.error('Login error:', err)
      const errorMessage = err?.message || err?.error_description || 'An error occurred during login'
      setError(errorMessage)
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 via-white to-accent-50 px-4">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-primary-600 to-accent-600 bg-clip-text text-transparent">
            HireLens
          </h1>
          <p className="mt-2 text-gray-600">Sign in to your account</p>
        </div>
        
        <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
          <form onSubmit={handleLogin} className="space-y-6">
            {error && (
              <div className="bg-danger-50 border border-danger-200 text-danger-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}
            
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition text-gray-900"
                placeholder="you@example.com"
              />
            </div>
            
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent transition text-gray-900"
                placeholder="••••••••"
              />
            </div>
            
            <button
              type="submit"
              disabled={loading}
              onClick={(e) => {
                if (!email || !password) {
                  e.preventDefault()
                  setError('Please enter both email and password')
                }
              }}
              className="w-full bg-gradient-to-r from-primary-600 to-accent-600 text-white py-3 rounded-lg font-medium hover:from-primary-700 hover:to-accent-700 transition disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-primary-500/30"
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </form>
          
          <p className="mt-6 text-center text-sm text-gray-600">
            Don't have an account?{' '}
            <Link href="/signup" className="font-medium text-primary-600 hover:text-primary-700">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

