import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
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
import { mockRevenueData, mockTransactions } from '../../utils/mockData'
import { formatCurrency, formatDateTime, COMMISSION_RATE } from '../../utils/format'
import { exportCsv, exportPdf } from '../../utils/export'

const PERIODS = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'] as const
type Period = (typeof PERIODS)[number]

const PIE_COLORS = ['#2E5E99', '#27AE60', '#F39C12', '#7BA4D0']

const paymentBreakdown = [
  { name: 'Mobile Money', value: 45 },
  { name: 'T-Money', value: 28 },
  { name: 'Flooz', value: 18 },
  { name: 'Bank Transfer', value: 9 },
]

export default function FinancePage() {
  const navigate = useNavigate()
  const [period, setPeriod] = useState<Period>('Monthly')

  const totalRevenue = mockRevenueData.reduce((s, d) => s + d.revenue, 0)
  const totalNet     = mockRevenueData.reduce((s, d) => s + d.net, 0)
  const totalComm    = mockRevenueData.reduce((s, d) => s + d.commission, 0)
  const totalBookings = mockRevenueData.reduce((s, d) => s + d.bookings, 0)

  const refunds = mockTransactions.filter(t => t.status === 'refunded')
  const refundTotal = refunds.reduce((s, t) => s + t.amount, 0)

  function handleExport() {
    exportCsv(
      mockTransactions.map(t => ({
        Date: formatDateTime(t.date),
        Passenger: t.passenger,
        Route: t.route,
        'Amount (XOF)': t.amount,
        'Net (XOF)': Math.round(t.amount * (1 - COMMISSION_RATE)),
        Method: t.method,
        Status: t.status,
        'Booking ID': t.booking_id,
      })),
      'transactions'
    )
  }

  function handleExportPdf() {
    exportPdf(
      'Transaction History',
      ['Date', 'Passenger', 'Route', 'Amount', 'Status'],
      mockTransactions.map(t => [
        formatDateTime(t.date),
        t.passenger,
        t.route,
        formatCurrency(t.amount),
        t.status,
      ]),
      'transactions'
    )
  }

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
                {mockTransactions.length} recent transactions · full recap, filters by date/status/method, and cancel/complete actions
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
        <StatCard label="Gross revenue (7 months)" value={formatCurrency(totalRevenue)} icon={DollarSign} trend={8.2} color="success" />
        <StatCard label="Net revenue (after 3% fee)" value={formatCurrency(totalNet)} icon={TrendingUp} trend={8.2} color="primary" />
        <StatCard label="Platform commission paid" value={formatCurrency(totalComm)} icon={BarChart2} color="warning" />
        <StatCard label="Total refunds issued" value={formatCurrency(refundTotal)} icon={ArrowDownLeft} color="error" />
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
            <BarChart data={mockRevenueData} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
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
          <ResponsiveContainer width="100%" height={180}>
            <PieChart>
              <Pie data={paymentBreakdown} cx="50%" cy="50%" innerRadius={50} outerRadius={75} dataKey="value" paddingAngle={3}>
                {paymentBreakdown.map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip formatter={(v) => [`${v}%`, 'Share']} contentStyle={{ borderRadius: 10, fontSize: 11 }} />
            </PieChart>
          </ResponsiveContainer>
          <div className="grid grid-cols-2 gap-2 mt-2">
            {paymentBreakdown.map((p, i) => (
              <div key={p.name} className="flex items-center gap-1.5">
                <div className="w-2.5 h-2.5 rounded-full" style={{ background: PIE_COLORS[i] }} />
                <span className="text-xs text-gray-500">{p.name}: <strong>{p.value}%</strong></span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Bookings trend */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Booking Volume</CardTitle>
            <span className="text-xs text-gray-400">{totalBookings} total in period</span>
          </CardHeader>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={mockRevenueData} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
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
              { label: 'Avg revenue / trip', value: formatCurrency(Math.round(totalRevenue / totalBookings)) },
              { label: 'Platform fee rate', value: `${(COMMISSION_RATE * 100).toFixed(0)}%` },
              { label: 'Commission this period', value: formatCurrency(totalComm) },
              { label: 'Net margin', value: `${((totalNet / totalRevenue) * 100).toFixed(1)}%` },
            ].map(item => (
              <div key={item.label} className="flex justify-between py-2 border-b border-gray-50 last:border-0">
                <span className="text-gray-500">{item.label}</span>
                <span className="font-semibold text-dark">{item.value}</span>
              </div>
            ))}
            <div className="mt-2 px-3 py-2.5 rounded-xl bg-green-50 text-success text-xs font-medium flex items-center gap-2">
              <TrendingUp className="w-4 h-4" />
              Revenue trending +8.2% vs previous period
            </div>
          </div>
        </Card>
      </div>
    </div>
  )
}
