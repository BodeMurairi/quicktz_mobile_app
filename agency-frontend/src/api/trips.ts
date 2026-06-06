import { apiClient } from './client'
import type { Trip, TripCreate, TripUpdate } from '../types'

export const tripApi = {
  list: async (params?: {
    agency_id?: string
    route_id?: string
    status?: string
    from_date?: string
    to_date?: string
  }): Promise<Trip[]> => {
    const { data } = await apiClient.get<Trip[]>('/trips', { params })
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
