'use client'

import { useState, useEffect, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import StageColumn from '@/components/StageColumn'
import MoveStageModal from '@/components/MoveStageModal'
import CreateCandidateModal from '@/components/CreateCandidateModal'
import { STAGES, type Candidate, type Stage, type ActionType, type ReasonCode } from '@/lib/types'

function CandidatesContent() {
  const [candidates, setCandidates] = useState<Candidate[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCandidate, setSelectedCandidate] = useState<Candidate | null>(null)
  const [showMoveModal, setShowMoveModal] = useState(false)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const router = useRouter()
  const searchParams = useSearchParams()
  const supabase = createClient()

  useEffect(() => {
    loadCandidates()
    if (searchParams.get('action') === 'create') {
      setShowCreateModal(true)
    }
  }, [searchParams])

  async function loadCandidates() {
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

      const { data, error } = await supabase
        .from('candidates')
        .select('*')
        .eq('organization_id', user.organization_id)
        .order('created_at', { ascending: false })

      if (error) throw error
      if (data) setCandidates(data)
    } catch (error) {
      console.error('Error loading candidates:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleMoveCandidate = (candidateId: string) => {
    const candidate = candidates.find(c => c.candidate_id === candidateId)
    if (candidate) {
      setSelectedCandidate(candidate)
      setShowMoveModal(true)
    }
  }

  const handleConfirmMove = async (
    toStage: Stage,
    actionType: ActionType,
    reasonCode: ReasonCode,
    reasonText: string
  ) => {
    if (!selectedCandidate) return

    try {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (!authUser) return

      const { data: user } = await supabase
        .from('users')
        .select('*')
        .eq('user_id', authUser.id)
        .single()

      if (!user) return

      // Create stage event
      const { error: eventError } = await supabase
        .from('candidate_stage_events')
        .insert({
          candidate_id: selectedCandidate.candidate_id,
          organization_id: user.organization_id,
          from_stage: selectedCandidate.current_stage,
          to_stage: toStage,
          action_type: actionType,
          reason_code: reasonCode,
          reason_text: reasonCode === 'Other' ? reasonText : null,
          moved_by: authUser.id,
        })

      if (eventError) throw eventError

      // Update candidate stage and status
      let newStatus = selectedCandidate.status
      if (actionType === 'reject') newStatus = 'rejected'
      else if (actionType === 'withdraw') newStatus = 'withdrawn'
      else if (toStage === 'Joined') newStatus = 'hired'

      const { error: updateError } = await supabase
        .from('candidates')
        .update({
          current_stage: toStage,
          status: newStatus,
        })
        .eq('candidate_id', selectedCandidate.candidate_id)

      if (updateError) throw updateError

      // Reload candidates
      await loadCandidates()
      setShowMoveModal(false)
      setSelectedCandidate(null)
    } catch (error) {
      console.error('Error moving candidate:', error)
      throw error
    }
  }

  const handleCreateCandidate = async () => {
    await loadCandidates()
    setShowCreateModal(false)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading candidates...</div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Candidates</h1>
          <p className="mt-2 text-gray-600">Manage your hiring pipeline</p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="px-6 py-3 bg-gradient-to-r from-primary-600 to-accent-600 text-white rounded-lg font-medium hover:from-primary-700 hover:to-accent-700 transition shadow-lg shadow-primary-500/30"
        >
          Add Candidate
        </button>
      </div>

      {/* Kanban Board */}
      <div className="overflow-x-auto pb-4 -mx-4 px-4 lg:mx-0 lg:px-0">
        <div className="flex space-x-4 min-w-max">
          {STAGES.map((stage) => (
            <StageColumn
              key={stage}
              stage={stage}
              candidates={candidates}
              onMoveCandidate={handleMoveCandidate}
              onCreateCandidate={stage === 'Application Submitted' ? () => setShowCreateModal(true) : undefined}
            />
          ))}
        </div>
      </div>

      {selectedCandidate && (
        <MoveStageModal
          isOpen={showMoveModal}
          onClose={() => {
            setShowMoveModal(false)
            setSelectedCandidate(null)
          }}
          currentStage={selectedCandidate.current_stage}
          candidateName={`${selectedCandidate.first_name} ${selectedCandidate.last_name}`}
          onConfirm={handleConfirmMove}
        />
      )}

      <CreateCandidateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSuccess={handleCreateCandidate}
      />
    </div>
  )
}

export default function CandidatesPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-64"><div className="text-gray-500">Loading...</div></div>}>
      <CandidatesContent />
    </Suspense>
  )
}

