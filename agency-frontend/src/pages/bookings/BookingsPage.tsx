import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, Download, Filter, Ticket } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import Header from '../../components/layout/Header'
import { Card } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import DataTable from '../../components/ui/DataTable'
import EmptyState from '../../components/ui/EmptyState'
import { bookingApi } from '../../api/bookings'
import { useAuth } from '../../contexts/AuthContext'
import type { Booking } from '../../types'
import { formatCurrency, formatDateTime, statusColor } from '../../utils/format'
import { exportCsv, exportPdf } from '../../utils/export'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

const STATUS_FILTERS = ['all', 'confirmed', 'pending', 'cancelled', 'completed']

export default function BookingsPage() {
  const { agency } = useAuth()
  const navigate = useNavigate()
  const [statusFilter, setStatusFilter] = useState('all')
  const [search, setSearch] = useState('')

  const { data: bookings = [], isLoading } = useQuery({
    queryKey: ['bookings', agency?.id],
    queryFn: () => bookingApi.list({ agency_id: agency!.id }),
    enabled: !!agency,
  })

  const filtered = bookings.filter(b => {
    const matchStatus = statusFilter === 'all' || b.status === statusFilter
    const matchSearch = search === '' ||
      b.passenger_name.toLowerCase().includes(search.toLowerCase()) ||
      b.id.toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchSearch
  })

  function handleExportCsv() {
    exportCsv(
      filtered.map(b => ({
        'Booking ID': b.id,
        'Passenger': b.passenger_name,
        'Phone': b.passenger_phone ?? '',
        'Trip ID': b.trip_id,
        'Status': b.status,
        'Price (XOF)': b.total_price,
        'Date': formatDateTime(b.created_at),
      })),
      'bookings'
    )
  }

  function handleExportPdf() {
    exportPdf(
      `Bookings — ${agency?.name ?? ''}`,
      ['ID', 'Passenger', 'Status', 'Price', 'Date'],
      filtered.map(b => [
        b.id.slice(0, 8),
        b.passenger_name,
        b.status,
        formatCurrency(b.total_price),
        formatDateTime(b.created_at),
      ]),
      'bookings'
    )
  }

  const columns = [
    {
      key: 'id',
      header: 'Booking ID',
      render: (b: Booking) => (
        <span className="font-mono text-xs text-gray-600">{b.id.slice(0, 8).toUpperCase()}</span>
      ),
    },
    {
      key: 'passenger_name',
      header: 'Passenger',
      render: (b: Booking) => (
        <div>
          <p className="font-medium text-dark text-sm">{b.passenger_name}</p>
          <p className="text-xs text-gray-400">{b.passenger_phone ?? '—'}</p>
        </div>
      ),
    },
    {
      key: 'route',
      header: 'Route',
      render: (b: Booking) => (
        <span className="text-sm text-gray-600">
          {b.trip?.route?.origin ?? '—'} → {b.trip?.route?.destination ?? '—'}
        </span>
      ),
    },
    {
      key: 'departure',
      header: 'Departure',
      render: (b: Booking) => (
        <span className="text-sm">{b.trip ? formatDateTime(b.trip.departure_datetime) : '—'}</span>
      ),
    },
    {
      key: 'total_price',
      header: 'Amount',
      render: (b: Booking) => (
        <span className="font-semibold text-dark">{formatCurrency(b.total_price)}</span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (b: Booking) => (
        <Badge label={b.status} color={statusColor(b.status) as BadgeColor} dot />
      ),
    },
    {
      key: 'created_at',
      header: 'Booked',
      render: (b: Booking) => (
        <span className="text-xs text-gray-400">{formatDateTime(b.created_at)}</span>
      ),
    },
  ]

  return (
    <div>
      <Header
        title="Bookings"
        subtitle={`${filtered.length} booking${filtered.length !== 1 ? 's' : ''} found`}
        actions={
          <Button
            onClick={() => navigate('/bookings/manual')}
            leftIcon={<Plus className="w-4 h-4" />}
          >
            Manual Booking
          </Button>
        }
      />

      {/* Summary cards */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[
          { label: 'Total', count: bookings.length, color: 'bg-primary/10 text-primary' },
          { label: 'Confirmed', count: bookings.filter(b => b.status === 'confirmed').length, color: 'bg-green-100 text-success' },
          { label: 'Pending', count: bookings.filter(b => b.status === 'pending').length, color: 'bg-amber-100 text-warning' },
          { label: 'Cancelled', count: bookings.filter(b => b.status === 'cancelled').length, color: 'bg-red-100 text-error' },
        ].map(s => (
          <div key={s.label} className="bg-white rounded-2xl shadow-card p-4 text-center">
            <p className={`text-2xl font-extrabold ${s.color.split(' ')[1]}`}>{s.count}</p>
            <p className="text-xs text-gray-500 mt-0.5">{s.label}</p>
          </div>
        ))}
      </div>

      <Card padding={false}>
        {/* Filters toolbar */}
        <div className="flex items-center gap-3 px-5 py-4 border-b border-gray-100 flex-wrap">
          <div className="flex gap-1">
            {STATUS_FILTERS.map(s => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition ${
                  statusFilter === s
                    ? 'bg-primary text-white'
                    : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                }`}
              >
                {s}
              </button>
            ))}
          </div>

          <div className="flex-1 min-w-[200px]">
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search passenger or booking ID…"
              className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
            />
          </div>

          <div className="flex gap-2 ml-auto">
            <Button variant="outline" size="sm" leftIcon={<Download className="w-3.5 h-3.5" />} onClick={handleExportCsv}>
              CSV
            </Button>
            <Button variant="outline" size="sm" leftIcon={<Download className="w-3.5 h-3.5" />} onClick={handleExportPdf}>
              PDF
            </Button>
          </div>
        </div>

        {filtered.length === 0 && !isLoading ? (
          <EmptyState
            icon={Ticket}
            title="No bookings found"
            description="Bookings will appear here once customers start reserving trips."
            action={{ label: 'Add manual booking', onClick: () => navigate('/bookings/manual') }}
          />
        ) : (
          <DataTable
            columns={columns}
            data={filtered}
            loading={isLoading}
            rowKey={b => b.id}
            onRowClick={b => navigate(`/bookings/${b.id}`)}
            emptyMessage="No bookings match your filters"
          />
        )}
      </Card>
    </div>
  )
}
