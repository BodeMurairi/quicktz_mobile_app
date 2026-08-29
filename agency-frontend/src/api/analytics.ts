import { apiClient } from './client'
import type { DashboardStats, FinanceSummary } from '../types'

export const analyticsApi = {
  dashboard: async (agencyId: string): Promise<DashboardStats> => {
    const { data } = await apiClient.get<DashboardStats>(`/agencies/${agencyId}/analytics/dashboard`)
    return data
  },

  finance: async (
    agencyId: string,
    period: 'weekly' | 'monthly' | 'quarterly' | 'yearly' = 'monthly'
  ): Promise<FinanceSummary> => {
    const { data } = await apiClient.get<FinanceSummary>(`/agencies/${agencyId}/analytics/finance`, {
      params: { period },
    })
    return data
  },
}
