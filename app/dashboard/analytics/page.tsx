'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from 'recharts'
import { TrendingUp, Users, Clock, Target } from 'lucide-react'

const COLORS = ['#0ea5e9', '#d946ef', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6']

export default function AnalyticsPage() {
  const [loading, setLoading] = useState(true)
  const [funnelData, setFunnelData] = useState<any[]>([])
  const [dropoffData, setDropoffData] = useState<any[]>([])
  const [timeData, setTimeData] = useState<any[]>([])
  const [sourceData, setSourceData] = useState<any[]>([])
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    loadAnalytics()
  }, [])

  async function loadAnalytics() {
    try {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (!authUser) {
        router.push('/login')
        return
      }

      const { data: user } = await supabase
        .from('users')
        .select('*')
        .eq('user_id', authUser.id)
        .single()

      if (!user) return

      // Load funnel data
      const { data: funnel } = await supabase
        .from('candidate_stage_events')
        .select('to_stage')
        .eq('organization_id', user.organization_id)

      if (funnel) {
        const stageCounts: Record<string, number> = {}
        funnel.forEach(event => {
          stageCounts[event.to_stage] = (stageCounts[event.to_stage] || 0) + 1
        })
        setFunnelData(Object.entries(stageCounts).map(([stage, count]) => ({ stage, count })))
      }

      // Load dropoff data
      const { data: dropoffs } = await supabase
        .from('candidate_stage_events')
        .select('to_stage, reason_code, action_type')
        .eq('organization_id', user.organization_id)
        .in('action_type', ['reject', 'withdraw'])

      if (dropoffs) {
        const reasonCounts: Record<string, number> = {}
        dropoffs.forEach(event => {
          reasonCounts[event.reason_code] = (reasonCounts[event.reason_code] || 0) + 1
        })
        setDropoffData(Object.entries(reasonCounts).map(([reason, count]) => ({ reason, count })))
      }

      // Load source performance
      const { data: candidates } = await supabase
        .from('candidates')
        .select('source, status')
        .eq('organization_id', user.organization_id)

      if (candidates) {
        const sourceStats: Record<string, { total: number; hired: number }> = {}
        candidates.forEach(c => {
          if (!c.source) return
          if (!sourceStats[c.source]) {
            sourceStats[c.source] = { total: 0, hired: 0 }
          }
          sourceStats[c.source].total++
          if (c.status === 'hired') {
            sourceStats[c.source].hired++
          }
        })
        setSourceData(Object.entries(sourceStats).map(([source, stats]) => ({
          source,
          total: stats.total,
          hired: stats.hired,
          rate: stats.total > 0 ? Math.round((stats.hired / stats.total) * 100) : 0,
        })))
      }

      // Mock time data (in production, use the time_in_stage view)
      setTimeData([
        { stage: 'Application Submitted', avgDays: 2.5 },
        { stage: 'Recruiter Screening', avgDays: 5.2 },
        { stage: 'Hiring Manager Review', avgDays: 3.8 },
        { stage: 'Interview Round 1', avgDays: 7.1 },
        { stage: 'Interview Round 2', avgDays: 6.5 },
        { stage: 'Offer Extended', avgDays: 4.2 },
      ])
    } catch (error) {
      console.error('Error loading analytics:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading analytics...</div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <p className="mt-2 text-gray-600">Real-time insights into your hiring pipeline</p>
      </div>

      {/* Funnel Analysis */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Funnel Analysis</h2>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart data={funnelData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="stage" angle={-45} textAnchor="end" height={100} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="count" fill="#0ea5e9" name="Candidates" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Drop-off Reasons */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Drop-off Reasons</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={dropoffData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ reason, percent }) => `${reason}: ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="count"
              >
                {dropoffData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Source Performance */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Source Performance</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={sourceData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis type="number" />
              <YAxis dataKey="source" type="category" width={100} />
              <Tooltip />
              <Legend />
              <Bar dataKey="total" fill="#0ea5e9" name="Total" />
              <Bar dataKey="hired" fill="#22c55e" name="Hired" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Time in Stage */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Average Time in Stage</h2>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={timeData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="stage" angle={-45} textAnchor="end" height={100} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line type="monotone" dataKey="avgDays" stroke="#d946ef" name="Avg Days" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

