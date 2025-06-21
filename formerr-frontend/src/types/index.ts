export interface User {
  github_id: number
  username: string
  name: string
  email: string
  avatar_url: string
  github_url: string
  role: string
  permissions: string[]
  limits: {
    max_forms: number
    max_submissions_per_month: number
    max_questions_per_form: number
    max_file_size_mb: number
  }
  created_at: string
  user_type: string
  sprint_version: string
  is_admin: boolean
}

export interface Form {
  id: string
  title: string
  description?: string
  icon: string
  folder_color: string
  preview_url?: string
  status: 'draft' | 'public' | 'private' | 'archived' | 'closed'
  total_responses: number
  created_at: string
  updated_at: string
}

export interface Question {
  id: string
  type: 'text' | 'email' | 'number' | 'select' | 'textarea' | 'checkbox' | 'radio' | 'short-text' | 'long-text' | 'dropdown' | 'multiple-choice' | 'multiple-selection'
  title: string
  description?: string
  required: boolean
  options?: {
    choices?: string[]
    [key: string]: any
  }
  validation?: Record<string, any>
  order: number
}

export interface Section {
  id: string
  title: string
  description?: string
  order: number
  questions: Question[]
}

export interface FormPublic {
  id: string
  title: string
  description?: string
  status: string
  sections: Section[]
}

export interface DashboardStats {
  total_forms: number
  active_forms: number
  total_responses: number
  responses_this_month: number
  responses_this_week: number
  avg_response_rate: number
  most_popular_form?: {
    id: string
    title: string
    response_count: number
  }
}

export interface ResponseSession {
  id: string
  submitted_at: string
  respondent_email?: string | null
  respondent_ip?: string | null
  user_agent?: string | null
}

export interface ResponseDetail extends ResponseSession {
  answers: {
    question_id: string
    question_title: string
    question_type: string
    value: string
  }[]
}

export interface FormAnalytics {
  total_responses: number
  responses_this_month: number
  responses_this_week: number
  responses_per_question: Array<{
    question_id: string
    title: string
    type: string
    total: number
    distribution?: Record<string, number>
  }>
}

export interface CreateFormRequest {
  title: string
  description?: string
  icon?: string
  folder_color?: string
}

export interface CreateSectionRequest {
  title: string
  description?: string
  order?: number
  questions: Omit<Question, 'id' | 'order'>[]
}

export interface SubmitFormRequest {
  answers: {
    question_id: string
    value: string[]
  }[]
  respondent_email?: string
}
