import {
  DollarSign, Ticket, Bus, Star, AlertCircle,
  Users, ArrowRight, TrendingUp, Clock,
} from 'lucide-react'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import Header from '../components/layout/Header'
import StatCard from '../components/ui/StatCard'
import { Card, CardHeader, CardTitle } from '../components/ui/Card'
import Badge from '../components/ui/Badge'
import { formatCurrency, formatDateTime, statusColor } from '../utils/format'
import { reviewApi } from '../api/reviews'
import { bookingApi } from '../api/bookings'
import { analyticsApi } from '../api/analytics'
import { useAuth } from '../contexts/AuthContext'

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

export default function DashboardPage() {
  const navigate = useNavigate()
  const { agency } = useAuth()

  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats', agency?.id],
    queryFn: () => analyticsApi.dashboard(agency!.id),
    enabled: !!agency,
  })

  const { data: recentTransactions = [] } = useQuery({
    queryKey: ['dashboard-recent-transactions', agency?.id],
    queryFn: () =>
      bookingApi.listTransactions({ agency_id: agency!.id, page: 1, size: 5 }).then(r => r.items),
    enabled: !!agency,
  })

  const { data: reviews = [] } = useQuery({
    queryKey: ['reviews', agency?.id],
    queryFn: () => reviewApi.listByAgency(agency!.id),
    enabled: !!agency,
  })

  const s = stats

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
          value={statsLoading ? '…' : formatCurrency(s?.revenue_this_month ?? 0)}
          icon={DollarSign}
          trend={s?.revenue_trend_pct ?? undefined}
          trendLabel="vs last month"
          color="success"
        />
        <StatCard
          label="Bookings (this month)"
          value={statsLoading ? '…' : (s?.bookings_this_month ?? 0)}
          icon={Ticket}
          trend={s?.bookings_trend_pct ?? undefined}
          color="primary"
        />
        <StatCard
          label="Active trips today"
          value={statsLoading ? '…' : (s?.active_trips_today ?? 0)}
          icon={Bus}
          color="warning"
        />
        <StatCard
          label="Average rating"
          value={s?.average_rating != null ? `${s.average_rating.toFixed(1)} / 5` : 'No ratings yet'}
          icon={Star}
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
            <p className="text-2xl font-extrabold text-dark">{s?.cancelled_this_month ?? 0}</p>
            <p className="text-xs text-gray-500">Cancelled this month</p>
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
            <p className="text-2xl font-extrabold text-dark">{s?.active_customers ?? 0}</p>
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
            <p className="text-2xl font-extrabold text-dark">{formatCurrency(s?.net_revenue_this_month ?? 0)}</p>
            <p className="text-xs text-gray-500">
              Net revenue (after {s ? (s.platform_fee_rate * 100).toFixed(0) : '…'}% fee)
            </p>
          </div>
        </div>
      </div>

      {/* Revenue chart + recent bookings */}
      <div className="grid grid-cols-5 gap-4 mb-6">
        {/* Chart */}
        <Card className="col-span-3">
          <CardHeader>
            <CardTitle>Revenue Trend</CardTitle>
            <span className="text-xs text-gray-400">Last {s?.revenue_trend.length ?? 0} months</span>
          </CardHeader>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={s?.revenue_trend ?? []} margin={{ top: 5, right: 5, left: 0, bottom: 0 }}>
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
              { label: 'Departures scheduled', value: s?.departures_scheduled_today ?? 0, icon: Bus },
              { label: 'Check-ins pending', value: s?.checkins_pending_today ?? 0, icon: Clock },
              { label: 'New bookings', value: s?.new_bookings_today ?? 0, icon: Ticket },
              { label: 'Cancelled today', value: s?.cancelled_today ?? 0, icon: AlertCircle },
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
                onClick={() => navigate('/transactions')}
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
                {recentTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-5 py-6 text-center text-gray-400 text-sm">
                      No transactions yet.
                    </td>
                  </tr>
                ) : (
                  recentTransactions.map(tx => (
                    <tr key={tx.id} className="border-b border-gray-50 hover:bg-gray-50/50 transition">
                      <td className="px-5 py-3">
                        <p className="font-medium text-dark">{tx.passenger_name}</p>
                        <p className="text-xs text-gray-400">{formatDateTime(tx.created_at)}</p>
                      </td>
                      <td className="px-5 py-3 text-gray-600 text-xs">
                        {tx.trip?.route ? `${tx.trip.route.origin} → ${tx.trip.route.destination}` : '—'}
                      </td>
                      <td className="px-5 py-3 text-right font-semibold text-dark">{formatCurrency(tx.total_price)}</td>
                      <td className="px-5 py-3">
                        <Badge
                          label={tx.payment?.status ?? tx.status}
                          color={statusColor(tx.payment?.status ?? tx.status) as BadgeColor}
                          dot
                        />
                      </td>
                    </tr>
                  ))
                )}
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
            {reviews.length === 0 ? (
              <p className="text-xs text-gray-400 text-center py-4">No reviews yet.</p>
            ) : (
              reviews.slice(0, 4).map(r => (
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
                    {r.comment && <p className="text-xs text-gray-500 line-clamp-2">{r.comment}</p>}
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
              ))
            )}
          </div>
        </Card>
      </div>
    </div>
  )
}
