import { apiClient } from './client'
import type { Agency, AgencyCreate } from '../types'

export const agencyApi = {
  list: async (): Promise<Agency[]> => {
    const { data } = await apiClient.get<Agency[]>('/agencies')
    return data
  },

  get: async (id: string): Promise<Agency> => {
    const { data } = await apiClient.get<Agency>(`/agencies/${id}`)
    return data
  },

  create: async (payload: AgencyCreate): Promise<Agency> => {
    const { data } = await apiClient.post<Agency>('/agencies', payload)
    return data
  },

  update: async (id: string, payload: Partial<AgencyCreate>): Promise<Agency> => {
    const { data } = await apiClient.patch<Agency>(`/agencies/${id}`, payload)
    return data
  },
}
