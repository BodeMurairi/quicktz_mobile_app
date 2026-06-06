import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Printer, XCircle, CheckCircle2 } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import jsPDF from 'jspdf'
import Header from '../../components/layout/Header'
import { Card } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import { bookingApi } from '../../api/bookings'
import { formatCurrency, formatDateTime, statusColor } from '../../utils/format'
import type { Booking } from '../../types'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

function printTicket(b: Booking) {
  const doc = new jsPDF({ unit: 'mm', format: [80, 200] })
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('QuickTZ', 40, 15, { align: 'center' })
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('BOARDING PASS', 40, 22, { align: 'center' })
  doc.line(5, 26, 75, 26)
  const y = 34
  const rows = [
    ['Passenger', b.passenger_name],
    ['Phone', b.passenger_phone ?? '—'],
    ['From', b.trip?.route?.origin ?? '—'],
    ['To', b.trip?.route?.destination ?? '—'],
    ['Departure', b.trip ? formatDateTime(b.trip.departure_datetime) : '—'],
    ['Seat', b.seat_number ? String(b.seat_number) : 'Any'],
    ['Price', formatCurrency(b.total_price)],
    ['Status', b.status.toUpperCase()],
    ['Ticket Code', b.ticket?.ticket_code ?? '—'],
    ['Booking ID', b.id.slice(0, 12).toUpperCase()],
  ]
  rows.forEach(([label, val], i) => {
    doc.setFont('helvetica', 'bold')
    doc.text(`${label}:`, 8, y + i * 8)
    doc.setFont('helvetica', 'normal')
    doc.text(val, 38, y + i * 8)
  })
  doc.save(`ticket-${b.id.slice(0, 8)}.pdf`)
}

export default function BookingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const qc = useQueryClient()

  const { data: booking, isLoading, isError } = useQuery({
    queryKey: ['booking', id],
    queryFn: () => bookingApi.get(id!),
    enabled: !!id,
  })

  const cancelMutation = useMutation({
    mutationFn: () => bookingApi.cancel(id!),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['booking', id] }),
  })

  const confirmMutation = useMutation({
    mutationFn: () => bookingApi.confirm(id!),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['booking', id] }),
  })

  if (isLoading) return <div className="flex justify-center py-16"><div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" /></div>
  if (isError || !booking) return <div className="text-center py-16 text-error">Booking not found</div>

  const route = booking.trip?.route
  const trip  = booking.trip

  return (
    <div>
      <Header title="Booking Detail" />

      <div className="mb-4">
        <Button variant="ghost" size="sm" leftIcon={<ArrowLeft className="w-4 h-4" />} onClick={() => navigate('/bookings')}>
          Back to bookings
        </Button>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Main info */}
        <div className="col-span-2 space-y-4">
          {/* Status banner */}
          <Card className="flex items-center gap-4">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <span className="font-mono text-sm font-semibold text-dark">
                  #{booking.id.slice(0, 12).toUpperCase()}
                </span>
                <Badge
                  label={booking.status}
                  color={statusColor(booking.status) as BadgeColor}
                  dot
                />
              </div>
              <p className="text-xs text-gray-400">Booked on {formatDateTime(booking.created_at)}</p>
            </div>
            <div className="flex gap-2">
              {booking.status === 'pending' && (
                <Button
                  size="sm"
                  leftIcon={<CheckCircle2 className="w-3.5 h-3.5" />}
                  loading={confirmMutation.isPending}
                  onClick={() => confirmMutation.mutate()}
                >
                  Confirm
                </Button>
              )}
              {['pending', 'confirmed'].includes(booking.status) && (
                <Button
                  variant="danger"
                  size="sm"
                  leftIcon={<XCircle className="w-3.5 h-3.5" />}
                  loading={cancelMutation.isPending}
                  onClick={() => cancelMutation.mutate()}
                >
                  Cancel
                </Button>
              )}
              <Button
                variant="outline"
                size="sm"
                leftIcon={<Printer className="w-3.5 h-3.5" />}
                onClick={() => printTicket(booking)}
              >
                Print ticket
              </Button>
            </div>
          </Card>

          {/* Passenger */}
          <Card>
            <h3 className="section-title mb-4">Passenger Information</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <Info label="Full name" value={booking.passenger_name} />
              <Info label="Phone" value={booking.passenger_phone ?? '—'} />
              <Info label="Seat number" value={booking.seat_number ? String(booking.seat_number) : 'Unassigned'} />
              <Info label="Total paid" value={formatCurrency(booking.total_price)} highlight />
            </div>
          </Card>

          {/* Trip */}
          {trip && (
            <Card>
              <h3 className="section-title mb-4">Trip Information</h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <Info label="Origin" value={route?.origin ?? '—'} />
                <Info label="Destination" value={route?.destination ?? '—'} />
                <Info label="Departure" value={formatDateTime(trip.departure_datetime)} />
                <Info label="Arrival" value={trip.arrival_datetime ? formatDateTime(trip.arrival_datetime) : '—'} />
                <Info label="Bus number" value={trip.bus_number ?? '—'} />
                <Info label="Trip status">
                  <Badge label={trip.status} color={statusColor(trip.status) as BadgeColor} />
                </Info>
              </div>
              {/* Amenities */}
              <div className="flex gap-2 flex-wrap mt-4 pt-4 border-t border-gray-100">
                {trip.has_ac && <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded-full">❄️ AC</span>}
                {trip.has_wifi && <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded-full">📶 WiFi</span>}
                {trip.has_meal && <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded-full">🍽️ Meal</span>}
                {trip.has_usb && <span className="text-xs bg-primary/10 text-primary px-2 py-1 rounded-full">🔌 USB</span>}
              </div>
            </Card>
          )}
        </div>

        {/* Ticket + Payment sidebar */}
        <div className="space-y-4">
          {booking.ticket && (
            <Card className="bg-gradient-to-br from-dark to-primary text-white">
              <p className="text-xs text-primary-200 uppercase tracking-wider mb-3">Digital Ticket</p>
              <p className="text-2xl font-extrabold tracking-widest mb-1">{booking.ticket.ticket_code}</p>
              <p className="text-xs text-primary-200 mb-4">Show this code at boarding</p>
              <Badge
                label={booking.ticket.status}
                color={statusColor(booking.ticket.status) as BadgeColor}
                className="text-white bg-white/20"
              />
            </Card>
          )}

          {booking.payment && (
            <Card>
              <h3 className="section-title mb-4 text-sm">Payment</h3>
              <div className="space-y-2 text-sm">
                <Info label="Method" value={booking.payment.payment_method.replace('_', ' ')} />
                <Info label="Amount" value={formatCurrency(booking.payment.amount)} highlight />
                <Info label="Status">
                  <Badge label={booking.payment.status} color={statusColor(booking.payment.status) as BadgeColor} />
                </Info>
                {booking.payment.paid_at && (
                  <Info label="Paid at" value={formatDateTime(booking.payment.paid_at)} />
                )}
              </div>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}

function Info({
  label,
  value,
  highlight = false,
  children,
}: {
  label: string
  value?: string
  highlight?: boolean
  children?: React.ReactNode
}) {
  return (
    <div>
      <p className="text-xs text-gray-400 mb-0.5">{label}</p>
      {children ?? (
        <p className={highlight ? 'font-bold text-primary' : 'font-medium text-dark'}>
          {value ?? '—'}
        </p>
      )}
    </div>
  )
}
