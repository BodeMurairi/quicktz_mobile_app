import { useState } from 'react'
import {
  Route as RouteIcon, Plus, MapPinned, Ruler, Power, CalendarClock, Search, Trash2, MapPin,
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
import { routeApi } from '../../api/routes'
import { tripApi } from '../../api/trips'
import { useAuth } from '../../contexts/AuthContext'
import { useToast } from '../../contexts/ToastContext'
import type { Route } from '../../types'
import { TOGO_CITIES } from '../../utils/mockData'

type StatusFilter = 'all' | 'active' | 'inactive'

const routeSchema = z.object({
  origin: z.string().min(1),
  destination: z.string().min(1),
  distance_km: z.coerce.number().min(1).optional(),
  duration_minutes: z.coerce.number().min(1).optional(),
  stops: z.array(z.object({
    name: z.string().min(1, 'Stop name is required'),
    duration_minutes: z.coerce.number().min(1).optional(),
  })).optional(),
})

type RouteForm = z.infer<typeof routeSchema>

export default function RoutesPage() {
  const { agency } = useAuth()
  const qc = useQueryClient()
  const navigate = useNavigate()
  const toast = useToast()
  const [showRouteModal, setShowRouteModal] = useState(false)
  const [editingRoute, setEditingRoute] = useState<Route | null>(null)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')

  const { data: routes = [], isLoading: routesLoading } = useQuery({
    queryKey: ['routes', agency?.id],
    queryFn: () => routeApi.listByAgency(agency!.id),
    enabled: !!agency,
  })

  // Fetched only to derive the "trips on this route" count — shares the cache with TripsPage.
  const { data: trips = [] } = useQuery({
    queryKey: ['trips', agency?.id],
    queryFn: () => tripApi.list({ agency_id: agency?.id }),
    enabled: !!agency,
  })

  const createRoute = useMutation({
    mutationFn: (data: RouteForm) => routeApi.create({ ...data, agency_id: agency!.id }),
    onSuccess: (route) => {
      qc.invalidateQueries({ queryKey: ['routes'] })
      closeRouteModal()
      toast.success(`Route ${route.origin} → ${route.destination} created.`)
    },
    onError: () => toast.error('Could not create the route. Please try again.'),
  })

  const toggleActive = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) => routeApi.update(id, { is_active }),
    onSuccess: (route) => {
      qc.invalidateQueries({ queryKey: ['routes'] })
      toast.success(
        route.is_active
          ? `${route.origin} → ${route.destination} is now active.`
          : `${route.origin} → ${route.destination} was deactivated — find it under the Inactive tab to reactivate it.`
      )
    },
    onError: () => toast.error('Could not update the route. Please try again.'),
  })

  const updateRoute = useMutation({
    mutationFn: (data: RouteForm) => routeApi.update(editingRoute!.id, data),
    onSuccess: (route) => {
      qc.invalidateQueries({ queryKey: ['routes'] })
      closeRouteModal()
      toast.success(`Route ${route.origin} → ${route.destination} updated.`)
    },
    onError: () => toast.error('Could not update the route. Please try again.'),
  })

  const routeForm = useForm<RouteForm>({ resolver: zodResolver(routeSchema), defaultValues: { stops: [] } })
  const stopsArray = useFieldArray({ control: routeForm.control, name: 'stops' })

  function openCreateRoute() {
    routeForm.reset({ origin: '', destination: '', distance_km: undefined, duration_minutes: undefined, stops: [] })
    setShowRouteModal(true)
  }

  function openEditRoute(route: Route) {
    routeForm.reset({
      origin: route.origin,
      destination: route.destination,
      distance_km: route.distance_km ?? undefined,
      duration_minutes: route.duration_minutes ?? undefined,
      stops: (route.stops ?? []).map(s => ({ name: s.name, duration_minutes: s.duration_minutes ?? undefined })),
    })
    setEditingRoute(route)
  }

  function closeRouteModal() {
    setShowRouteModal(false)
    setEditingRoute(null)
    routeForm.reset({ stops: [] })
  }

  function handleRouteSubmit(data: RouteForm) {
    if (editingRoute) {
      updateRoute.mutate(data)
    } else {
      createRoute.mutate(data)
    }
  }

  const tripCountByRoute = trips.reduce<Record<string, number>>((acc, t) => {
    acc[t.route_id] = (acc[t.route_id] ?? 0) + 1
    return acc
  }, {})

  const filteredRoutes = routes.filter(r => {
    const matchesStatus = statusFilter === 'all' || (statusFilter === 'active' ? r.is_active : !r.is_active)
    const matchesSearch = search === '' ||
      r.origin.toLowerCase().includes(search.toLowerCase()) ||
      r.destination.toLowerCase().includes(search.toLowerCase())
    return matchesStatus && matchesSearch
  })

  const citiesServed = new Set(routes.flatMap(r => [r.origin, r.destination])).size
  const routesWithDistance = routes.filter(r => r.distance_km != null)
  const avgDistance = routesWithDistance.length
    ? Math.round(routesWithDistance.reduce((s, r) => s + (r.distance_km ?? 0), 0) / routesWithDistance.length)
    : null

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
      key: 'stops',
      header: 'Stops',
      render: (r: Route) => {
        const stops = r.stops ?? []
        if (stops.length === 0) return <span className="text-xs text-gray-400">Direct</span>
        const tooltip = stops.map((s, i) => `${i + 1}. ${s.name}${s.duration_minutes ? ` (+${s.duration_minutes}min)` : ''}`).join('\n')
        return (
          <span className="inline-flex items-center gap-1 text-xs text-dark" title={tooltip}>
            <MapPin className="w-3 h-3 text-gray-400" />
            {stops.length} stop{stops.length > 1 ? 's' : ''}
          </span>
        )
      },
    },
    {
      key: 'trips',
      header: 'Trips scheduled',
      render: (r: Route) => (
        <button
          onClick={e => { e.stopPropagation(); navigate('/schedule') }}
          className="text-sm font-semibold text-primary hover:underline disabled:no-underline disabled:text-gray-400"
          disabled={!tripCountByRoute[r.id]}
        >
          {tripCountByRoute[r.id] ?? 0}
        </button>
      ),
    },
    {
      key: 'is_active',
      header: 'Status',
      render: (r: Route) => <Badge label={r.is_active ? 'active' : 'inactive'} color={r.is_active ? 'success' : 'secondary'} />,
    },
    {
      key: 'actions',
      header: '',
      headerClassName: 'text-right',
      className: 'text-right',
      render: (r: Route) => (
        <button
          onClick={e => { e.stopPropagation(); toggleActive.mutate({ id: r.id, is_active: !r.is_active }) }}
          disabled={toggleActive.isPending}
          className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium transition disabled:opacity-50 ${
            r.is_active
              ? 'text-gray-500 hover:text-error hover:bg-red-50'
              : 'text-success hover:bg-green-50'
          }`}
          title={r.is_active ? 'Deactivate this route' : 'Reactivate this route'}
        >
          <Power className="w-3.5 h-3.5" />
          {r.is_active ? 'Deactivate' : 'Activate'}
        </button>
      ),
    },
  ]

  return (
    <div>
      <Header
        title="Routes"
        subtitle="Manage the origins and destinations your agency serves"
        actions={
          <div className="flex gap-2">
            <Button variant="outline" size="sm" leftIcon={<CalendarClock className="w-4 h-4" />} onClick={() => navigate('/schedule')}>
              Manage Trips
            </Button>
            <Button size="sm" leftIcon={<Plus className="w-4 h-4" />} onClick={openCreateRoute}>
              New Route
            </Button>
          </div>
        }
      />

      {/* Quick stats */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[
          { label: 'Total routes', value: routes.length, icon: RouteIcon, color: 'text-primary bg-primary/10' },
          { label: 'Active routes', value: routes.filter(r => r.is_active).length, icon: Power, color: 'text-success bg-green-100' },
          { label: 'Cities served', value: citiesServed, icon: MapPinned, color: 'text-secondary bg-secondary/20' },
          { label: 'Avg. distance', value: avgDistance != null ? `${avgDistance} km` : '—', icon: Ruler, color: 'text-warning bg-amber-100' },
        ].map(s => (
          <Card key={s.label} className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${s.color}`}>
              <s.icon className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xl font-extrabold text-dark">{s.value}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </div>
          </Card>
        ))}
      </div>

      <Card padding={false}>
        {/* Search + status filter */}
        <div className="flex flex-wrap items-center gap-3 px-5 py-3 border-b border-gray-100">
          <div className="flex items-center gap-2 flex-1 min-w-[200px]">
            <Search className="w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by origin or destination…"
              className="flex-1 text-sm bg-transparent focus:outline-none"
            />
          </div>
          <div className="flex gap-2">
            {(['all', 'active', 'inactive'] as StatusFilter[]).map(s => {
              const count = s === 'all' ? routes.length : routes.filter(r => (s === 'active' ? r.is_active : !r.is_active)).length
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
        </div>
        {filteredRoutes.length === 0 && !routesLoading ? (
          <EmptyState
            icon={RouteIcon}
            title="No routes found"
            description="Create a route first, then schedule trips on it."
            action={{ label: 'Create a route', onClick: openCreateRoute }}
          />
        ) : (
          <DataTable columns={routeColumns} data={filteredRoutes} loading={routesLoading} rowKey={r => r.id} onRowClick={openEditRoute} />
        )}
      </Card>

      {/* Create / Edit Route Modal */}
      <Modal
        open={showRouteModal || !!editingRoute}
        onClose={closeRouteModal}
        title={editingRoute ? 'Edit Route' : 'Create New Route'}
        size="lg"
      >
        <form onSubmit={routeForm.handleSubmit(handleRouteSubmit)} className="space-y-4">
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

          {/* Stops */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <div>
                <p className="text-sm font-medium text-dark">Stops <span className="text-gray-400 font-normal">(optional)</span></p>
                <p className="text-xs text-gray-400">Intermediate cities passengers can board or alight at, in travel order.</p>
              </div>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                leftIcon={<Plus className="w-3.5 h-3.5" />}
                onClick={() => stopsArray.append({ name: '', duration_minutes: undefined })}
              >
                Add stop
              </Button>
            </div>
            {stopsArray.fields.length > 0 && (
              <div className="space-y-2">
                {stopsArray.fields.map((field, i) => (
                  <div key={field.id} className="flex items-start gap-2">
                    <span className="text-xs text-gray-400 w-4 shrink-0 mt-3">{i + 1}.</span>
                    <div className="flex-1">
                      <Input
                        {...routeForm.register(`stops.${i}.name` as const)}
                        placeholder="Stop name, e.g. Atakpamé"
                        error={!!routeForm.formState.errors.stops?.[i]?.name}
                      />
                      {routeForm.formState.errors.stops?.[i]?.name && (
                        <p className="text-xs text-error mt-1">{routeForm.formState.errors.stops[i]?.name?.message}</p>
                      )}
                    </div>
                    <Input
                      {...routeForm.register(`stops.${i}.duration_minutes` as const)}
                      type="number"
                      min={1}
                      placeholder="Minutes from previous"
                      className="w-44"
                    />
                    <button
                      type="button"
                      onClick={() => stopsArray.remove(i)}
                      className="p-2.5 rounded-lg text-gray-400 hover:text-error hover:bg-red-50 transition shrink-0"
                      title="Remove stop"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {(createRoute.error || updateRoute.error) && (
            <p className="text-sm text-error bg-red-50 px-3 py-2 rounded-lg">
              {((editingRoute ? updateRoute.error : createRoute.error) as Error).message}
            </p>
          )}
          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={closeRouteModal}>Cancel</Button>
            <Button type="submit" loading={editingRoute ? updateRoute.isPending : createRoute.isPending}>
              {editingRoute ? 'Save Changes' : 'Create Route'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
