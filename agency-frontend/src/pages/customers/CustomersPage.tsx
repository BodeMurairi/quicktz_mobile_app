import { useState } from 'react'
import { Users, Star, MessageCircle, Crown, Search } from 'lucide-react'
import Header from '../../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import StatCard from '../../components/ui/StatCard'
import DataTable from '../../components/ui/DataTable'
import EmptyState from '../../components/ui/EmptyState'
import Modal from '../../components/ui/Modal'
import { FormField, Textarea } from '../../components/ui/FormField'
import { mockCustomers, mockReviews } from '../../utils/mockData'
import { formatCurrency, formatDate } from '../../utils/format'
import type { Customer, Review } from '../../types'

type ActiveTab = 'directory' | 'reviews' | 'messages'

export default function CustomersPage() {
  const [tab, setTab] = useState<ActiveTab>('directory')
  const [search, setSearch] = useState('')
  const [replyTarget, setReplyTarget] = useState<Review | null>(null)
  const [replyText, setReplyText] = useState('')
  const [reviews, setReviews] = useState<Review[]>(mockReviews)

  const filtered = mockCustomers.filter(c =>
    search === '' ||
    c.full_name.toLowerCase().includes(search.toLowerCase()) ||
    c.email?.toLowerCase().includes(search.toLowerCase()) ||
    c.phone_number?.includes(search)
  )

  const avgRating = (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1)

  function submitReply() {
    if (!replyTarget || !replyText.trim()) return
    setReviews(prev => prev.map(r => r.id === replyTarget.id ? { ...r, reply: replyText } : r))
    setReplyTarget(null)
    setReplyText('')
  }

  const customerColumns = [
    {
      key: 'full_name',
      header: 'Customer',
      render: (c: Customer) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
            <span className="text-xs font-bold text-primary">{c.full_name[0]}</span>
          </div>
          <div>
            <p className="font-medium text-dark text-sm">{c.full_name}</p>
            <p className="text-xs text-gray-400">{c.email ?? c.phone_number ?? '—'}</p>
          </div>
          {c.is_premium && <Crown className="w-3.5 h-3.5 text-warning" />}
        </div>
      ),
    },
    {
      key: 'booking_count',
      header: 'Total bookings',
      render: (c: Customer) => (
        <span className="font-semibold text-dark">{c.booking_count}</span>
      ),
    },
    {
      key: 'total_spent',
      header: 'Total spent',
      render: (c: Customer) => (
        <span className="font-semibold text-primary">{formatCurrency(c.total_spent)}</span>
      ),
    },
    {
      key: 'last_travel',
      header: 'Last trip',
      render: (c: Customer) => (
        <span className="text-sm text-gray-500">{c.last_travel ? formatDate(c.last_travel) : '—'}</span>
      ),
    },
    {
      key: 'is_premium',
      header: 'Plan',
      render: (c: Customer) => (
        <Badge label={c.is_premium ? 'premium' : 'free'} color={c.is_premium ? 'warning' : 'secondary'} />
      ),
    },
  ]

  return (
    <div>
      <Header title="Customer Relationship" subtitle="Directory, reviews, and messaging" />

      {/* KPIs */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <StatCard label="Total customers" value={mockCustomers.length} icon={Users} color="primary" />
        <StatCard label="Premium customers" value={mockCustomers.filter(c => c.is_premium).length} icon={Crown} color="warning" />
        <StatCard label="Average rating" value={`${avgRating} / 5`} icon={Star} trend={2.1} color="success" />
        <StatCard label="Pending replies" value={reviews.filter(r => !r.reply).length} icon={MessageCircle} color="error" />
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-4">
        {([
          { key: 'directory', label: `Directory (${mockCustomers.length})` },
          { key: 'reviews', label: `Reviews (${reviews.length})` },
          { key: 'messages', label: 'Messages' },
        ] as { key: ActiveTab; label: string }[]).map(t => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
              tab === t.key ? 'bg-primary text-white shadow-sm' : 'bg-white text-gray-500 shadow-card hover:bg-gray-50'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Directory */}
      {tab === 'directory' && (
        <Card padding={false}>
          <div className="px-5 py-3 border-b border-gray-100 flex items-center gap-3">
            <Search className="w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, email, or phone…"
              className="flex-1 text-sm bg-transparent focus:outline-none"
            />
          </div>
          {filtered.length === 0 ? (
            <EmptyState icon={Users} title="No customers yet" description="Customers who book with your agency will appear here." />
          ) : (
            <DataTable columns={customerColumns} data={filtered} rowKey={c => c.id} />
          )}
        </Card>
      )}

      {/* Reviews */}
      {tab === 'reviews' && (
        <div className="space-y-4">
          {/* Rating summary */}
          <Card>
            <CardHeader>
              <CardTitle>Rating Overview</CardTitle>
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-extrabold text-dark">{avgRating}</span>
                <span className="text-sm text-gray-400">/ 5.0</span>
              </div>
            </CardHeader>
            <div className="flex gap-1 mb-4">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star key={i} className={`w-5 h-5 ${i < parseFloat(avgRating) ? 'text-warning fill-warning' : 'text-gray-200'}`} />
              ))}
            </div>
            <div className="space-y-2">
              {[5, 4, 3, 2, 1].map(star => {
                const count = reviews.filter(r => r.rating === star).length
                const pct = reviews.length ? Math.round((count / reviews.length) * 100) : 0
                return (
                  <div key={star} className="flex items-center gap-2 text-xs">
                    <span className="w-8 text-gray-500">{star}★</span>
                    <div className="flex-1 h-2 rounded-full bg-gray-100">
                      <div className="h-2 rounded-full bg-warning transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="w-8 text-right text-gray-400">{count}</span>
                  </div>
                )
              })}
            </div>
          </Card>

          {reviews.map(r => (
            <Card key={r.id}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                    <span className="text-sm font-bold text-primary">{r.customer_name[0]}</span>
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-semibold text-dark text-sm">{r.customer_name}</p>
                      <div className="flex">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <Star key={i} className={`w-3 h-3 ${i < r.rating ? 'text-warning fill-warning' : 'text-gray-200'}`} />
                        ))}
                      </div>
                      <span className="text-xs text-gray-400">{r.trip_route}</span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{r.comment}</p>

                    {r.reply ? (
                      <div className="ml-4 pl-3 border-l-2 border-primary/30">
                        <p className="text-xs text-gray-400 mb-0.5">Agency reply:</p>
                        <p className="text-sm text-dark">{r.reply}</p>
                      </div>
                    ) : (
                      <Button
                        variant="ghost"
                        size="sm"
                        leftIcon={<MessageCircle className="w-3.5 h-3.5" />}
                        onClick={() => setReplyTarget(r)}
                      >
                        Reply
                      </Button>
                    )}
                  </div>
                </div>
                <span className="text-xs text-gray-400 shrink-0">{formatDate(r.created_at)}</span>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Messages */}
      {tab === 'messages' && (
        <Card>
          <CardHeader>
            <CardTitle>In-app Messages</CardTitle>
            <Badge label="Coming soon" color="secondary" />
          </CardHeader>
          <EmptyState
            icon={MessageCircle}
            title="Messaging coming soon"
            description="Respond to customer inquiries directly from the portal. This feature is in active development."
          />
        </Card>
      )}

      {/* Reply modal */}
      <Modal open={!!replyTarget} onClose={() => setReplyTarget(null)} title="Reply to review">
        {replyTarget && (
          <div className="space-y-4">
            <div className="bg-gray-50 rounded-xl p-4 text-sm">
              <p className="font-medium text-dark mb-1">{replyTarget.customer_name} — {replyTarget.trip_route}</p>
              <p className="text-gray-600">{replyTarget.comment}</p>
            </div>
            <FormField label="Your response" required>
              <Textarea
                value={replyText}
                onChange={e => setReplyText(e.target.value)}
                rows={4}
                placeholder="Thank you for your feedback…"
              />
            </FormField>
            <div className="flex justify-end gap-3">
              <Button variant="outline" onClick={() => setReplyTarget(null)}>Cancel</Button>
              <Button onClick={submitReply} disabled={!replyText.trim()}>Send reply</Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
