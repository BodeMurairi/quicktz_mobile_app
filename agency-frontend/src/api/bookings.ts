import { apiClient } from './client'
import type { Booking, BookingCreate, BookingStatus } from '../types'

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

  // Agency dashboard: paginated + filtered transactions, with the total count read
  // off the X-Total-Count response header (see backend/controller/bookings.py).
  listTransactions: async (params: {
    agency_id: string
    status?: string
    payment_method?: string
    from_date?: string
    to_date?: string
    page?: number
    size?: number
  }): Promise<{ items: Booking[]; total: number }> => {
    const { data, headers } = await apiClient.get<Booking[]>('/bookings', { params })
    const total = Number(headers['x-total-count'] ?? data.length)
    return { items: data, total }
  },

  updateTransactionStatus: async (
    id: string,
    agencyId: string,
    status: Extract<BookingStatus, 'cancelled' | 'completed'>
  ): Promise<Booking> => {
    const { data } = await apiClient.patch<Booking>(`/bookings/${id}/status`, { agency_id: agencyId, status })
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
