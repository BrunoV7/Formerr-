import api from '../lib/api'
import axios from 'axios'
import { User, Form, DashboardStats, FormPublic, ResponseSession, ResponseDetail, CreateFormRequest, CreateSectionRequest, SubmitFormRequest } from '@/types'

// Auth services
export const authService = {
  getCurrentUser: async (): Promise<User> => {
    const response = await api.get('/auth/me')
    // O backend retorna { user: {...}, authenticated: true, ... }
    // Precisamos extrair apenas o objeto user
    return response.data.user
  },

  redirectToGitHub: () => {
    window.location.href = `${process.env.NEXT_PUBLIC_API_URL}/auth/github`
  }
}

// Dashboard services
export const dashboardService = {
  getStats: async (): Promise<DashboardStats> => {
    const response = await api.get('/dashboard/stats')
    return response.data
  },

  getForms: async (): Promise<Form[]> => {
    const response = await api.get('/dashboard/forms')
    return response.data
  },

  deleteForm: async (formId: string): Promise<{ message: string }> => {
    const response = await api.delete(`/forms/${formId}`)
    return response.data
  }
}

// Forms services
export const formsService = {
  create: async (data: CreateFormRequest): Promise<{ formId: string }> => {
    const response = await api.post('/forms', data)
    return response.data
  },

  getForm: async (formId: string): Promise<Form> => {
    const response = await api.get(`/forms/${formId}`)
    return response.data
  },

  getSections: async (formId: string): Promise<{ form_id: string; sections: any[] }> => {
    const response = await api.get(`/forms/${formId}/sections`)
    return response.data
  },

  getSection: async (sectionId: string): Promise<any> => {
    const response = await api.get(`/sections/${sectionId}`)
    return response.data
  },

  createSection: async (formId: string, data: CreateSectionRequest): Promise<{ sectionId: string }> => {
    const response = await api.post(`/forms/${formId}/sections`, data)
    return response.data
  },

  updateSection: async (sectionId: string, data: any): Promise<{ message: string }> => {
    const response = await api.put(`/sections/${sectionId}`, data)
    return response.data
  },

  deleteSection: async (sectionId: string): Promise<{ message: string }> => {
    const response = await api.delete(`/sections/${sectionId}`)
    return response.data
  },

  publish: async (formId: string, data: { status: string }): Promise<{ message: string }> => {
    const response = await api.put(`/forms/${formId}/publish`, data)
    return response.data
  },

  getPublic: async (formId: string): Promise<FormPublic> => {
    // Criar uma instância separada do axios sem autenticação para acesso público
    const publicApi = axios.create({
      baseURL: api.defaults.baseURL,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const response = await publicApi.get(`/forms/${formId}/public`)
    return response.data
  },

  getResponses: async (formId: string): Promise<ResponseSession[]> => {
    const response = await api.get(`/forms/${formId}/responses`)
    return response.data
  },

  submitResponse: async (formId: string, data: SubmitFormRequest): Promise<{ session_id: string; submitted_at: string }> => {
    // Criar uma instância separada do axios sem autenticação para submissão pública
    const publicApi = axios.create({
      baseURL: api.defaults.baseURL,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const response = await publicApi.post(`/forms/${formId}/submit`, data)
    return response.data
  },

  // Update form basic info
  updateForm: async (formId: string, data: { title?: string; description?: string; status?: string }): Promise<{ message: string }> => {
    const response = await api.put(`/forms/${formId}`, data)
    return response.data
  },

  // Get analytics
  getAnalytics: async (formId: string): Promise<any> => {
    const response = await api.get(`/forms/${formId}/analytics`)
    return response.data
  },

  // Get response detail
  getResponseDetail: async (sessionId: string): Promise<any> => {
    const response = await api.get(`/responses/${sessionId}`)
    return response.data
  },

  // Update section order
  updateSectionOrder: async (formId: string, sectionId: string, newOrder: number): Promise<{ message: string }> => {
    const response = await api.put(`/sections/${sectionId}`, { order: newOrder })
    return response.data
  }
}

// Response services
export const responseService = {
  getDetail: async (sessionId: string): Promise<ResponseDetail> => {
    const response = await api.get(`/responses/${sessionId}`)
    return response.data
  }
}
