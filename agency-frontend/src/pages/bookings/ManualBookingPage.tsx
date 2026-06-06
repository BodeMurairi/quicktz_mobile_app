import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Header from '../../components/layout/Header'
import { Card } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import { FormField, Input, Select } from '../../components/ui/FormField'
import { tripApi } from '../../api/trips'
import { bookingApi } from '../../api/bookings'
import { useAuth } from '../../contexts/AuthContext'
import { formatCurrency, formatDateTime } from '../../utils/format'

const schema = z.object({
  trip_id: z.string().min(1, 'Please select a trip'),
  passenger_name: z.string().min(2, 'Name must be at least 2 characters'),
  passenger_phone: z.string().optional(),
  seat_number: z.coerce.number().int().min(1).optional(),
  payment_method: z.enum(['mobile_money', 'tmoney', 'flooz', 'bank_transfer', 'cash']),
})

type FormData = z.infer<typeof schema>

export default function ManualBookingPage() {
  const { agency } = useAuth()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const [success, setSuccess] = useState<string | null>(null)

  const { data: trips = [] } = useQuery({
    queryKey: ['trips', agency?.id],
    queryFn: () => tripApi.list({ agency_id: agency?.id, status: 'scheduled' }),
    enabled: !!agency,
  })

  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { payment_method: 'mobile_money' },
  })

  const selectedTrip = trips.find(t => t.id === watch('trip_id'))

  const mutation = useMutation({
    mutationFn: bookingApi.create,
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ['bookings'] })
      setSuccess(data.id)
      reset()
    },
  })

  function onSubmit(data: FormData) {
    mutation.mutate(data)
  }

  if (success) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mb-4">
          <CheckCircle className="w-9 h-9 text-success" />
        </div>
        <h2 className="text-xl font-bold text-dark mb-2">Booking Confirmed!</h2>
        <p className="text-gray-500 text-sm mb-1">Booking ID: <span className="font-mono font-semibold">{success.slice(0, 12).toUpperCase()}</span></p>
        <p className="text-gray-400 text-xs mb-6">Ticket has been generated and saved.</p>
        <div className="flex gap-3">
          <Button variant="outline" onClick={() => navigate('/bookings')}>
            View all bookings
          </Button>
          <Button onClick={() => { setSuccess(null) }}>
            Add another booking
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div>
      <Header title="Manual Booking" subtitle="Enter booking details for walk-in or phone customers" />

      <div className="grid grid-cols-3 gap-6">
        {/* Form */}
        <div className="col-span-2">
          <Card>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              {/* Trip selection */}
              <div>
                <h3 className="section-title mb-4">1. Select Trip</h3>
                <FormField label="Available Trip" required error={errors.trip_id?.message}>
                  <Select {...register('trip_id')} error={!!errors.trip_id}>
                    <option value="">— Choose a departure —</option>
                    {trips.map(t => (
                      <option key={t.id} value={t.id}>
                        {t.route?.origin} → {t.route?.destination} · {formatDateTime(t.departure_datetime)} · {formatCurrency(t.price)} · {t.available_seats} seats left
                      </option>
                    ))}
                  </Select>
                </FormField>
              </div>

              {/* Passenger */}
              <div>
                <h3 className="section-title mb-4">2. Passenger Details</h3>
                <div className="grid grid-cols-2 gap-4">
                  <FormField label="Full name" required error={errors.passenger_name?.message}>
                    <Input {...register('passenger_name')} placeholder="Kofi Mensah" error={!!errors.passenger_name} />
                  </FormField>
                  <FormField label="Phone number" error={errors.passenger_phone?.message}>
                    <Input {...register('passenger_phone')} placeholder="+228 90 00 00 00" />
                  </FormField>
                </div>
                <FormField label="Seat number (optional)" className="mt-4" error={errors.seat_number?.message}>
                  <Input {...register('seat_number')} type="number" placeholder="e.g. 14" className="max-w-[120px]" />
                </FormField>
              </div>

              {/* Payment */}
              <div>
                <h3 className="section-title mb-4">3. Payment Method</h3>
                <FormField label="Method" required>
                  <Select {...register('payment_method')}>
                    <option value="mobile_money">Mobile Money</option>
                    <option value="tmoney">T-Money</option>
                    <option value="flooz">Flooz</option>
                    <option value="bank_transfer">Bank Transfer</option>
                    <option value="cash">Cash (walk-in)</option>
                  </Select>
                </FormField>
              </div>

              {mutation.error && (
                <p className="text-sm text-error bg-red-50 px-4 py-2 rounded-lg">
                  {(mutation.error as Error).message}
                </p>
              )}

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="outline" onClick={() => navigate('/bookings')} leftIcon={<ArrowLeft className="w-4 h-4" />}>
                  Cancel
                </Button>
                <Button type="submit" loading={mutation.isPending}>
                  Confirm Booking
                </Button>
              </div>
            </form>
          </Card>
        </div>

        {/* Summary sidebar */}
        <div className="space-y-4">
          <Card>
            <h3 className="section-title mb-4">Booking Summary</h3>
            {!selectedTrip ? (
              <p className="text-sm text-gray-400">Select a trip to see details</p>
            ) : (
              <div className="space-y-3 text-sm">
                <Row label="Route" value={`${selectedTrip.route?.origin} → ${selectedTrip.route?.destination}`} />
                <Row label="Departure" value={formatDateTime(selectedTrip.departure_datetime)} />
                <Row label="Arrival" value={selectedTrip.arrival_datetime ? formatDateTime(selectedTrip.arrival_datetime) : '—'} />
                <Row label="Bus" value={selectedTrip.bus_number ?? '—'} />
                <Row label="Available seats" value={String(selectedTrip.available_seats)} />
                <div className="border-t border-gray-100 pt-3 mt-3">
                  <div className="flex justify-between font-semibold">
                    <span className="text-gray-600">Total price</span>
                    <span className="text-primary text-base">{formatCurrency(selectedTrip.price)}</span>
                  </div>
                  <p className="text-xs text-gray-400 mt-1">
                    Net to agency: {formatCurrency(selectedTrip.price * 0.97)}
                    <span className="ml-1 text-gray-300">(after 3% platform fee)</span>
                  </p>
                </div>
                {/* Amenities */}
                <div className="flex flex-wrap gap-2 pt-1">
                  {selectedTrip.has_ac && <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">❄️ AC</span>}
                  {selectedTrip.has_wifi && <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">📶 WiFi</span>}
                  {selectedTrip.has_meal && <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">🍽️ Meal</span>}
                  {selectedTrip.has_usb && <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">🔌 USB</span>}
                </div>
              </div>
            )}
          </Card>

          <Card>
            <h3 className="section-title mb-3 text-sm">Need a printable list?</h3>
            <p className="text-xs text-gray-400 mb-3">After booking, generate a PDF manifest of all passengers for this trip.</p>
            <Button
              variant="outline"
              size="sm"
              className="w-full justify-center"
              onClick={() => navigate('/bookings')}
            >
              View bookings & print
            </Button>
          </Card>
        </div>
      </div>
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-dark text-right max-w-[60%]">{value}</span>
    </div>
  )
}
