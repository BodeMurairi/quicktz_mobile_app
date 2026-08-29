import { apiClient } from './client'
import type { Agency, AgencyCreate } from '../types'

export const agencyApi = {
  get: async (id: string): Promise<Agency> => {
    const { data } = await apiClient.get<Agency>(`/agencies/${id}`)
    return data
  },

  update: async (id: string, payload: Partial<AgencyCreate>): Promise<Agency> => {
    const { data } = await apiClient.patch<Agency>(`/agencies/${id}`, payload)
    return data
  },
}
