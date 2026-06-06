import clsx from 'clsx'
import type { LucideIcon } from 'lucide-react'
import { TrendingUp, TrendingDown } from 'lucide-react'

interface StatCardProps {
  label: string
  value: string | number
  icon: LucideIcon
  trend?: number   // percent change
  trendLabel?: string
  color?: 'primary' | 'success' | 'warning' | 'error'
  className?: string
}

const colorMap = {
  primary: { bg: 'bg-primary/10', icon: 'text-primary', border: 'border-primary/20' },
  success: { bg: 'bg-green-50', icon: 'text-success', border: 'border-green-200' },
  warning: { bg: 'bg-amber-50', icon: 'text-warning', border: 'border-amber-200' },
  error:   { bg: 'bg-red-50', icon: 'text-error', border: 'border-red-200' },
}

export default function StatCard({ label, value, icon: Icon, trend, trendLabel, color = 'primary', className }: StatCardProps) {
  const c = colorMap[color]
  const positive = trend !== undefined && trend >= 0

  return (
    <div className={clsx('bg-white rounded-2xl shadow-card p-5 flex flex-col gap-3', className)}>
      <div className="flex items-center justify-between">
        <div className={clsx('w-10 h-10 rounded-xl flex items-center justify-center', c.bg)}>
          <Icon className={clsx('w-5 h-5', c.icon)} />
        </div>
        {trend !== undefined && (
          <div className={clsx('flex items-center gap-1 text-xs font-semibold', positive ? 'text-success' : 'text-error')}>
            {positive ? <TrendingUp className="w-3.5 h-3.5" /> : <TrendingDown className="w-3.5 h-3.5" />}
            {Math.abs(trend)}%
          </div>
        )}
      </div>
      <div>
        <p className="text-2xl font-extrabold text-dark leading-none">{value}</p>
        <p className="text-xs text-gray-500 mt-1">{label}</p>
        {trendLabel && <p className="text-xs text-gray-400 mt-0.5">{trendLabel}</p>}
      </div>
    </div>
  )
}
