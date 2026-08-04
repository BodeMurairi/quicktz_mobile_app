import { useState } from 'react'
import {
  Calendar, Plus, Route as RouteIcon, Bus, Clock,
  CheckCircle2, XCircle, AlertTriangle, MapPin, Trash2, ClipboardList, Repeat,
} from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm, useFieldArray } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Header from '../../components/layout/Header'
import { Card } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import Modal from '../../components/ui/Modal'
import DataTable from '../../components/ui/DataTable'
import EmptyState from '../../components/ui/EmptyState'
import { FormField, Input, Select } from '../../components/ui/FormField'
import { tripApi } from '../../api/trips'
import { routeApi } from '../../api/routes'
import { useAuth } from '../../contexts/AuthContext'
import { useToast } from '../../contexts/ToastContext'
import type { Trip, TripStatus } from '../../types'
import { formatCurrency, formatDateTime } from '../../utils/format'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

const REQUIREMENT_PRESETS = [
  'Max luggage (bags)',
  'Max weight per bag (kg)',
  'Prohibited items',
  'ID required at boarding',
  'Check-in deadline',
]

const tripSchema = z.object({
  route_id: z.string().min(1, 'Select a route'),
  departure_datetime: z.string().min(1, 'Set departure time'),
  arrival_datetime: z.string().optional(),
  total_seats: z.coerce.number().int().min(1).max(100),
  price: z.coerce.number().min(1000),
  bus_number: z.string().optional(),
  has_wifi: z.boolean().default(false),
  has_meal: z.boolean().default(false),
  has_ac: z.boolean().default(false),
  has_usb: z.boolean().default(false),
  requirements: z.array(z.object({
    label: z.string().min(1, 'Required'),
    value: z.string().min(1, 'Required'),
  })).optional(),
})

type TripForm = z.infer<typeof tripSchema>

const STATUS_COLORS: Record<TripStatus, BadgeColor> = {
  scheduled: 'primary',
  departed: 'warning',
  completed: 'success',
  cancelled: 'error',
  delayed: 'warning',
}

const STATUS_LABEL: Record<TripStatus, string> = {
  scheduled: 'scheduled',
  departed: 'marked as departed',
  completed: 'marked as completed',
  cancelled: 'cancelled',
  delayed: 'marked as delayed',
}

// ── Recurrence (create multiple occurrences of the same trip in one submit) ────

type RecurrenceType = 'none' | 'daily' | 'weekly' | 'custom'
const WEEKDAY_LABELS = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
const RECURRENCE_MAX = 60 // hard cap per batch so a mis-click can't spam hundreds of trips

interface RecurrenceConfig {
  type: RecurrenceType
  weekdays: number[]
  endType: 'after_count' | 'on_date'
  count: number
  endDate: string
}

