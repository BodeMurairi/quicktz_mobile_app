import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Bell, Search, RefreshCw, Ticket, Star, DollarSign, Info, CheckCheck,
} from 'lucide-react'
import clsx from 'clsx'
import { useAuth } from '../../contexts/AuthContext'
import Modal from '../ui/Modal'
import { mockAgencyNotifications } from '../../utils/mockData'
import { formatDateTime } from '../../utils/format'
import type { AgencyNotification, AgencyNotificationType } from '../../types'

interface HeaderProps {
  title: string
  subtitle?: string
  actions?: React.ReactNode
}

const SEARCH_ITEMS = [
  { label: 'Dashboard', description: 'Overview and key metrics', href: '/dashboard' },
  { label: 'Bookings', description: 'View and manage all bookings', href: '/bookings' },
  { label: 'New manual booking', description: 'Create a booking on behalf of a customer', href: '/bookings/manual' },
  { label: 'Finance', description: 'Revenue, commissions and transactions', href: '/finance' },
  { label: 'Trips', description: 'Manage departures and trip statuses', href: '/schedule' },
  { label: 'Routes', description: 'Manage origins and destinations', href: '/routes' },
  { label: 'Customers', description: 'Directory, reviews and messaging', href: '/customers' },
  { label: 'Marketing', description: 'Promotions and announcements', href: '/marketing' },
  { label: 'Settings', description: 'Agency profile and preferences', href: '/settings' },
]

const NOTIF_ICON: Record<AgencyNotificationType, React.ComponentType<{ className?: string }>> = {
  booking: Ticket,
  review: Star,
  payment: DollarSign,
  system: Info,
}

const NOTIF_COLOR: Record<AgencyNotificationType, string> = {
  booking: 'text-primary bg-primary/10',
  review: 'text-warning bg-amber-100',
  payment: 'text-success bg-green-100',
  system: 'text-gray-500 bg-gray-100',
}

export default function Header({ title, subtitle, actions }: HeaderProps) {
  const { agency } = useAuth()
  const navigate = useNavigate()

  const [showSearch, setShowSearch] = useState(false)
  const [query, setQuery] = useState('')
  const [showNotifications, setShowNotifications] = useState(false)
  const [notifications, setNotifications] = useState<AgencyNotification[]>(mockAgencyNotifications)

  const unreadCount = notifications.filter(n => !n.read).length

  const filteredResults = SEARCH_ITEMS.filter(item =>
    query.trim() === '' ||
    item.label.toLowerCase().includes(query.toLowerCase()) ||
    item.description.toLowerCase().includes(query.toLowerCase())
  )

  function goTo(href: string) {
    navigate(href)
    setShowSearch(false)
    setQuery('')
  }

  function openNotification(n: AgencyNotification) {
    setNotifications(prev => prev.map(x => (x.id === n.id ? { ...x, read: true } : x)))
    if (n.href) navigate(n.href)
    setShowNotifications(false)
  }

  function markAllRead() {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })))
  }

  return (
    <div className="flex items-start justify-between mb-6">
      <div>
        <h1 className="page-title">{title}</h1>
        {subtitle && <p className="text-sm text-gray-500 mt-0.5">{subtitle}</p>}
        {!subtitle && agency && (
          <p className="text-sm text-gray-400 mt-0.5">{agency.name}</p>
        )}
      </div>
      <div className="flex items-center gap-2 mt-1">
        {actions}
        <button
          onClick={() => setShowSearch(true)}
          className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500"
          aria-label="Search"
        >
          <Search className="w-4 h-4" />
        </button>
        <button
          onClick={() => setShowNotifications(true)}
          className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500 relative"
          aria-label="Notifications"
        >
          <Bell className="w-4 h-4" />
          {unreadCount > 0 && (
            <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-error rounded-full" />
          )}
        </button>
        <button
          onClick={() => window.location.reload()}
          className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500"
          aria-label="Refresh"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Search modal */}
      <Modal open={showSearch} onClose={() => setShowSearch(false)} title="Search">
        <div className="space-y-3">
          <input
            autoFocus
            type="text"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search pages and actions…"
            className="w-full text-sm bg-background border border-gray-200 rounded-xl px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-primary-400"
          />
          <div className="space-y-1 max-h-72 overflow-y-auto">
            {filteredResults.length === 0 ? (
              <p className="text-sm text-gray-400 text-center py-6">No matches for "{query}"</p>
            ) : (
              filteredResults.map(item => (
                <button
                  key={item.href + item.label}
                  onClick={() => goTo(item.href)}
                  className="w-full text-left px-3 py-2.5 rounded-xl hover:bg-gray-50 transition"
                >
                  <p className="text-sm font-medium text-dark">{item.label}</p>
                  <p className="text-xs text-gray-400">{item.description}</p>
                </button>
              ))
            )}
          </div>
        </div>
      </Modal>

      {/* Notifications modal */}
      <Modal open={showNotifications} onClose={() => setShowNotifications(false)} title="Notifications">
        <div className="space-y-3">
          {unreadCount > 0 && (
            <button
              onClick={markAllRead}
              className="flex items-center gap-1.5 text-xs font-medium text-primary hover:underline ml-auto"
            >
              <CheckCheck className="w-3.5 h-3.5" />
              Mark all as read
            </button>
          )}
          {notifications.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-6">You're all caught up.</p>
          ) : (
            <div className="space-y-1 max-h-96 overflow-y-auto">
              {notifications.map(n => {
                const Icon = NOTIF_ICON[n.type]
                return (
                  <button
                    key={n.id}
                    onClick={() => openNotification(n)}
                    className={clsx(
                      'w-full flex items-start gap-3 text-left px-3 py-2.5 rounded-xl transition',
                      n.read ? 'hover:bg-gray-50' : 'bg-primary-50/60 hover:bg-primary-50'
                    )}
                  >
                    <div className={clsx('w-8 h-8 rounded-lg flex items-center justify-center shrink-0', NOTIF_COLOR[n.type])}>
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-dark truncate">{n.title}</p>
                        {!n.read && <span className="w-1.5 h-1.5 rounded-full bg-primary shrink-0" />}
                      </div>
                      <p className="text-xs text-gray-500 mt-0.5">{n.description}</p>
                      <p className="text-[10px] text-gray-400 mt-1">{formatDateTime(n.created_at)}</p>
                    </div>
                  </button>
                )
              })}
            </div>
          )}
        </div>
      </Modal>
    </div>
  )
}
