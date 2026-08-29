import { apiClient } from './client'
import type { Review } from '../types'

export interface RatingSummary {
  agency_id: string
  average_rating: number | null
  review_count: number
}

export const reviewApi = {
  listByAgency: async (agencyId: string): Promise<Review[]> => {
    const { data } = await apiClient.get<Review[]>(`/agencies/${agencyId}/reviews`)
    return data
  },

  ratingSummary: async (agencyId: string): Promise<RatingSummary> => {
    const { data } = await apiClient.get<RatingSummary>(`/agencies/${agencyId}/rating-summary`)
    return data
  },

  reply: async (agencyId: string, reviewId: string, reply: string): Promise<Review> => {
    const { data } = await apiClient.patch<Review>(`/agencies/${agencyId}/reviews/${reviewId}/reply`, { reply })
    return data
  },
}
