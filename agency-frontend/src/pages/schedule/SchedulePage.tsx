import { useState } from 'react'
import {
  Calendar, Plus, Route as RouteIcon, Bus, Clock,
  CheckCircle2, XCircle, AlertTriangle, MapPin,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Header from '../../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import Modal from '../../components/ui/Modal'
import DataTable from '../../components/ui/DataTable'
import EmptyState from '../../components/ui/EmptyState'
import { FormField, Input, Select } from '../../components/ui/FormField'
import { tripApi } from '../../api/trips'
import { routeApi } from '../../api/routes'
import { useAuth } from '../../contexts/AuthContext'
import type { Trip, Route, TripStatus } from '../../types'
import { formatCurrency, formatDateTime, statusColor } from '../../utils/format'
import { TOGO_CITIES } from '../../utils/mockData'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'
type ActiveTab = 'trips' | 'routes'

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
})

const routeSchema = z.object({
  origin: z.string().min(1),
  destination: z.string().min(1),
  distance_km: z.coerce.number().min(1).optional(),
  duration_minutes: z.coerce.number().min(1).optional(),
})

type TripForm = z.infer<typeof tripSchema>
type RouteForm = z.infer<typeof routeSchema>

const STATUS_COLORS: Record<TripStatus, BadgeColor> = {
  scheduled: 'primary',
  departed: 'warning',
  completed: 'success',
  cancelled: 'error',
  delayed: 'warning',
}

