import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Megaphone, Tag, Bell, Building2, Eye, MousePointerClick,
  Ticket, TrendingUp, Plus, ArrowRight, CalendarClock, Percent, Route as RouteIcon, Hash,
} from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Header from '../../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import StatCard from '../../components/ui/StatCard'
import Modal from '../../components/ui/Modal'
import EmptyState from '../../components/ui/EmptyState'
import { FormField, Input, Select, Textarea } from '../../components/ui/FormField'
import { mockPromotions, mockAnnouncements } from '../../utils/mockData'
import { formatDate } from '../../utils/format'
import type { Promotion, Announcement } from '../../types'

type ActiveTab = 'promotions' | 'announcements' | 'analytics'

const promoSchema = z.object({
  code: z.string().min(3).toUpperCase(),
  description: z.string().min(5),
  discount_percent: z.coerce.number().min(1).max(100),
  valid_from: z.string().min(1),
  valid_until: z.string().min(1),
  max_uses: z.coerce.number().int().min(1),
})

const annSchema = z.object({
  title: z.string().min(3),
  body: z.string().min(10),
  target: z.enum(['all', 'previous_customers']),
})

type PromoForm = z.infer<typeof promoSchema>
type AnnForm = z.infer<typeof annSchema>

export default function MarketingPage() {
  const navigate = useNavigate()
  const [tab, setTab] = useState<ActiveTab>('promotions')
  const [promotions, setPromotions] = useState<Promotion[]>(mockPromotions)
  const [announcements, setAnnouncements] = useState<Announcement[]>(mockAnnouncements)
  const [showPromoModal, setShowPromoModal] = useState(false)
  const [showAnnModal, setShowAnnModal] = useState(false)
  const [viewingPromo, setViewingPromo] = useState<Promotion | null>(null)

  const promoForm = useForm<PromoForm>({ resolver: zodResolver(promoSchema) })
  const annForm = useForm<AnnForm>({ resolver: zodResolver(annSchema), defaultValues: { target: 'all' } })

  function createPromo(data: PromoForm) {
    const newPromo: Promotion = {
      id: `promo-${Date.now()}`,
      ...data,
      used_count: 0,
      is_active: true,
      routes: ['All routes'],
    }
    setPromotions(prev => [newPromo, ...prev])
    setShowPromoModal(false)
    promoForm.reset()
  }

  function sendAnnouncement(data: AnnForm) {
    const newAnn: Announcement = {
      id: `ann-${Date.now()}`,
      ...data,
      created_at: new Date().toISOString(),
      sent_count: data.target === 'all' ? 1842 : 763,
    }
    setAnnouncements(prev => [newAnn, ...prev])
    setShowAnnModal(false)
    annForm.reset()
  }

  function togglePromo(id: string) {
    setPromotions(prev => prev.map(p => p.id === id ? { ...p, is_active: !p.is_active } : p))
  }

  return (
    <div>
      <Header title="Marketing & Visibility" subtitle="Profile, promotions, announcements, and reach analytics" />

      {/* KPIs */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <StatCard label="Profile views this month" value="2,847" icon={Eye} trend={12.4} color="primary" />
        <StatCard label="Route clicks" value="1,203" icon={MousePointerClick} trend={8.1} color="success" />
        <StatCard label="Bookings from profile" value="89" icon={Ticket} trend={15.3} color="warning" />
        <StatCard label="Active promotions" value={promotions.filter(p => p.is_active).length} icon={Tag} color="error" />
      </div>

      {/* Profile banner */}
      <Card className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
            <Building2 className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="font-semibold text-dark text-sm">Manage your public agency profile</p>
            <p className="text-xs text-gray-500">Photo gallery, locations, opening hours, and more.</p>
          </div>
        </div>
        <Button variant="outline" size="sm" rightIcon={<ArrowRight className="w-3.5 h-3.5" />} onClick={() => navigate('/profile')}>
          Go to Profile
        </Button>
      </Card>

      {/* Tabs */}
      <div className="flex gap-2 mb-4">
        {([
          { key: 'promotions', label: `Promotions (${promotions.length})` },
          { key: 'announcements', label: `Announcements (${announcements.length})` },
          { key: 'analytics', label: 'Analytics' },
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

      {/* Promotions */}
      {tab === 'promotions' && (
        <div>
          <div className="flex justify-end mb-4">
            <Button leftIcon={<Plus className="w-4 h-4" />} onClick={() => setShowPromoModal(true)}>
              New Promotion
            </Button>
          </div>
          <div className="grid grid-cols-2 gap-4">
            {promotions.map(p => (
              <Card
                key={p.id}
                onClick={() => setViewingPromo(p)}
                className={!p.is_active ? 'opacity-60' : ''}
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-mono font-bold text-primary text-lg">{p.code}</span>
                      <Badge label={p.is_active ? 'active' : 'inactive'} color={p.is_active ? 'success' : 'secondary'} />
                    </div>
                    <p className="text-sm text-gray-600">{p.description}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-extrabold text-dark">{p.discount_percent}%</p>
                    <p className="text-xs text-gray-400">discount</p>
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-3 text-xs mb-3">
                  <div>
                    <p className="text-gray-400">Valid from</p>
                    <p className="font-medium">{formatDate(p.valid_from)}</p>
                  </div>
                  <div>
                    <p className="text-gray-400">Valid until</p>
                    <p className="font-medium">{formatDate(p.valid_until)}</p>
                  </div>
                  <div>
                    <p className="text-gray-400">Usage</p>
                    <p className="font-medium">{p.used_count} / {p.max_uses}</p>
                  </div>
                </div>
                {/* Usage bar */}
                <div className="w-full h-1.5 bg-gray-100 rounded-full mb-3">
                  <div
                    className="h-1.5 bg-primary rounded-full"
                    style={{ width: `${Math.min((p.used_count / p.max_uses) * 100, 100)}%` }}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <p className="text-xs text-gray-400">Routes: {p.routes.join(', ')}</p>
                  <Button
                    variant={p.is_active ? 'outline' : 'secondary'}
                    size="sm"
                    onClick={e => { e.stopPropagation(); togglePromo(p.id) }}
                  >
                    {p.is_active ? 'Deactivate' : 'Activate'}
                  </Button>
                </div>
              </Card>
            ))}
            {promotions.length === 0 && (
              <div className="col-span-2">
                <EmptyState icon={Tag} title="No promotions yet" description="Create your first promo code to attract more customers." action={{ label: 'Create promotion', onClick: () => setShowPromoModal(true) }} />
              </div>
            )}
          </div>
        </div>
      )}

      {/* Announcements */}
      {tab === 'announcements' && (
        <div>
          <div className="flex justify-end mb-4">
            <Button leftIcon={<Plus className="w-4 h-4" />} onClick={() => setShowAnnModal(true)}>
              New Announcement
            </Button>
          </div>
          <div className="space-y-4">
            {announcements.map(a => (
              <Card key={a.id}>
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                      <Bell className="w-5 h-5 text-primary" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-dark">{a.title}</p>
                        <Badge label={a.target === 'all' ? 'All users' : 'Past customers'} color={a.target === 'all' ? 'primary' : 'secondary'} />
                      </div>
                      <p className="text-sm text-gray-600 mb-2">{a.body}</p>
                      <div className="flex items-center gap-3 text-xs text-gray-400">
                        <span>Sent {formatDate(a.created_at)}</span>
                        <span>·</span>
                        <span className="flex items-center gap-1">
                          <Megaphone className="w-3 h-3" />
                          {a.sent_count.toLocaleString()} recipients
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
            {announcements.length === 0 && (
              <EmptyState icon={Bell} title="No announcements" description="Push updates to your customers about new routes, schedules, and offers." action={{ label: 'Send announcement', onClick: () => setShowAnnModal(true) }} />
            )}
          </div>
        </div>
      )}

      {/* Analytics */}
      {tab === 'analytics' && (
        <div className="grid grid-cols-2 gap-4">
          {[
            { label: 'Profile page views', value: '2,847', change: '+12.4%', icon: Eye, color: 'bg-primary/10 text-primary' },
            { label: 'Route detail clicks', value: '1,203', change: '+8.1%', icon: MousePointerClick, color: 'bg-green-50 text-success' },
            { label: 'Bookings from profile', value: '89', change: '+15.3%', icon: Ticket, color: 'bg-amber-50 text-warning' },
            { label: 'Promo code redemptions', value: '48', change: '+5.2%', icon: Tag, color: 'bg-purple-50 text-purple-600' },
          ].map(item => (
            <Card key={item.label} className="flex items-center gap-4">
              <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${item.color}`}>
                <item.icon className="w-6 h-6" />
              </div>
              <div>
                <p className="text-2xl font-extrabold text-dark">{item.value}</p>
                <p className="text-sm text-gray-500">{item.label}</p>
                <p className="text-xs text-success font-medium">{item.change} vs last month</p>
              </div>
            </Card>
          ))}

          <Card className="col-span-2">
            <CardHeader>
              <CardTitle>Premium Features</CardTitle>
              <Badge label="Upgrade required" color="warning" />
            </CardHeader>
            <div className="grid grid-cols-3 gap-3">
              {[
                { icon: TrendingUp, title: 'Advanced Analytics', desc: 'Deep-dive reports with funnel analysis and cohort tracking.' },
                { icon: Eye, title: 'Priority Search Placement', desc: 'Your routes appear first in QuickTZ search results.' },
                { icon: Megaphone, title: 'Unlimited Campaigns', desc: 'Run unlimited promotional campaigns without restrictions.' },
              ].map(f => (
                <div key={f.title} className="p-4 rounded-xl bg-gradient-to-br from-dark to-primary-700 text-white">
                  <f.icon className="w-6 h-6 mb-3 text-secondary" />
                  <p className="font-semibold text-sm mb-1">{f.title}</p>
                  <p className="text-xs text-primary-200">{f.desc}</p>
                </div>
              ))}
            </div>
            <div className="mt-4 flex justify-end">
              <Button>Upgrade to Premium</Button>
            </div>
          </Card>
        </div>
      )}

      {/* Create Promotion Modal */}
      <Modal open={showPromoModal} onClose={() => setShowPromoModal(false)} title="Create Promotion">
        <form onSubmit={promoForm.handleSubmit(createPromo)} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Promo code" required error={promoForm.formState.errors.code?.message}>
              <Input {...promoForm.register('code')} placeholder="SUMMER25" className="uppercase" />
            </FormField>
            <FormField label="Discount (%)" required error={promoForm.formState.errors.discount_percent?.message}>
              <Input {...promoForm.register('discount_percent')} type="number" min={1} max={100} />
            </FormField>
          </div>
          <FormField label="Description" required error={promoForm.formState.errors.description?.message}>
            <Input {...promoForm.register('description')} placeholder="Summer 25% off all routes" />
          </FormField>
          <div className="grid grid-cols-2 gap-4">
            <FormField label="Valid from" required error={promoForm.formState.errors.valid_from?.message}>
              <Input {...promoForm.register('valid_from')} type="date" />
            </FormField>
            <FormField label="Valid until" required error={promoForm.formState.errors.valid_until?.message}>
              <Input {...promoForm.register('valid_until')} type="date" />
            </FormField>
          </div>
          <FormField label="Max uses" required error={promoForm.formState.errors.max_uses?.message}>
            <Input {...promoForm.register('max_uses')} type="number" min={1} placeholder="200" />
          </FormField>
          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => setShowPromoModal(false)}>Cancel</Button>
            <Button type="submit">Create Promotion</Button>
          </div>
        </form>
      </Modal>

      {/* Announcement Modal */}
      <Modal open={showAnnModal} onClose={() => setShowAnnModal(false)} title="Send Announcement" size="lg">
        <form onSubmit={annForm.handleSubmit(sendAnnouncement)} className="space-y-4">
          <FormField label="Title" required error={annForm.formState.errors.title?.message}>
            <Input {...annForm.register('title')} placeholder="New route: Lomé → Bassar" />
          </FormField>
          <FormField label="Message body" required error={annForm.formState.errors.body?.message}>
            <Textarea {...annForm.register('body')} rows={4} placeholder="Write your announcement here…" />
          </FormField>
          <FormField label="Target audience" required>
            <Select {...annForm.register('target')}>
              <option value="all">All QuickTZ users</option>
              <option value="previous_customers">Previous customers only</option>
            </Select>
          </FormField>
          <div className="bg-amber-50 text-amber-800 text-xs rounded-xl px-4 py-3">
            💡 Targeting "All users" will reach ~1,842 people. "Previous customers" reaches ~763.
          </div>
          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => setShowAnnModal(false)}>Cancel</Button>
            <Button type="submit">Send Announcement</Button>
          </div>
        </form>
      </Modal>

      {/* Promotion Detail Modal */}
      <Modal
        open={!!viewingPromo}
        onClose={() => setViewingPromo(null)}
        title="Promotion Details"
        size="lg"
      >
        {viewingPromo && (() => {
          const p = viewingPromo
          const today = new Date()
          const until = new Date(p.valid_until)
          const from = new Date(p.valid_from)
          const daysRemaining = Math.ceil((until.getTime() - today.getTime()) / 86_400_000)
          const hasEnded = daysRemaining < 0
          const hasStarted = today >= from
          const usagePercent = Math.min((p.used_count / p.max_uses) * 100, 100)
          const remainingUses = Math.max(p.max_uses - p.used_count, 0)

          return (
            <div className="space-y-5">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-mono font-bold text-primary text-2xl">{p.code}</span>
                    <Badge label={p.is_active ? 'active' : 'inactive'} color={p.is_active ? 'success' : 'secondary'} />
                    {p.is_active && hasEnded && <Badge label="expired" color="error" />}
                    {p.is_active && !hasEnded && !hasStarted && <Badge label="upcoming" color="warning" />}
                  </div>
                  <p className="text-sm text-gray-600">{p.description}</p>
                </div>
                <div className="text-right shrink-0 ml-4">
                  <p className="text-3xl font-extrabold text-dark">{p.discount_percent}%</p>
                  <p className="text-xs text-gray-400">discount</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 rounded-xl bg-gray-50 flex items-start gap-2.5">
                  <CalendarClock className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                  <div>
                    <p className="text-xs text-gray-400">Valid period</p>
                    <p className="text-sm font-medium text-dark">{formatDate(p.valid_from)} — {formatDate(p.valid_until)}</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {hasEnded ? 'Ended' : hasStarted ? `${daysRemaining} day${daysRemaining === 1 ? '' : 's'} remaining` : `Starts in ${Math.abs(Math.ceil((from.getTime() - today.getTime()) / 86_400_000))} day(s)`}
                    </p>
                  </div>
                </div>
                <div className="p-3 rounded-xl bg-gray-50 flex items-start gap-2.5">
                  <Hash className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                  <div>
                    <p className="text-xs text-gray-400">Usage</p>
                    <p className="text-sm font-medium text-dark">{p.used_count} of {p.max_uses} used</p>
                    <p className="text-xs text-gray-400 mt-0.5">{remainingUses} redemption{remainingUses === 1 ? '' : 's'} left</p>
                  </div>
                </div>
                <div className="p-3 rounded-xl bg-gray-50 flex items-start gap-2.5">
                  <Percent className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                  <div>
                    <p className="text-xs text-gray-400">Redemption rate</p>
                    <p className="text-sm font-medium text-dark">{usagePercent.toFixed(1)}%</p>
                  </div>
                </div>
                <div className="p-3 rounded-xl bg-gray-50 flex items-start gap-2.5">
                  <RouteIcon className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                  <div>
                    <p className="text-xs text-gray-400">Applicable routes</p>
                    <p className="text-sm font-medium text-dark">{p.routes.join(', ')}</p>
                  </div>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <p className="text-xs font-medium text-gray-500">Usage progress</p>
                  <p className="text-xs text-gray-400">{p.used_count} / {p.max_uses}</p>
                </div>
                <div className="w-full h-2 bg-gray-100 rounded-full">
                  <div
                    className="h-2 bg-primary rounded-full transition-all"
                    style={{ width: `${usagePercent}%` }}
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-1 border-t border-gray-100">
                <Button variant="outline" onClick={() => setViewingPromo(null)}>Close</Button>
                <Button
                  variant={p.is_active ? 'outline' : 'secondary'}
                  onClick={() => { togglePromo(p.id); setViewingPromo(null) }}
                >
                  {p.is_active ? 'Deactivate' : 'Activate'}
                </Button>
              </div>
            </div>
          )
        })()}
      </Modal>
    </div>
  )
}
