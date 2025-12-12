'use client'

import { useState } from 'react'
import { X } from 'lucide-react'
import { STAGES, REASON_CODES, type Stage, type ReasonCode, type ActionType } from '@/lib/types'

interface MoveStageModalProps {
  isOpen: boolean
  onClose: () => void
  currentStage: Stage
  candidateName: string
  onConfirm: (toStage: Stage, actionType: ActionType, reasonCode: ReasonCode, reasonText: string) => Promise<void>
}

export default function MoveStageModal({
  isOpen,
  onClose,
  currentStage,
  candidateName,
  onConfirm,
}: MoveStageModalProps) {
  const [toStage, setToStage] = useState<Stage>(STAGES[0])
  const [actionType, setActionType] = useState<ActionType>('advance')
  const [reasonCode, setReasonCode] = useState<ReasonCode>(REASON_CODES[0])
  const [reasonText, setReasonText] = useState('')
  const [loading, setLoading] = useState(false)

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await onConfirm(toStage, actionType, reasonCode, reasonText)
      onClose()
      // Reset form
      setToStage(STAGES[0])
      setActionType('advance')
      setReasonCode(REASON_CODES[0])
      setReasonText('')
    } catch (error) {
      console.error('Error moving candidate:', error)
    } finally {
      setLoading(false)
    }
  }

  const availableStages = STAGES.filter(s => s !== currentStage)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50">
      <div className="bg-white rounded-xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Move Candidate</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div>
            <p className="text-sm text-gray-600 mb-4">
              Moving <span className="font-semibold">{candidateName}</span> from{' '}
              <span className="font-semibold">{currentStage}</span>
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Action Type
            </label>
            <select
              value={actionType}
              onChange={(e) => setActionType(e.target.value as ActionType)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900"
              required
            >
              <option value="advance">Advance</option>
              <option value="reject">Reject</option>
              <option value="withdraw">Withdraw</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              To Stage
            </label>
            <select
              value={toStage}
              onChange={(e) => setToStage(e.target.value as Stage)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900"
              required
            >
              {availableStages.map((stage) => (
                <option key={stage} value={stage}>
                  {stage}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Reason <span className="text-danger-500">*</span>
            </label>
            <select
              value={reasonCode}
              onChange={(e) => setReasonCode(e.target.value as ReasonCode)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent mb-2 text-gray-900"
              required
            >
              {REASON_CODES.map((code) => (
                <option key={code} value={code}>
                  {code}
                </option>
              ))}
            </select>
            {reasonCode === 'Other' && (
              <textarea
                value={reasonText}
                onChange={(e) => setReasonText(e.target.value)}
                placeholder="Please provide details..."
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent mt-2 text-gray-900"
                rows={3}
                required
              />
            )}
          </div>

          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-primary-600 to-accent-600 text-white rounded-lg font-medium hover:from-primary-700 hover:to-accent-700 transition disabled:opacity-50"
            >
              {loading ? 'Moving...' : 'Move Candidate'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

