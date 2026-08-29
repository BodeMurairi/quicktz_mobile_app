import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  DollarSign, TrendingUp, ArrowDownLeft, ArrowRight,
  Download, BarChart2, Receipt,
} from 'lucide-react'
import {
  BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell,
} from 'recharts'
import Header from '../../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import StatCard from '../../components/ui/StatCard'
import { formatCurrency, formatDateTime } from '../../utils/format'
import { exportCsv, exportPdf } from '../../utils/export'
import { analyticsApi } from '../../api/analytics'
import { bookingApi } from '../../api/bookings'
import { useAuth } from '../../contexts/AuthContext'

const PERIODS = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'] as const
type Period = (typeof PERIODS)[number]

const PIE_COLORS = ['#2E5E99', '#27AE60', '#F39C12', '#7BA4D0', '#9B59B6']

const METHOD_LABELS: Record<string, string> = {
  mobile_money: 'Mobile Money',
  tmoney: 'T-Money',
  flooz: 'Flooz',
  bank_transfer: 'Bank Transfer',
  cash: 'Cash',
  simulated: 'Simulated',
  unknown: 'Unknown',
}

export default function FinancePage() {
  const navigate = useNavigate()
  const { agency } = useAuth()
  const [period, setPeriod] = useState<Period>('Monthly')

  const { data: finance, isLoading: financeLoading } = useQuery({
    queryKey: ['finance-summary', agency?.id, period],
    queryFn: () => analyticsApi.finance(agency!.id, period.toLowerCase() as 'weekly' | 'monthly' | 'quarterly' | 'yearly'),
    enabled: !!agency,
  })

  // Capped at 100 (the API's page-size limit) — same cap used everywhere else in
  // this app. Good enough for a CSV/PDF snapshot; the Transactions page is the
  // source of truth for the complete, paginated history.
  const { data: exportRows = [] } = useQuery({
    queryKey: ['finance-export-rows', agency?.id],
    queryFn: () => bookingApi.listTransactions({ agency_id: agency!.id, page: 1, size: 100 }).then(r => r.items),
    enabled: !!agency,
  })

  function handleExport() {
    exportCsv(
      exportRows.map(t => ({
        Date: formatDateTime(t.created_at),
        Passenger: t.passenger_name,
        Route: t.trip?.route ? `${t.trip.route.origin} → ${t.trip.route.destination}` : '—',
        'Amount (XOF)': t.total_price,
        Method: t.payment?.payment_method ?? '—',
        Status: t.payment?.status ?? t.status,
        'Booking ID': t.id,
      })),
      'transactions'
    )
  }

  function handleExportPdf() {
    exportPdf(
      'Transaction History',
      ['Date', 'Passenger', 'Route', 'Amount', 'Status'],
      exportRows.map(t => [
        formatDateTime(t.created_at),
        t.passenger_name,
        t.trip?.route ? `${t.trip.route.origin} → ${t.trip.route.destination}` : '—',
        formatCurrency(t.total_price),
        t.payment?.status ?? t.status,
      ]),
      'transactions'
    )
  }

  const f = finance
  const feePct = f ? (f.platform_fee_rate * 100).toFixed(0) : '3'

  return (
    <div>
      <Header
        title="Financial Management"
        subtitle="Revenue, commissions, and transaction history"
        actions={
          <Button variant="outline" size="sm" leftIcon={<Download className="w-4 h-4" />} onClick={handleExport}>
            Export
          </Button>
        }
      />

      {/* Transaction history — full recap, filters, and actions now live on their own page */}
      <Card className="mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
              <Receipt className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h3 className="section-title mb-0.5">Transaction History</h3>
              <p className="text-sm text-gray-500">
                {f?.total_bookings ?? 0} transactions · full recap, filters by date/status/method, and cancel/complete actions
              </p>
            </div>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={handleExport} leftIcon={<Download className="w-3.5 h-3.5" />}>CSV</Button>
            <Button variant="outline" size="sm" onClick={handleExportPdf} leftIcon={<Download className="w-3.5 h-3.5" />}>PDF</Button>
            <Button size="sm" rightIcon={<ArrowRight className="w-3.5 h-3.5" />} onClick={() => navigate('/transactions')}>
              View Transactions
            </Button>
          </div>
        </div>
      </Card>

      {/* KPIs */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <StatCard label="Gross revenue" value={financeLoading ? '…' : formatCurrency(f?.gross_revenue ?? 0)} icon={DollarSign} color="success" />
        <StatCard label={`Net revenue (after ${feePct}% fee)`} value={financeLoading ? '…' : formatCurrency(f?.net_revenue ?? 0)} icon={TrendingUp} color="primary" />
        <StatCard label="Platform commission paid" value={financeLoading ? '…' : formatCurrency(f?.commission_paid ?? 0)} icon={BarChart2} color="warning" />
        <StatCard label="Total refunds issued" value={financeLoading ? '…' : formatCurrency(f?.total_refunds ?? 0)} icon={ArrowDownLeft} color="error" />
      </div>

      {/* Revenue bar chart */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Revenue vs Net Earnings</CardTitle>
            <div className="flex gap-1">
              {PERIODS.map(p => (
                <button
                  key={p}
                  onClick={() => setPeriod(p)}
                  className={`px-2.5 py-1 rounded-lg text-xs font-medium transition ${
                    period === p ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                  }`}
                >
                  {p}
                </button>
              ))}
            </div>
          </CardHeader>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={f?.revenue_trend ?? []} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
              <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#9ca3af' }} />
              <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} tickFormatter={v => `${(v / 1_000_000).toFixed(1)}M`} />
              <Tooltip
                formatter={(v: number, name: string) => [formatCurrency(v), name === 'revenue' ? 'Gross' : 'Net']}
                contentStyle={{ borderRadius: 12, fontSize: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
              />
              <Legend />
              <Bar dataKey="revenue" fill="#2E5E99" radius={[4, 4, 0, 0]} name="Gross Revenue" />
              <Bar dataKey="net" fill="#27AE60" radius={[4, 4, 0, 0]} name="Net Revenue" />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        {/* Payment breakdown pie */}
        <Card>
          <CardHeader>
            <CardTitle>Payment Methods</CardTitle>
          </CardHeader>
          {!f || f.payment_methods.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-10">No transactions yet.</p>
          ) : (
            <>
              <ResponsiveContainer width="100%" height={180}>
                <PieChart>
                  <Pie data={f.payment_methods} cx="50%" cy="50%" innerRadius={50} outerRadius={75} dataKey="pct" paddingAngle={3}>
                    {f.payment_methods.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => [`${v}%`, 'Share']} contentStyle={{ borderRadius: 10, fontSize: 11 }} />
                </PieChart>
              </ResponsiveContainer>
              <div className="grid grid-cols-2 gap-2 mt-2">
                {f.payment_methods.map((p, i) => (
                  <div key={p.method} className="flex items-center gap-1.5">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />
                    <span className="text-xs text-gray-500">
                      {METHOD_LABELS[p.method] ?? p.method}: <strong>{p.pct}%</strong>
                    </span>
                  </div>
                ))}
              </div>
            </>
          )}
        </Card>
      </div>

      {/* Bookings trend */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Booking Volume</CardTitle>
            <span className="text-xs text-gray-400">{f?.total_bookings ?? 0} total in period</span>
          </CardHeader>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={f?.revenue_trend ?? []} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
              <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#9ca3af' }} />
              <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} />
              <Tooltip contentStyle={{ borderRadius: 12, fontSize: 12 }} />
              <Line type="monotone" dataKey="bookings" stroke="#2E5E99" strokeWidth={2} dot={{ r: 4 }} />
            </LineChart>
          </ResponsiveContainer>
        </Card>

        {/* Budgeting summary */}
        <Card>
          <CardHeader>
            <CardTitle>Budgeting Summary</CardTitle>
          </CardHeader>
          <div className="space-y-3 text-sm">
            {[
              { label: 'Avg revenue / trip', value: formatCurrency(Math.round(f?.avg_revenue_per_trip ?? 0)) },
              { label: 'Platform fee rate', value: `${feePct}%` },
              { label: 'Commission this period', value: formatCurrency(f?.commission_paid ?? 0) },
              { label: 'Net margin', value: `${(f?.net_margin_pct ?? 0).toFixed(1)}%` },
            ].map(item => (
              <div key={item.label} className="flex justify-between py-2 border-b border-gray-50 last:border-0">
                <span className="text-gray-500">{item.label}</span>
                <span className="font-semibold text-dark">{item.value}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
