import {
  DollarSign, Ticket, Bus, Star, AlertCircle,
  Users, ArrowRight, TrendingUp, Clock,
} from 'lucide-react'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import { useNavigate } from 'react-router-dom'
import Header from '../components/layout/Header'
import StatCard from '../components/ui/StatCard'
import { Card, CardHeader, CardTitle } from '../components/ui/Card'
import Badge from '../components/ui/Badge'
import {
  mockDashboardStats, mockRevenueData, mockTransactions, mockReviews,
} from '../utils/mockData'
import { formatCurrency, formatDateTime, statusColor } from '../utils/format'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

export default function DashboardPage() {
  const navigate = useNavigate()
  const s = mockDashboardStats

  return (
    <div>
      <Header
        title="Dashboard"
        subtitle={`Today is ${new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}`}
      />

      {/* KPI row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          label="Revenue (this month)"
          value={formatCurrency(s.totalRevenue)}
          icon={DollarSign}
          trend={8.2}
          trendLabel="vs last month"
          color="success"
        />
        <StatCard
          label="Bookings (this month)"
          value={s.totalBookings}
          icon={Ticket}
          trend={5.1}
          color="primary"
        />
        <StatCard
          label="Active trips today"
          value={s.activeTrips}
          icon={Bus}
          color="warning"
        />
        <StatCard
          label="Average rating"
          value={`${s.avgRating} / 5`}
          icon={Star}
          trend={-2.3}
          color="error"
        />
      </div>

      {/* Secondary stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-2xl shadow-card p-4 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center">
            <AlertCircle className="w-5 h-5 text-warning" />
          </div>
          <div>
            <p className="text-2xl font-extrabold text-dark">{s.pendingCancellations}</p>
            <p className="text-xs text-gray-500">Pending cancellations</p>
          </div>
          <button
            onClick={() => navigate('/bookings?status=cancelled')}
            className="ml-auto text-primary hover:text-primary-700"
          >
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
        <div className="bg-white rounded-2xl shadow-card p-4 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
            <Users className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-2xl font-extrabold text-dark">{s.activeCustomers}</p>
            <p className="text-xs text-gray-500">Active customers</p>
          </div>
          <button onClick={() => navigate('/customers')} className="ml-auto text-primary hover:text-primary-700">
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
        <div className="bg-white rounded-2xl shadow-card p-4 flex items-center gap-4">
          <div className="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
            <TrendingUp className="w-5 h-5 text-success" />
          </div>
          <div>
            <p className="text-2xl font-extrabold text-dark">{formatCurrency(s.netRevenue)}</p>
            <p className="text-xs text-gray-500">Net revenue (after 3% fee)</p>
          </div>
        </div>
      </div>

      {/* Revenue chart + recent bookings */}
      <div className="grid grid-cols-5 gap-4 mb-6">
        {/* Chart */}
        <Card className="col-span-3">
          <CardHeader>
            <CardTitle>Revenue Trend</CardTitle>
            <span className="text-xs text-gray-400">Last 7 months</span>
          </CardHeader>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={mockRevenueData} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#2E5E99" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#2E5E99" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#9ca3af' }} />
              <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} tickFormatter={v => `${(v / 1_000_000).toFixed(1)}M`} />
              <Tooltip
                formatter={(v: number) => [formatCurrency(v), 'Revenue']}
                contentStyle={{ borderRadius: 12, fontSize: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}
              />
              <Area type="monotone" dataKey="revenue" stroke="#2E5E99" strokeWidth={2} fill="url(#rev)" />
            </AreaChart>
          </ResponsiveContainer>
        </Card>

        {/* Quick stats */}
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Today's Activity</CardTitle>
          </CardHeader>
          <div className="space-y-3">
            {[
              { label: 'Departures scheduled', value: '6', icon: Bus },
              { label: 'Check-ins pending', value: '24', icon: Clock },
              { label: 'New bookings', value: '11', icon: Ticket },
              { label: 'Cancelled today', value: '2', icon: AlertCircle },
            ].map(item => (
              <div key={item.label} className="flex items-center gap-3 py-2 border-b border-gray-50 last:border-0">
                <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <item.icon className="w-4 h-4 text-primary" />
                </div>
                <span className="text-sm text-gray-600 flex-1">{item.label}</span>
                <span className="font-bold text-dark">{item.value}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Recent transactions + recent reviews */}
      <div className="grid grid-cols-5 gap-4">
        {/* Recent transactions */}
        <Card className="col-span-3" padding={false}>
          <div className="p-5 pb-0">
            <CardHeader>
              <CardTitle>Recent Transactions</CardTitle>
              <button
                onClick={() => navigate('/finance/transactions')}
                className="text-xs text-primary font-medium hover:underline flex items-center gap-1"
              >
                View all <ArrowRight className="w-3 h-3" />
              </button>
            </CardHeader>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-y border-gray-50">
                  <th className="text-left px-5 py-2.5 text-xs text-gray-400 font-medium">Passenger</th>
                  <th className="text-left px-5 py-2.5 text-xs text-gray-400 font-medium">Route</th>
                  <th className="text-right px-5 py-2.5 text-xs text-gray-400 font-medium">Amount</th>
                  <th className="text-left px-5 py-2.5 text-xs text-gray-400 font-medium">Status</th>
                </tr>
              </thead>
              <tbody>
                {mockTransactions.slice(0, 5).map(tx => (
                  <tr key={tx.id} className="border-b border-gray-50 hover:bg-gray-50/50 transition">
                    <td className="px-5 py-3">
                      <p className="font-medium text-dark">{tx.passenger}</p>
                      <p className="text-xs text-gray-400">{formatDateTime(tx.date)}</p>
                    </td>
                    <td className="px-5 py-3 text-gray-600 text-xs">{tx.route}</td>
                    <td className="px-5 py-3 text-right font-semibold text-dark">{formatCurrency(tx.amount)}</td>
                    <td className="px-5 py-3">
                      <Badge label={tx.status} color={statusColor(tx.status) as BadgeColor} dot />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Recent reviews */}
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Recent Reviews</CardTitle>
            <button
              onClick={() => navigate('/customers/reviews')}
              className="text-xs text-primary font-medium hover:underline flex items-center gap-1"
            >
              View all <ArrowRight className="w-3 h-3" />
            </button>
          </CardHeader>
          <div className="space-y-3">
            {mockReviews.slice(0, 4).map(r => (
              <div key={r.id} className="flex gap-3 py-2 border-b border-gray-50 last:border-0">
                <div className="w-7 h-7 rounded-full bg-secondary/20 flex items-center justify-center shrink-0">
                  <span className="text-xs font-bold text-primary">{r.customer_name[0]}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5 mb-0.5">
                    <p className="text-xs font-semibold text-dark">{r.customer_name}</p>
                    <div className="flex">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} className={`w-2.5 h-2.5 ${i < r.rating ? 'text-warning fill-warning' : 'text-gray-200'}`} />
                      ))}
                    </div>
                  </div>
                  <p className="text-xs text-gray-500 line-clamp-2">{r.comment}</p>
                  {!r.reply && (
                    <button
                      onClick={() => navigate('/customers/reviews')}
                      className="text-[11px] text-primary font-medium mt-1 hover:underline"
                    >
                      Reply
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
