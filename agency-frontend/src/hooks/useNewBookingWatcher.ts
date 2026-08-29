import { useEffect, useRef } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { bookingApi } from '../api/bookings'
import { useAuth } from '../contexts/AuthContext'
import { useToast } from '../contexts/ToastContext'

// Polls the agency's most recent transaction and pops a toast whenever the total
// booking count increases — mounted once at the layout level so it fires app-wide,
// not just while the Bookings page happens to be open.
export function useNewBookingWatcher() {
  const { agency } = useAuth()
  const toast = useToast()
  const qc = useQueryClient()
  const lastTotal = useRef<number | null>(null)

  const { data } = useQuery({
    queryKey: ['latest-booking-watch', agency?.id],
    queryFn: () => bookingApi.listTransactions({ agency_id: agency!.id, page: 1, size: 1 }),
    enabled: !!agency,
    refetchInterval: 15_000,
  })

  useEffect(() => {
    if (!data) return
    if (lastTotal.current !== null && data.total > lastTotal.current) {
      const latest = data.items[0]
      const route = latest?.trip?.route
      toast.success(
        latest
          ? `New booking — ${latest.passenger_name}${route ? ` (${route.origin} → ${route.destination})` : ''}`
          : 'New booking received'
      )
      qc.invalidateQueries({ queryKey: ['bookings'] })
      qc.invalidateQueries({ queryKey: ['transactions'] })
    }
    lastTotal.current = data.total
  }, [data, toast, qc])
}
