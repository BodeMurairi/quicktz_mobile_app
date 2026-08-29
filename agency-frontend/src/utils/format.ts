import { format, parseISO, isValid } from 'date-fns'

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('fr-TG', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount) + ' XOF'
}

export function formatDate(iso: string | null | undefined, fmt = 'dd MMM yyyy'): string {
  if (!iso) return '—'
  const d = parseISO(iso)
  return isValid(d) ? format(d, fmt) : '—'
}

export function formatDateTime(iso: string | null | undefined): string {
  return formatDate(iso, 'dd MMM yyyy, HH:mm')
}

export function formatTime(iso: string | null | undefined): string {
  return formatDate(iso, 'HH:mm')
}

export function statusColor(status: string): string {
  const map: Record<string, string> = {
    confirmed: 'success',
    completed: 'success',
    active:    'success',
    pending:   'warning',
    pending_approval: 'warning',
    scheduled: 'primary',
    delayed:   'warning',
    cancelled: 'error',
    departed:  'secondary',
    used:      'secondary',
    failed:    'error',
    refunded:  'warning',
  }
  return map[status] ?? 'secondary'
}

export function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
