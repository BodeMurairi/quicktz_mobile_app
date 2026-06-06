import clsx from 'clsx'
import { capitalize } from '../../utils/format'

type Color = 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'default'

interface BadgeProps {
  label: string
  color?: Color
  dot?: boolean
  className?: string
}

const colorMap: Record<Color, string> = {
  primary:   'bg-primary/10 text-primary-700',
  success:   'bg-green-100 text-green-700',
  warning:   'bg-amber-100 text-amber-700',
  error:     'bg-red-100 text-red-700',
  secondary: 'bg-gray-100 text-gray-600',
  default:   'bg-gray-100 text-gray-500',
}

const dotMap: Record<Color, string> = {
  primary:   'bg-primary',
  success:   'bg-success',
  warning:   'bg-warning',
  error:     'bg-error',
  secondary: 'bg-gray-400',
  default:   'bg-gray-400',
}

export default function Badge({ label, color = 'default', dot = false, className }: BadgeProps) {
  return (
    <span className={clsx('inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold', colorMap[color], className)}>
      {dot && <span className={clsx('w-1.5 h-1.5 rounded-full', dotMap[color])} />}
      {capitalize(label)}
    </span>
  )
}
