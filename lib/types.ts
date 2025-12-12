export type UserRole = 'recruiter' | 'admin' | 'manager'
export type ActionType = 'advance' | 'reject' | 'withdraw'
export type CandidateStatus = 'active' | 'rejected' | 'withdrawn' | 'hired'

export const STAGES = [
  'Application Submitted',
  'Recruiter Screening',
  'Hiring Manager Review',
  'Interview Round 1',
  'Interview Round 2',
  'Offer Extended',
  'Offer Accepted',
  'Background Check',
  'Joined',
] as const

export type Stage = typeof STAGES[number]

export const REASON_CODES = [
  'Compensation mismatch',
  'Role mismatch',
  'Interview feedback',
  'Candidate withdrew',
  'Ghosted',
  'Failed background check',
  'Other',
] as const

export type ReasonCode = typeof REASON_CODES[number]

export interface Organization {
  organization_id: string
  organization_name: string
  created_at: string
  updated_at: string
}

export interface User {
  user_id: string
  organization_id: string
  role: UserRole
  email: string
  full_name: string | null
  created_at: string
  updated_at: string
}

export interface Role {
  role_id: string
  organization_id: string
  role_name: string
  department: string | null
  seniority: string | null
  created_at: string
  updated_at: string
}

export interface Candidate {
  candidate_id: string
  organization_id: string
  role_id: string | null
  recruiter_id: string | null
  source: string | null
  location: string | null
  current_stage: Stage
  status: CandidateStatus
  first_name: string
  last_name: string
  email: string | null
  phone: string | null
  created_at: string
  updated_at: string
}

export interface CandidateStageEvent {
  event_id: string
  candidate_id: string
  organization_id: string
  from_stage: Stage | null
  to_stage: Stage
  action_type: ActionType
  reason_code: ReasonCode
  reason_text: string | null
  moved_by: string
  moved_at: string
}

