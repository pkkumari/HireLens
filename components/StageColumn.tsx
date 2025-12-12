'use client'

import { useState } from 'react'
import CandidateCard from './CandidateCard'
import { Plus } from 'lucide-react'
import type { Candidate, Stage } from '@/lib/types'

interface StageColumnProps {
  stage: Stage
  candidates: Candidate[]
  onMoveCandidate: (candidateId: string) => void
  onCreateCandidate?: () => void
}

export default function StageColumn({ 
  stage, 
  candidates, 
  onMoveCandidate,
  onCreateCandidate 
}: StageColumnProps) {
  const stageCandidates = candidates.filter(c => c.current_stage === stage)

  return (
    <div className="flex flex-col h-[calc(100vh-12rem)] min-w-[280px] max-w-[320px] lg:min-w-[300px]">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-4 flex-shrink-0">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-semibold text-gray-900 text-sm lg:text-base">{stage}</h3>
          <span className="bg-gray-100 text-gray-600 text-xs font-medium px-2 py-1 rounded-full">
            {stageCandidates.length}
          </span>
        </div>
        {onCreateCandidate && stage === 'Application Submitted' && (
          <button
            onClick={onCreateCandidate}
            className="w-full mt-2 flex items-center justify-center space-x-2 py-2 bg-primary-50 text-primary-700 rounded-lg font-medium hover:bg-primary-100 transition text-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Add Candidate</span>
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto space-y-3 pb-4">
        {stageCandidates.map((candidate) => (
          <CandidateCard
            key={candidate.candidate_id}
            candidate={candidate}
            onMove={onMoveCandidate}
          />
        ))}
        {stageCandidates.length === 0 && (
          <div className="text-center py-8 text-gray-400 text-sm">
            No candidates in this stage
          </div>
        )}
      </div>
    </div>
  )
}

