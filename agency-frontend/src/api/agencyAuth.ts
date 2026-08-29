import { apiClient } from './client'
import type { AuthResponse, Agency, AgencyLoginRequest, AgencyRegisterRequest } from '../types'

export const agencyAuthApi = {
  login: async (data: AgencyLoginRequest): Promise<AuthResponse> => {
    const { data: res } = await apiClient.post<AuthResponse>('/agency-auth/login', data)
    return res
  },

  register: async (data: AgencyRegisterRequest): Promise<AuthResponse> => {
    const { data: res } = await apiClient.post<AuthResponse>('/agency-auth/register', data)
    return res
  },

  me: async (): Promise<Agency> => {
    const { data } = await apiClient.get<Agency>('/agency-auth/me')
    return data
  },

  forgotPassword: async (loginEmail: string): Promise<void> => {
    await apiClient.post('/agency-auth/forgot-password', { login_email: loginEmail })
  },

  resetPassword: async (loginEmail: string, code: string, newPassword: string): Promise<void> => {
    await apiClient.post('/agency-auth/reset-password', {
      login_email: loginEmail,
      code,
      new_password: newPassword,
    })
  },
}
