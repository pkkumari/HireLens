'use client'

import { useState } from 'react'
import { MoreVertical, Mail, Phone, MapPin } from 'lucide-react'
import type { Candidate } from '@/lib/types'

interface CandidateCardProps {
  candidate: Candidate
  onMove: (candidateId: string) => void
}

export default function CandidateCard({ candidate, onMove }: CandidateCardProps) {
  const [showMenu, setShowMenu] = useState(false)

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition cursor-pointer group">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <h3 className="font-semibold text-gray-900">
            {candidate.first_name} {candidate.last_name}
          </h3>
          {candidate.email && (
            <div className="flex items-center space-x-1 text-sm text-gray-500 mt-1">
              <Mail className="w-3 h-3" />
              <span className="truncate">{candidate.email}</span>
            </div>
          )}
        </div>
        <button
          onClick={(e) => {
            e.stopPropagation()
            setShowMenu(!showMenu)
          }}
          className="opacity-0 group-hover:opacity-100 transition p-1 hover:bg-gray-100 rounded"
        >
          <MoreVertical className="w-4 h-4 text-gray-400" />
        </button>
      </div>

      <div className="space-y-2 text-sm">
        {candidate.location && (
          <div className="flex items-center space-x-1 text-gray-600">
            <MapPin className="w-3 h-3" />
            <span>{candidate.location}</span>
          </div>
        )}
        {candidate.phone && (
          <div className="flex items-center space-x-1 text-gray-600">
            <Phone className="w-3 h-3" />
            <span>{candidate.phone}</span>
          </div>
        )}
        {candidate.source && (
          <div className="inline-block px-2 py-1 bg-gray-100 rounded text-xs text-gray-600">
            {candidate.source}
          </div>
        )}
      </div>

      <button
        onClick={() => onMove(candidate.candidate_id)}
        className="mt-4 w-full py-2 bg-primary-50 text-primary-700 rounded-lg font-medium hover:bg-primary-100 transition text-sm"
      >
        Move Stage
      </button>
    </div>
  )
}

