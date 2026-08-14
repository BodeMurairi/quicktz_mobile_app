import { useEffect, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Receipt, ChevronLeft, ChevronRight, CheckCircle2, XCircle,
  Calendar, MapPin, CreditCard, User as UserIcon, Ticket as TicketIcon,
} from 'lucide-react'
import Header from '../components/layout/Header'
import { Card } from '../components/ui/Card'
import Badge from '../components/ui/Badge'
import Modal from '../components/ui/Modal'
import Button from '../components/ui/Button'
import DataTable from '../components/ui/DataTable'
import EmptyState from '../components/ui/EmptyState'
import { bookingApi } from '../api/bookings'
import { useAuth } from '../contexts/AuthContext'
import { useToast } from '../contexts/ToastContext'
import { formatCurrency, formatDateTime, statusColor } from '../utils/format'
import { YEAR_OPTIONS, MONTH_OPTIONS, computeDateRange } from '../utils/periodFilter'
import type { Booking } from '../types'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

const TX_PAGE_SIZE = 20

const STATUS_OPTIONS = ['all', 'pending', 'completed', 'failed', 'refunded'] as const
type StatusFilter = (typeof STATUS_OPTIONS)[number]

const METHOD_OPTIONS = [
  { value: 'tmoney', label: 'T-Money' },
  { value: 'flooz', label: 'Flooz' },
  { value: 'bank_transfer', label: 'Bank Transfer' },
  { value: 'mobile_money', label: 'Mobile Money' },
  { value: 'cash', label: 'Cash' },
  { value: 'simulated', label: 'Simulated' },
]

function methodLabel(method?: string | null): string {
  if (!method) return '—'
  return METHOD_OPTIONS.find(m => m.value === method)?.label ?? method.replace('_', ' ')
}

function useTransactionCount(
  agencyId: string | undefined,
  dateRange: { from_date?: string; to_date?: string },
  status?: string
) {
  return useQuery({
    queryKey: ['tx-count', agencyId, dateRange.from_date, dateRange.to_date, status],
    queryFn: () =>
      bookingApi
        .listTransactions({ agency_id: agencyId!, status, ...dateRange, page: 1, size: 1 })
        .then(r => r.total),
    enabled: !!agencyId,
  })
}

