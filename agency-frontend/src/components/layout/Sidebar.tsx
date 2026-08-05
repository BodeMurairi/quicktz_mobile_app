import { NavLink, useNavigate } from 'react-router-dom'
import {
  Bus, LayoutDashboard, Ticket, DollarSign, Calendar, Route as RouteIcon,
  Users, Megaphone, Settings, LogOut, ChevronRight, Building2,
} from 'lucide-react'
import clsx from 'clsx'
import { useAuth } from '../../contexts/AuthContext'

interface NavItem {
  label: string
  href: string
  icon: React.ComponentType<{ className?: string }>
}

interface NavGroup {
  title: string
  items: NavItem[]
}

const NAV: NavGroup[] = [
  {
    title: 'Overview',
    items: [
      { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    ],
  },
  {
    title: 'Operations',
    items: [
      { label: 'Bookings', href: '/bookings', icon: Ticket },
      { label: 'Finance', href: '/finance', icon: DollarSign },
      { label: 'Trips', href: '/schedule', icon: Calendar },
      { label: 'Routes', href: '/routes', icon: RouteIcon },
    ],
  },
  {
    title: 'Engagement',
    items: [
      { label: 'Customers', href: '/customers', icon: Users },
      { label: 'Marketing', href: '/marketing', icon: Megaphone },
    ],
  },
  {
    title: 'Account',
    items: [
      { label: 'Profile', href: '/profile', icon: Building2 },
      { label: 'Settings', href: '/settings', icon: Settings },
    ],
  },
]

export default function Sidebar() {
  const { agency, user, logout } = useAuth()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/login')
  }

  return (
    <aside className="w-64 min-h-screen bg-dark flex flex-col shrink-0">
      {/* Brand */}
      <div className="px-5 py-5 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-primary flex items-center justify-center">
            <Bus className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="text-white font-bold text-sm leading-none">QuickTZ</p>
            <p className="text-primary-300 text-[10px] mt-0.5 uppercase tracking-wider">
              Agency Portal
            </p>
          </div>
        </div>
      </div>

      {/* Agency badge */}
      {agency && (
        <button
          onClick={() => navigate('/select-agency')}
          className="mx-4 mt-4 flex items-center gap-2 px-3 py-2.5 rounded-xl bg-white/10 hover:bg-white/15 transition group text-left"
        >
          <div className="w-7 h-7 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
            <Building2 className="w-3.5 h-3.5 text-secondary" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-white text-xs font-semibold truncate">{agency.name}</p>
            <p className="text-primary-300 text-[10px] truncate">Switch agency</p>
          </div>
          <ChevronRight className="w-3.5 h-3.5 text-primary-300 group-hover:text-white transition" />
        </button>
      )}

      {/* Nav */}
      <nav className="flex-1 px-4 pt-4 pb-4 overflow-y-auto space-y-5">
        {NAV.map(group => (
          <div key={group.title}>
            <p className="text-[10px] uppercase tracking-widest text-primary-400 font-semibold px-3 mb-1.5">
              {group.title}
            </p>
            <div className="space-y-0.5">
              {group.items.map(item => (
                <NavLink
                  key={item.href}
                  to={item.href}
                  className={({ isActive }) =>
                    clsx(
                      'sidebar-link',
                      isActive ? 'sidebar-link-active' : 'sidebar-link-inactive'
                    )
                  }
                >
                  <item.icon className="w-4 h-4 shrink-0" />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="px-4 pb-5 border-t border-white/10 pt-4">
        <div className="flex items-center gap-2 px-3 py-2 mb-2">
          <div className="w-7 h-7 rounded-full bg-secondary/20 flex items-center justify-center">
            <span className="text-secondary text-[11px] font-bold">
              {user?.full_name?.[0]?.toUpperCase() ?? 'A'}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-white text-xs font-medium truncate">{user?.full_name ?? 'Agent'}</p>
            <p className="text-primary-400 text-[10px] truncate">{user?.email ?? user?.phone_number}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="sidebar-link sidebar-link-inactive w-full hover:text-error"
        >
          <LogOut className="w-4 h-4" />
          Log out
        </button>
      </div>
    </aside>
  )
}
