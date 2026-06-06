import { apiClient } from './client'
import type { Booking, BookingCreate } from '../types'

export const bookingApi = {
  list: async (params?: {
    agency_id?: string
    trip_id?: string
    status?: string
    from_date?: string
    to_date?: string
  }): Promise<Booking[]> => {
    const { data } = await apiClient.get<Booking[]>('/bookings', { params })
    return data
  },

  get: async (id: string): Promise<Booking> => {
    const { data } = await apiClient.get<Booking>(`/bookings/${id}`)
    return data
  },

  create: async (payload: BookingCreate): Promise<Booking> => {
    const { data } = await apiClient.post<Booking>('/bookings', payload)
    return data
  },

  cancel: async (id: string): Promise<Booking> => {
    const { data } = await apiClient.patch<Booking>(`/bookings/${id}/cancel`)
    return data
  },

  confirm: async (id: string): Promise<Booking> => {
    const { data } = await apiClient.patch<Booking>(`/bookings/${id}/confirm`)
    return data
  },
}
