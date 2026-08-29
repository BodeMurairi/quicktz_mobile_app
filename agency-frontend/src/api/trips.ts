import { apiClient } from './client'
import type { Trip, TripCreate, TripUpdate } from '../types'

export const tripApi = {
  // Agency dashboard: every trip for this agency, any status — requires that
  // agency's own login. Without agency_id, hits the public rider-facing feed.
  list: async (params?: {
    agency_id?: string
    route_id?: string
    status?: string
    from_date?: string
    to_date?: string
  }): Promise<Trip[]> => {
    const { agency_id, ...rest } = params ?? {}
    const url = agency_id ? `/agencies/${agency_id}/trips` : '/trips'
    const { data } = await apiClient.get<Trip[]>(url, { params: rest })
    return data
  },

  get: async (id: string): Promise<Trip> => {
    const { data } = await apiClient.get<Trip>(`/trips/${id}`)
    return data
  },

  create: async (payload: TripCreate): Promise<Trip> => {
    const { data } = await apiClient.post<Trip>('/trips', payload)
    return data
  },

  update: async (id: string, payload: TripUpdate): Promise<Trip> => {
    const { data } = await apiClient.patch<Trip>(`/trips/${id}`, payload)
    return data
  },

  remove: async (id: string): Promise<void> => {
    await apiClient.delete(`/trips/${id}`)
  },

  updateStatus: async (id: string, status: Trip['status']): Promise<Trip> => {
    const { data } = await apiClient.patch<Trip>(`/trips/${id}`, { status })
    return data
  },
}