function toDatetimeLocalValue(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function buildOccurrenceDates(startValue: string, recur: RecurrenceConfig): Date[] {
  const start = new Date(startValue)
  if (recur.type === 'none' || isNaN(start.getTime())) return [start]

  const maxCount = Math.min(recur.endType === 'after_count' ? recur.count : RECURRENCE_MAX, RECURRENCE_MAX)
  const endDate = recur.endType === 'on_date' && recur.endDate ? new Date(`${recur.endDate}T23:59:59`) : null
  const dates: Date[] = []

  if (recur.type === 'daily') {
    for (let i = 0; dates.length < maxCount; i++) {
      const d = new Date(start)
      d.setDate(d.getDate() + i)
      if (endDate && d > endDate) break
      dates.push(d)
    }
  } else if (recur.type === 'weekly') {
    for (let i = 0; dates.length < maxCount; i++) {
      const d = new Date(start)
      d.setDate(d.getDate() + i * 7)
      if (endDate && d > endDate) break
      dates.push(d)
    }
  } else if (recur.type === 'custom') {
    const days = recur.weekdays.length > 0 ? recur.weekdays : [start.getDay()]
    const cursor = new Date(start)
    let guard = 0
    while (dates.length < maxCount && guard < 400) {
      if (days.includes(cursor.getDay()) && cursor.getTime() >= start.getTime()) {
        if (endDate && cursor > endDate) break
        dates.push(new Date(cursor))
      }
      cursor.setDate(cursor.getDate() + 1)
      guard++
    }
  }

  return dates.length > 0 ? dates : [start]
}

export default function TripsPage() {
  const { agency } = useAuth()
  const qc = useQueryClient()
  const navigate = useNavigate()
  const toast = useToast()
  const [showTripModal, setShowTripModal] = useState(false)
  const [statusFilter, setStatusFilter] = useState<TripStatus | 'all'>('all')
  const [recurrence, setRecurrence] = useState<RecurrenceType>('none')
  const [recurWeekdays, setRecurWeekdays] = useState<number[]>([])
  const [recurEndType, setRecurEndType] = useState<'after_count' | 'on_date'>('after_count')
  const [recurCount, setRecurCount] = useState(4)
  const [recurEndDate, setRecurEndDate] = useState('')

  const { data: trips = [], isLoading: tripsLoading } = useQuery({
    queryKey: ['trips', agency?.id],
    queryFn: () => tripApi.list({ agency_id: agency?.id }),
    enabled: !!agency,
  })

  const { data: routes = [] } = useQuery({
    queryKey: ['routes', agency?.id],
    queryFn: () => routeApi.listByAgency(agency!.id),
    enabled: !!agency,
  })
  const activeRoutes = routes.filter(r => r.is_active)

  // No onSuccess/onError here — recurring trips call mutateAsync in a loop from
  // handleScheduleSubmit, which reports one aggregate toast for the whole batch.
  const createTrip = useMutation({ mutationFn: tripApi.create })

  function resetRecurrence() {
    setRecurrence('none')
    setRecurWeekdays([])
    setRecurEndType('after_count')
    setRecurCount(4)
    setRecurEndDate('')
  }

  async function handleScheduleSubmit(d: TripForm) {
    const occurrences = buildOccurrenceDates(d.departure_datetime, {
      type: recurrence,
      weekdays: recurWeekdays,
      endType: recurEndType,
      count: recurCount,
      endDate: recurEndDate,
    })

    const start = new Date(d.departure_datetime)
    const arrival = d.arrival_datetime ? new Date(d.arrival_datetime) : null
    const arrivalOffsetMs = arrival && !isNaN(arrival.getTime()) ? arrival.getTime() - start.getTime() : null

    let success = 0
    let failed = 0
    for (const occ of occurrences) {
      const departure_datetime = toDatetimeLocalValue(occ)
      const arrival_datetime = arrivalOffsetMs != null
        ? toDatetimeLocalValue(new Date(occ.getTime() + arrivalOffsetMs))
        : undefined
      try {
        await createTrip.mutateAsync({ ...d, departure_datetime, arrival_datetime })
        success++
      } catch {
        failed++
      }
    }

    qc.invalidateQueries({ queryKey: ['trips'] })
    setShowTripModal(false)
    tripForm.reset()
    resetRecurrence()

    if (failed === 0) {
      toast.success(success > 1 ? `${success} trips scheduled successfully.` : 'Trip scheduled successfully.')
    } else if (success === 0) {
      toast.error('Could not schedule the trip(s). Please try again.')
    } else {
      toast.error(`${success} trip(s) scheduled, ${failed} failed — please check and retry.`)
    }
  }

  const updateStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: TripStatus }) => tripApi.updateStatus(id, status),
    onSuccess: (trip, variables) => {
      qc.invalidateQueries({ queryKey: ['trips'] })
      const route = trip.route ? `${trip.route.origin} → ${trip.route.destination} ` : 'Trip '
      toast.success(`${route}${STATUS_LABEL[variables.status]}.`)
    },
    onError: () => toast.error('Could not update the trip status. Please try again.'),
  })

  const tripForm = useForm<TripForm>({
    resolver: zodResolver(tripSchema),
    defaultValues: { total_seats: 50, has_wifi: false, has_meal: false, has_ac: false, has_usb: false, requirements: [] },
  })
  const requirementsArray = useFieldArray({ control: tripForm.control, name: 'requirements' })

  const filteredTrips = statusFilter === 'all' ? trips : trips.filter(t => t.status === statusFilter)

  const tripColumns = [
    {
      key: 'route',
      header: 'Route',
      render: (t: Trip) => (
        <div className="flex items-center gap-2">
          <MapPin className="w-3.5 h-3.5 text-primary shrink-0" />
          <span className="text-sm font-medium text-dark">
            {t.route?.origin ?? '—'} → {t.route?.destination ?? '—'}
          </span>
        </div>
      ),
    },
    {
      key: 'departure_datetime',
      header: 'Departure',
      render: (t: Trip) => <span className="text-sm">{formatDateTime(t.departure_datetime)}</span>,
    },
    {
      key: 'seats',
      header: 'Seats',
      render: (t: Trip) => (
        <div className="text-sm">
          <span className="font-semibold text-dark">{t.available_seats}</span>
          <span className="text-gray-400"> / {t.total_seats} available</span>
        </div>
      ),
    },
    {
      key: 'price',
      header: 'Price',
      render: (t: Trip) => <span className="font-semibold text-dark">{formatCurrency(t.price)}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      render: (t: Trip) => <Badge label={t.status} color={STATUS_COLORS[t.status]} dot />,
    },
    {
      key: 'amenities',
      header: 'Amenities',
      render: (t: Trip) => (
        <div className="flex gap-1">
          {t.has_ac && <span title="AC" className="text-primary text-xs">❄️</span>}
          {t.has_wifi && <span title="WiFi" className="text-xs">📶</span>}
          {t.has_meal && <span title="Meal" className="text-xs">🍽️</span>}
          {t.has_usb && <span title="USB" className="text-xs">🔌</span>}
        </div>
      ),
    },
    {
      key: 'requirements',
      header: 'Requirements',
      render: (t: Trip) => {
        const reqs = t.requirements ?? []
        if (reqs.length === 0) return <span className="text-xs text-gray-400">None</span>
        const tooltip = reqs.map(r => `${r.label}: ${r.value}`).join('\n')
        return (
          <span className="inline-flex items-center gap-1 text-xs text-dark" title={tooltip}>
            <ClipboardList className="w-3 h-3 text-gray-400" />
            {reqs.length}
          </span>
        )
      },
    },
    {
      key: 'actions',
      header: 'Quick update',
      render: (t: Trip) => (
        <div className="flex gap-1">
          {t.status === 'scheduled' && (
            <>
              <button
                onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'departed' }) }}
                className="p-1.5 rounded-lg hover:bg-primary/10 text-primary transition"
                title="Mark departed"
              >
                <Bus className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'delayed' }) }}
                className="p-1.5 rounded-lg hover:bg-amber-50 text-warning transition"
                title="Mark delayed"
              >
                <AlertTriangle className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'cancelled' }) }}
                className="p-1.5 rounded-lg hover:bg-red-50 text-error transition"
                title="Cancel trip"
              >
                <XCircle className="w-3.5 h-3.5" />
              </button>
            </>
          )}
          {t.status === 'departed' && (
            <button
              onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'completed' }) }}
              className="p-1.5 rounded-lg hover:bg-green-50 text-success transition"
              title="Mark completed"
            >
              <CheckCircle2 className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      ),
    },
  ]

  return (
    <div>
      <Header
        title="Trips"
        subtitle="Manage departures and trip statuses"
        actions={
          <div className="flex gap-2">
            <Button variant="outline" size="sm" leftIcon={<RouteIcon className="w-4 h-4" />} onClick={() => navigate('/routes')}>
              Manage Routes
            </Button>
            <Button size="sm" leftIcon={<Plus className="w-4 h-4" />} onClick={() => setShowTripModal(true)}>
              Schedule Trip
            </Button>
          </div>
        }
      />

      {/* Quick stats */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[
          { label: 'Total trips', count: trips.length, icon: Bus, color: 'text-primary bg-primary/10' },
          { label: 'Scheduled', count: trips.filter(t => t.status === 'scheduled').length, icon: Calendar, color: 'text-primary bg-primary/10' },
          { label: 'Departed', count: trips.filter(t => t.status === 'departed').length, icon: Clock, color: 'text-warning bg-amber-100' },
          { label: 'Completed', count: trips.filter(t => t.status === 'completed').length, icon: CheckCircle2, color: 'text-success bg-green-100' },
        ].map(s => (
          <Card key={s.label} className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${s.color}`}>
              <s.icon className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xl font-extrabold text-dark">{s.count}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </div>
          </Card>
        ))}
      </div>

      <Card padding={false}>
        {/* Status filter */}
        <div className="flex flex-wrap gap-2 px-5 py-3 border-b border-gray-100">
          {(['all', 'scheduled', 'departed', 'delayed', 'completed', 'cancelled'] as const).map(s => {
            const count = s === 'all' ? trips.length : trips.filter(t => t.status === s).length
            return (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition ${
                  statusFilter === s ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                }`}
              >
                {s} ({count})
              </button>
            )
          })}
        </div>
        {filteredTrips.length === 0 && !tripsLoading ? (
          <EmptyState
            icon={Calendar}
            title="No trips scheduled"
            description="Schedule your first departure to start accepting bookings."
            action={{ label: 'Schedule a trip', onClick: () => setShowTripModal(true) }}
          />
        ) : (
          <DataTable columns={tripColumns} data={filteredTrips} loading={tripsLoading} rowKey={t => t.id} />
        )}
      </Card>

      {/* Create Trip Modal */}
      <Modal open={showTripModal} onClose={() => setShowTripModal(false)} title="Schedule New Trip" size="lg">
        <form onSubmit={tripForm.handleSubmit(handleScheduleSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Route" required error={tripForm.formState.errors.route_id?.message} className="col-span-2">
              <Select {...tripForm.register('route_id')} error={!!tripForm.formState.errors.route_id}>
                <option value="">— Select a route —</option>
                {activeRoutes.map(r => (
                  <option key={r.id} value={r.id}>{r.origin} → {r.destination}</option>
                ))}
              </Select>
              {activeRoutes.length === 0 && (
                <p className="text-xs text-gray-400 mt-1">
                  No active routes yet — <button type="button" onClick={() => navigate('/routes')} className="text-primary underline">create or reactivate one in Routes</button> first.
                </p>
              )}
            </FormField>
            <FormField label="Departure" required error={tripForm.formState.errors.departure_datetime?.message}>
              <Input {...tripForm.register('departure_datetime')} type="datetime-local" />
            </FormField>
            <FormField label="Arrival (est.)" error={tripForm.formState.errors.arrival_datetime?.message}>
              <Input {...tripForm.register('arrival_datetime')} type="datetime-local" />
            </FormField>
            <FormField label="Total seats" required error={tripForm.formState.errors.total_seats?.message}>
              <Input {...tripForm.register('total_seats')} type="number" min={1} max={100} />
            </FormField>
            <FormField label="Price (XOF)" required error={tripForm.formState.errors.price?.message}>
              <Input {...tripForm.register('price')} type="number" min={1000} step={500} />
            </FormField>
            <FormField label="Bus / Vehicle number" error={tripForm.formState.errors.bus_number?.message}>
              <Input {...tripForm.register('bus_number')} placeholder="e.g. TG-1234" />
            </FormField>
          </div>

          {/* Recurrence */}
          <div className="border border-gray-200 rounded-xl p-3.5 space-y-3">
            <div className="flex items-center gap-2">
              <Repeat className="w-4 h-4 text-gray-400" />
              <p className="text-sm font-medium text-dark">Repeat</p>
            </div>
            <Select value={recurrence} onChange={e => setRecurrence(e.target.value as RecurrenceType)}>
              <option value="none">Does not repeat</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly, same day</option>
              <option value="custom">Custom…</option>
            </Select>

            {recurrence === 'custom' && (
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1.5">Repeat on</p>
                <div className="flex gap-1.5">
                  {WEEKDAY_LABELS.map((label, idx) => (
                    <button
                      key={label + idx}
                      type="button"
                      onClick={() => setRecurWeekdays(prev =>
                        prev.includes(idx) ? prev.filter(d => d !== idx) : [...prev, idx].sort()
                      )}
                      className={`w-8 h-8 rounded-full text-xs font-semibold transition ${
                        recurWeekdays.includes(idx) ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {recurrence !== 'none' && (
              <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
                <p className="text-xs font-medium text-gray-500 w-full">Ends</p>
                <label className="flex items-center gap-1.5 text-xs text-dark">
                  <input
                    type="radio"
                    checked={recurEndType === 'after_count'}
                    onChange={() => setRecurEndType('after_count')}
                    className="accent-primary"
                  />
                  After
                  <input
                    type="number"
                    min={1}
                    max={RECURRENCE_MAX}
                    value={recurCount}
                    onFocus={() => setRecurEndType('after_count')}
                    onChange={e => setRecurCount(Math.min(RECURRENCE_MAX, Math.max(1, Number(e.target.value) || 1)))}
                    className="w-14 px-2 py-1 border border-gray-200 rounded-lg text-xs"
                  />
                  occurrences
                </label>
                <label className="flex items-center gap-1.5 text-xs text-dark">
                  <input
                    type="radio"
                    checked={recurEndType === 'on_date'}
                    onChange={() => setRecurEndType('on_date')}
                    className="accent-primary"
                  />
                  On date
                  <input
                    type="date"
                    value={recurEndDate}
                    onChange={e => { setRecurEndDate(e.target.value); setRecurEndType('on_date') }}
                    className="px-2 py-1 border border-gray-200 rounded-lg text-xs"
                  />
                </label>
                <p className="text-xs text-gray-400 w-full">Capped at {RECURRENCE_MAX} trips per batch.</p>
              </div>
            )}
          </div>

          {/* Amenities */}
          <div>
            <p className="text-sm font-medium text-dark mb-2">Amenities</p>
            <div className="grid grid-cols-4 gap-2">
              {[
                { key: 'has_ac', label: '❄️ AC' },
                { key: 'has_wifi', label: '📶 WiFi' },
                { key: 'has_meal', label: '🍽️ Meal' },
                { key: 'has_usb', label: '🔌 USB' },
              ].map(a => (
                <label key={a.key} className="flex items-center gap-2 cursor-pointer p-2.5 rounded-lg border border-gray-200 hover:bg-background">
                  <input type="checkbox" {...tripForm.register(a.key as keyof TripForm)} className="accent-primary" />
                  <span className="text-sm">{a.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Travel requirements */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <div>
                <p className="text-sm font-medium text-dark">Travel requirements <span className="text-gray-400 font-normal">(optional)</span></p>
                <p className="text-xs text-gray-400">Shown to passengers on this trip's details in the mobile app.</p>
              </div>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                leftIcon={<Plus className="w-3.5 h-3.5" />}
                onClick={() => requirementsArray.append({ label: '', value: '' })}
              >
                Add requirement
              </Button>
            </div>

            {/* Quick-add presets */}
            <div className="flex flex-wrap gap-1.5 mb-3">
              {REQUIREMENT_PRESETS.map(preset => (
                <button
                  key={preset}
                  type="button"
                  onClick={() => {
                    if (requirementsArray.fields.some((_, i) => tripForm.getValues(`requirements.${i}.label`) === preset)) return
                    requirementsArray.append({ label: preset, value: '' })
                  }}
                  className="inline-flex items-center gap-1 text-xs px-2.5 py-1 rounded-full border border-gray-200 text-gray-500 hover:border-primary hover:text-primary transition"
                >
                  <Plus className="w-3 h-3" />
                  {preset}
                </button>
              ))}
            </div>

            {requirementsArray.fields.length === 0 ? (
              <p className="text-xs text-gray-400 flex items-center gap-1.5">
                <ClipboardList className="w-3.5 h-3.5" />
                No requirements added — this trip has no special conditions.
              </p>
            ) : (
              <div className="space-y-2">
                {requirementsArray.fields.map((field, i) => (
                  <div key={field.id} className="flex items-start gap-2">
                    <div className="flex-1">
                      <Input
                        {...tripForm.register(`requirements.${i}.label` as const)}
                        placeholder="Requirement, e.g. Max luggage (bags)"
                        error={!!tripForm.formState.errors.requirements?.[i]?.label}
                      />
                    </div>
                    <div className="flex-1">
                      <Input
                        {...tripForm.register(`requirements.${i}.value` as const)}
                        placeholder="Value, e.g. 2 bags per passenger"
                        error={!!tripForm.formState.errors.requirements?.[i]?.value}
                      />
                    </div>
                    <button
                      type="button"
                      onClick={() => requirementsArray.remove(i)}
                      className="p-2.5 rounded-lg text-gray-400 hover:text-error hover:bg-red-50 transition shrink-0"
                      title="Remove requirement"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => { setShowTripModal(false); resetRecurrence() }}>Cancel</Button>
            <Button type="submit" loading={tripForm.formState.isSubmitting}>
              {recurrence === 'none' ? 'Schedule Trip' : 'Schedule Trips'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