export default function SchedulePage() {
  const { agency } = useAuth()
  const qc = useQueryClient()
  const [tab, setTab] = useState<ActiveTab>('trips')
  const [showTripModal, setShowTripModal] = useState(false)
  const [showRouteModal, setShowRouteModal] = useState(false)
  const [statusFilter, setStatusFilter] = useState<TripStatus | 'all'>('all')

  const { data: trips = [], isLoading: tripsLoading } = useQuery({
    queryKey: ['trips', agency?.id],
    queryFn: () => tripApi.list({ agency_id: agency?.id }),
    enabled: !!agency,
  })

  const { data: routes = [], isLoading: routesLoading } = useQuery({
    queryKey: ['routes', agency?.id],
    queryFn: () => routeApi.listByAgency(agency!.id),
    enabled: !!agency,
  })

  const createTrip = useMutation({
    mutationFn: tripApi.create,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['trips'] }); setShowTripModal(false); tripForm.reset() },
  })

  const createRoute = useMutation({
    mutationFn: (data: RouteForm) => routeApi.create({ ...data, agency_id: agency!.id }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['routes'] }); setShowRouteModal(false); routeForm.reset() },
  })

  const updateStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: TripStatus }) => tripApi.updateStatus(id, status),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['trips'] }),
  })

  const tripForm = useForm<TripForm>({
    resolver: zodResolver(tripSchema),
    defaultValues: { total_seats: 50, has_wifi: false, has_meal: false, has_ac: false, has_usb: false },
  })

  const routeForm = useForm<RouteForm>({ resolver: zodResolver(routeSchema) })

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

  const routeColumns = [
    {
      key: 'origin',
      header: 'Origin',
      render: (r: Route) => <span className="font-medium text-dark">{r.origin}</span>,
    },
    {
      key: 'destination',
      header: 'Destination',
      render: (r: Route) => <span className="font-medium text-dark">{r.destination}</span>,
    },
    {
      key: 'distance_km',
      header: 'Distance',
      render: (r: Route) => <span className="text-gray-500">{r.distance_km ? `${r.distance_km} km` : '—'}</span>,
    },
    {
      key: 'duration_minutes',
      header: 'Duration',
      render: (r: Route) => <span className="text-gray-500">{r.duration_minutes ? `${Math.floor(r.duration_minutes / 60)}h ${r.duration_minutes % 60}m` : '—'}</span>,
    },
    {
      key: 'is_active',
      header: 'Status',
      render: (r: Route) => <Badge label={r.is_active ? 'active' : 'inactive'} color={r.is_active ? 'success' : 'secondary'} />,
    },
  ]

  return (
    <div>
      <Header
        title="Schedule & Routes"
        subtitle="Manage departures, routes, and trip statuses"
        actions={
          <div className="flex gap-2">
            <Button variant="outline" size="sm" leftIcon={<RouteIcon className="w-4 h-4" />} onClick={() => setShowRouteModal(true)}>
              New Route
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

      {/* Tab switcher */}
      <div className="flex gap-2 mb-4">
        {(['trips', 'routes'] as ActiveTab[]).map(t => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 rounded-xl text-sm font-medium capitalize transition ${
              tab === t ? 'bg-primary text-white shadow-sm' : 'bg-white text-gray-500 shadow-card hover:bg-gray-50'
            }`}
          >
            {t === 'trips' ? `Trips (${trips.length})` : `Routes (${routes.length})`}
          </button>
        ))}
      </div>

      <Card padding={false}>
        {tab === 'trips' ? (
          <>
            {/* Status filter */}
            <div className="flex gap-2 px-5 py-3 border-b border-gray-100">
              {(['all', 'scheduled', 'departed', 'delayed', 'completed', 'cancelled'] as const).map(s => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition ${
                    statusFilter === s ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                  }`}
                >
                  {s}
                </button>
              ))}
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
          </>
        ) : (
          <>
            {routes.length === 0 && !routesLoading ? (
              <EmptyState
                icon={RouteIcon}
                title="No routes defined"
                description="Create a route first, then schedule trips on it."
                action={{ label: 'Create a route', onClick: () => setShowRouteModal(true) }}
              />
            ) : (
              <DataTable columns={routeColumns} data={routes} loading={routesLoading} rowKey={r => r.id} />
            )}
          </>
        )}
      </Card>

      {/* Create Trip Modal */}
      <Modal open={showTripModal} onClose={() => setShowTripModal(false)} title="Schedule New Trip" size="lg">
        <form onSubmit={tripForm.handleSubmit(d => createTrip.mutate(d))} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Route" required error={tripForm.formState.errors.route_id?.message} className="col-span-2">
              <Select {...tripForm.register('route_id')} error={!!tripForm.formState.errors.route_id}>
                <option value="">— Select a route —</option>
                {routes.map(r => (
                  <option key={r.id} value={r.id}>{r.origin} → {r.destination}</option>
                ))}
              </Select>
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
          {createTrip.error && (
            <p className="text-sm text-error bg-red-50 px-3 py-2 rounded-lg">
              {(createTrip.error as Error).message}
            </p>
          )}
          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => setShowTripModal(false)}>Cancel</Button>
            <Button type="submit" loading={createTrip.isPending}>Schedule Trip</Button>
          </div>
        </form>
      </Modal>

      {/* Create Route Modal */}
      <Modal open={showRouteModal} onClose={() => setShowRouteModal(false)} title="Create New Route">
        <form onSubmit={routeForm.handleSubmit(d => createRoute.mutate(d))} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Origin" required error={routeForm.formState.errors.origin?.message}>
              <Select {...routeForm.register('origin')} error={!!routeForm.formState.errors.origin}>
                <option value="">— City —</option>
                {TOGO_CITIES.map(c => <option key={c} value={c}>{c}</option>)}
              </Select>
            </FormField>
            <FormField label="Destination" required error={routeForm.formState.errors.destination?.message}>
              <Select {...routeForm.register('destination')} error={!!routeForm.formState.errors.destination}>
                <option value="">— City —</option>
                {TOGO_CITIES.map(c => <option key={c} value={c}>{c}</option>)}
              </Select>
            </FormField>
            <FormField label="Distance (km)" error={routeForm.formState.errors.distance_km?.message}>
              <Input {...routeForm.register('distance_km')} type="number" min={1} placeholder="e.g. 350" />
            </FormField>
            <FormField label="Duration (minutes)" error={routeForm.formState.errors.duration_minutes?.message}>
              <Input {...routeForm.register('duration_minutes')} type="number" min={1} placeholder="e.g. 420" />
            </FormField>
          </div>
          {createRoute.error && (
            <p className="text-sm text-error bg-red-50 px-3 py-2 rounded-lg">
              {(createRoute.error as Error).message}
            </p>
          )}
          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => setShowRouteModal(false)}>Cancel</Button>
            <Button type="submit" loading={createRoute.isPending}>Create Route</Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