export default function TransactionsPage() {
  const { agency } = useAuth()
  const qc = useQueryClient()
  const toast = useToast()

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [methodFilter, setMethodFilter] = useState<string>('all')
  const [yearFilter, setYearFilter] = useState<number | 'all'>('all')
  const [monthFilter, setMonthFilter] = useState<number | 'all'>('all')
  const [dateFilter, setDateFilter] = useState('')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<Booking | null>(null)

  const dateRange = computeDateRange(yearFilter, monthFilter, dateFilter)
  const hasPeriodFilter = yearFilter !== 'all' || !!dateFilter

  const allCount = useTransactionCount(agency?.id, dateRange)
  const completedCount = useTransactionCount(agency?.id, dateRange, 'completed')
  const pendingCount = useTransactionCount(agency?.id, dateRange, 'pending')
  const failedCount = useTransactionCount(agency?.id, dateRange, 'failed')
  const refundedCount = useTransactionCount(agency?.id, dateRange, 'refunded')

  const COUNTS: Record<StatusFilter, number | undefined> = {
    all: allCount.data,
    completed: completedCount.data,
    pending: pendingCount.data,
    failed: failedCount.data,
    refunded: refundedCount.data,
  }

  const { data: txResult, isLoading } = useQuery({
    queryKey: ['transactions', agency?.id, dateRange.from_date, dateRange.to_date, statusFilter, methodFilter, page],
    queryFn: () =>
      bookingApi.listTransactions({
        agency_id: agency!.id,
        status: statusFilter === 'all' ? undefined : statusFilter,
        payment_method: methodFilter === 'all' ? undefined : methodFilter,
        from_date: dateRange.from_date,
        to_date: dateRange.to_date,
        page,
        size: TX_PAGE_SIZE,
      }),
    enabled: !!agency,
  })
  const transactions = txResult?.items ?? []
  const total = txResult?.total ?? 0
  const totalPages = Math.max(1, Math.ceil(total / TX_PAGE_SIZE))

  useEffect(() => {
    setPage(1)
  }, [statusFilter, methodFilter, yearFilter, monthFilter, dateFilter])

  const updateStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: 'cancelled' | 'completed' }) =>
      bookingApi.updateTransactionStatus(id, agency!.id, status),
    onSuccess: (booking, variables) => {
      qc.invalidateQueries({ queryKey: ['transactions'] })
      qc.invalidateQueries({ queryKey: ['tx-count'] })
      setSelected(null)
      toast.success(
        `Transaction for ${booking.passenger_name} ${variables.status === 'cancelled' ? 'cancelled' : 'marked completed'}.`
      )
    },
    onError: () => toast.error('Could not update the transaction. Please try again.'),
  })

  const columns = [
    {
      key: 'created_at',
      header: 'Date',
      render: (t: Booking) => <span className="text-xs text-gray-500">{formatDateTime(t.created_at)}</span>,
    },
    {
      key: 'passenger_name',
      header: 'Passenger',
      render: (t: Booking) => <span className="font-medium text-dark text-sm">{t.passenger_name}</span>,
    },
    {
      key: 'route',
      header: 'Route',
      render: (t: Booking) => (
        <span className="text-xs text-gray-500">
          {t.trip?.route ? `${t.trip.route.origin} → ${t.trip.route.destination}` : '—'}
        </span>
      ),
    },
    {
      key: 'method',
      header: 'Method',
      render: (t: Booking) => <span className="text-xs text-gray-500">{methodLabel(t.payment?.payment_method)}</span>,
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (t: Booking) => <span className="font-semibold text-dark">{formatCurrency(t.total_price)}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      render: (t: Booking) => {
        const s = t.payment?.status ?? t.status
        return <Badge label={s} color={statusColor(s) as BadgeColor} dot />
      },
    },
    {
      key: 'actions',
      header: 'Quick update',
      render: (t: Booking) => {
        const payStatus = t.payment?.status
        const canComplete = payStatus === 'pending'
        const canCancel = t.status !== 'cancelled' && t.status !== 'completed'
        return (
          <div className="flex gap-1">
            {canComplete && (
              <button
                onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'completed' }) }}
                className="p-1.5 rounded-lg hover:bg-green-50 text-success transition"
                title="Mark completed"
              >
                <CheckCircle2 className="w-3.5 h-3.5" />
              </button>
            )}
            {canCancel && (
              <button
                onClick={e => { e.stopPropagation(); updateStatus.mutate({ id: t.id, status: 'cancelled' }) }}
                className="p-1.5 rounded-lg hover:bg-red-50 text-error transition"
                title="Cancel transaction"
              >
                <XCircle className="w-3.5 h-3.5" />
              </button>
            )}
            {!canComplete && !canCancel && <span className="text-xs text-gray-300">—</span>}
          </div>
        )
      },
    },
  ]

  return (
    <div>
      <Header title="Transactions" subtitle="Transaction recaps, history, and payment actions" />

      {/* Status recap / filter pills */}
      <div className="grid grid-cols-5 gap-4 mb-6">
        {STATUS_OPTIONS.map(s => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`text-left p-4 rounded-2xl shadow-card transition ${
              statusFilter === s ? 'bg-primary text-white' : 'bg-white hover:bg-gray-50'
            }`}
          >
            <p className={`text-xl font-extrabold ${statusFilter === s ? 'text-white' : 'text-dark'}`}>
              {COUNTS[s] ?? '—'}
            </p>
            <p className={`text-xs capitalize ${statusFilter === s ? 'text-white/80' : 'text-gray-500'}`}>
              {s === 'all' ? 'All transactions' : s}
            </p>
          </button>
        ))}
      </div>

      <Card padding={false}>
        {/* Period + method filters */}
        <div className="flex flex-wrap items-center gap-3 px-5 py-3 border-b border-gray-100">
          <div className="flex items-center gap-2 text-xs text-gray-500 font-medium">
            <Calendar className="w-3.5 h-3.5" />
            Period
          </div>
          <select
            value={yearFilter}
            onChange={e => { setYearFilter(e.target.value === 'all' ? 'all' : Number(e.target.value)); setDateFilter('') }}
            disabled={!!dateFilter}
            className="px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs disabled:opacity-40"
          >
            <option value="all">All years</option>
            {YEAR_OPTIONS.map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <select
            value={monthFilter}
            onChange={e => { setMonthFilter(e.target.value === 'all' ? 'all' : Number(e.target.value)); setDateFilter('') }}
            disabled={!!dateFilter || yearFilter === 'all'}
            className="px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs disabled:opacity-40"
          >
            <option value="all">All months</option>
            {MONTH_OPTIONS.map((m, i) => <option key={m} value={i}>{m}</option>)}
          </select>
          <span className="text-xs text-gray-400">or</span>
          <input
            type="date"
            value={dateFilter}
            onChange={e => setDateFilter(e.target.value)}
            className="px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs"
          />

          <div className="w-px h-5 bg-gray-200 mx-1" />

          <div className="flex items-center gap-2 text-xs text-gray-500 font-medium">
            <CreditCard className="w-3.5 h-3.5" />
            Method
          </div>
          <select
            value={methodFilter}
            onChange={e => setMethodFilter(e.target.value)}
            className="px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs"
          >
            <option value="all">All methods</option>
            {METHOD_OPTIONS.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
          </select>

          {(hasPeriodFilter || methodFilter !== 'all' || statusFilter !== 'all') && (
            <button
              onClick={() => { setYearFilter('all'); setMonthFilter('all'); setDateFilter(''); setMethodFilter('all'); setStatusFilter('all') }}
              className="text-xs text-primary hover:underline ml-auto"
            >
              Clear filters
            </button>
          )}
        </div>

        {transactions.length === 0 && !isLoading ? (
          <EmptyState
            icon={Receipt}
            title="No transactions found"
            description="Try a different period, status, or payment method."
          />
        ) : (
          <>
            <DataTable
              columns={columns}
              data={transactions}
              loading={isLoading}
              rowKey={t => t.id}
              onRowClick={setSelected}
            />
            <div className="flex items-center justify-between px-5 py-3 border-t border-gray-100">
              <p className="text-xs text-gray-500">
                Showing {(page - 1) * TX_PAGE_SIZE + 1}–{Math.min(page * TX_PAGE_SIZE, total)} of {total} transactions
              </p>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed transition"
                  aria-label="Previous page"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span className="text-xs text-gray-500 px-2 min-w-[90px] text-center">Page {page} of {totalPages}</span>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed transition"
                  aria-label="Next page"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          </>
        )}
      </Card>

      {/* Transaction detail modal */}
      <Modal open={!!selected} onClose={() => setSelected(null)} title="Transaction Details" size="lg">
        {selected && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-2xl font-extrabold text-dark">{formatCurrency(selected.total_price)}</p>
                <p className="text-xs text-gray-400">{formatDateTime(selected.created_at)}</p>
              </div>
              <Badge
                label={selected.payment?.status ?? selected.status}
                color={statusColor(selected.payment?.status ?? selected.status) as BadgeColor}
                dot
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 rounded-xl bg-background">
                <div className="flex items-center gap-1.5 text-xs text-gray-400 mb-1">
                  <UserIcon className="w-3.5 h-3.5" /> Passenger
                </div>
                <p className="text-sm font-medium text-dark">{selected.passenger_name}</p>
                <p className="text-xs text-gray-500">{selected.passenger_phone || '—'}</p>
              </div>
              <div className="p-3 rounded-xl bg-background">
                <div className="flex items-center gap-1.5 text-xs text-gray-400 mb-1">
                  <MapPin className="w-3.5 h-3.5" /> Route
                </div>
                <p className="text-sm font-medium text-dark">
                  {selected.trip?.route ? `${selected.trip.route.origin} → ${selected.trip.route.destination}` : '—'}
                </p>
                <p className="text-xs text-gray-500">
                  {selected.trip ? formatDateTime(selected.trip.departure_datetime) : '—'}
                  {selected.trip?.bus_number ? ` · ${selected.trip.bus_number}` : ''}
                </p>
              </div>
              <div className="p-3 rounded-xl bg-background">
                <div className="flex items-center gap-1.5 text-xs text-gray-400 mb-1">
                  <CreditCard className="w-3.5 h-3.5" /> Payment
                </div>
                <p className="text-sm font-medium text-dark">{methodLabel(selected.payment?.payment_method)}</p>
                <p className="text-xs text-gray-500">
                  {selected.payment?.paid_at ? `Paid ${formatDateTime(selected.payment.paid_at)}` : 'Not yet paid'}
                </p>
              </div>
              <div className="p-3 rounded-xl bg-background">
                <div className="flex items-center gap-1.5 text-xs text-gray-400 mb-1">
                  <TicketIcon className="w-3.5 h-3.5" /> Ticket
                </div>
                <p className="text-sm font-medium text-dark">{selected.ticket?.ticket_code ?? '—'}</p>
                <p className="text-xs text-gray-500 capitalize">{selected.ticket?.status ?? '—'}</p>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs text-gray-400 px-1">
              <span>Booking status: <span className="font-medium text-dark capitalize">{selected.status}</span></span>
              <span>ID: {selected.id.slice(0, 8)}</span>
            </div>

            <div className="flex justify-end gap-3 pt-2">
              {selected.payment?.status === 'pending' && (
                <Button
                  variant="outline"
                  onClick={() => updateStatus.mutate({ id: selected.id, status: 'completed' })}
                  loading={updateStatus.isPending}
                >
                  Mark Completed
                </Button>
              )}
              {selected.status !== 'cancelled' && selected.status !== 'completed' && (
                <Button
                  variant="danger"
                  onClick={() => updateStatus.mutate({ id: selected.id, status: 'cancelled' })}
                  loading={updateStatus.isPending}
                >
                  Cancel Transaction
                </Button>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
