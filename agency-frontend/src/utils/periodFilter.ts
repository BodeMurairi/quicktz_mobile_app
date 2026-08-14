// Shared "period filter" (year / month / exact date -> API date range) used by any
// page offering a Trips-style date filter (Trips, Transactions, ...).

export const CURRENT_YEAR = new Date().getFullYear()
export const YEAR_OPTIONS = Array.from({ length: 5 }, (_, i) => CURRENT_YEAR - 1 + i)
export const MONTH_OPTIONS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

export function computeDateRange(
  year: number | 'all',
  month: number | 'all',
  exactDate: string
): { from_date?: string; to_date?: string } {
  if (exactDate) {
    return { from_date: `${exactDate}T00:00:00`, to_date: `${exactDate}T23:59:59` }
  }
  if (year === 'all') return {}
  if (month === 'all') {
    return { from_date: `${year}-01-01T00:00:00`, to_date: `${year}-12-31T23:59:59` }
  }
  const mm = String(month + 1).padStart(2, '0')
  const lastDay = new Date(year, month + 1, 0).getDate()
  return {
    from_date: `${year}-${mm}-01T00:00:00`,
    to_date: `${year}-${mm}-${String(lastDay).padStart(2, '0')}T23:59:59`,
  }
}
