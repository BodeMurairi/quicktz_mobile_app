import { format, parseISO, isValid } from 'date-fns'

export const COMMISSION_RATE = 0.03

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

export function netRevenue(gross: number): number {
  return gross * (1 - COMMISSION_RATE)
}

export function commissionAmount(gross: number): number {
  return gross * COMMISSION_RATE
}

export function statusColor(status: string): string {
  const map: Record<string, string> = {
    confirmed: 'success',
    completed: 'success',
    active:    'success',
    pending:   'warning',
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
