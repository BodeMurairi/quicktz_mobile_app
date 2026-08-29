import { apiClient, BASE_URL } from './client'
import type { Booking, BookingCreate, BookingStatus, ChatMessage } from '../types'

export const bookingApi = {
  // Agency dashboard: every booking for this agency (unpaginated). Requires that
  // agency's own login — see GET /agencies/{agency_id}/bookings.
  list: async (params: {
    agency_id: string
    status?: string
    from_date?: string
    to_date?: string
  }): Promise<Booking[]> => {
    const { agency_id, ...rest } = params
    const { data } = await apiClient.get<Booking[]>(`/agencies/${agency_id}/bookings`, { params: rest })
    return data
  },

  // Agency dashboard: paginated + filtered transactions, with the total count read
  // off the X-Total-Count response header (see backend/controller/agencies.py).
  listTransactions: async (params: {
    agency_id: string
    status?: string
    payment_method?: string
    from_date?: string
    to_date?: string
    passenger_phone?: string
    page?: number
    size?: number
  }): Promise<{ items: Booking[]; total: number }> => {
    const { agency_id, ...rest } = params
    const { data, headers } = await apiClient.get<Booking[]>(`/agencies/${agency_id}/bookings`, { params: rest })
    const total = Number(headers['x-total-count'] ?? data.length)
    return { items: data, total }
  },

  updateTransactionStatus: async (
    id: string,
    _agencyId: string,
    status: Extract<BookingStatus, 'cancelled' | 'completed'>
  ): Promise<Booking> => {
    const { data } = await apiClient.patch<Booking>(`/bookings/${id}/status`, { status })
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

  // Agency dashboard's manual booking. If the passenger's phone matches a real
  // rider account, the booking comes back `pending_approval` — the rider must
  // confirm + pay in the app before a ticket exists. Otherwise it's an
  // accountless walk-in and comes back instant-confirmed, same as before.
  createManual: async (agencyId: string, payload: BookingCreate): Promise<Booking> => {
    const { data } = await apiClient.post<Booking>('/bookings/manual', { agency_id: agencyId, ...payload })
    return data
  },

  ticketPdfUrl: (bookingId: string): string => `${BASE_URL}/bookings/${bookingId}/ticket.pdf`,

  sendTicketMessage: async (bookingId: string, agencyId: string): Promise<ChatMessage> => {
    const { data } = await apiClient.post<ChatMessage>(`/bookings/${bookingId}/send-ticket-message`, {
      agency_id: agencyId,
    })
    return data
  },

  sendTicketEmail: async (
    bookingId: string,
    agencyId: string,
    payload: { to: string; subject: string; body: string }
  ): Promise<void> => {
    await apiClient.post(`/bookings/${bookingId}/send-ticket-email`, { agency_id: agencyId, ...payload })
  },
}
