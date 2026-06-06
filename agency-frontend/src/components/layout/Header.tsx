import { Bell, Search, RefreshCw } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'

interface HeaderProps {
  title: string
  subtitle?: string
  actions?: React.ReactNode
}

export default function Header({ title, subtitle, actions }: HeaderProps) {
  const { agency } = useAuth()

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
        <button className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500">
          <Search className="w-4 h-4" />
        </button>
        <button className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500 relative">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-error rounded-full" />
        </button>
        <button className="p-2 rounded-xl bg-white shadow-card hover:bg-gray-50 transition text-gray-500">
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}
