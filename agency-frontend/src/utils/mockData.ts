import type {
  Booking, Trip, Route, Customer, Review,
  Promotion, Announcement, RevenueDataPoint, TransactionRow,
} from '../types'

// ── Revenue mock data (last 7 months) ─────────────────────────────────────────

export const mockRevenueData: RevenueDataPoint[] = [
  { label: 'Dec', revenue: 4_820_000, commission: 144_600, net: 4_675_400, bookings: 96 },
  { label: 'Jan', revenue: 5_100_000, commission: 153_000, net: 4_947_000, bookings: 102 },
  { label: 'Feb', revenue: 4_450_000, commission: 133_500, net: 4_316_500, bookings: 89 },
  { label: 'Mar', revenue: 5_800_000, commission: 174_000, net: 5_626_000, bookings: 116 },
  { label: 'Apr', revenue: 6_200_000, commission: 186_000, net: 6_014_000, bookings: 124 },
  { label: 'May', revenue: 7_100_000, commission: 213_000, net: 6_887_000, bookings: 142 },
  { label: 'Jun', revenue: 6_750_000, commission: 202_500, net: 6_547_500, bookings: 135 },
]

// ── Mock transactions ─────────────────────────────────────────────────────────

export const mockTransactions: TransactionRow[] = [
  { id: 'txn-001', date: '2026-06-04T09:12:00', passenger: 'Kofi Mensah', route: 'Lomé → Kara', amount: 12500, method: 'mobile_money', status: 'completed', booking_id: 'bk-001' },
  { id: 'txn-002', date: '2026-06-04T08:45:00', passenger: 'Ama Koffi', route: 'Lomé → Sokodé', amount: 9500, method: 'tmoney', status: 'completed', booking_id: 'bk-002' },
  { id: 'txn-003', date: '2026-06-03T16:22:00', passenger: 'Yao Agbenyo', route: 'Kara → Lomé', amount: 12500, method: 'flooz', status: 'refunded', booking_id: 'bk-003' },
  { id: 'txn-004', date: '2026-06-03T14:10:00', passenger: 'Akosua Addo', route: 'Lomé → Atakpamé', amount: 6000, method: 'mobile_money', status: 'completed', booking_id: 'bk-004' },
  { id: 'txn-005', date: '2026-06-03T11:05:00', passenger: 'Komi Djagba', route: 'Lomé → Dapaong', amount: 18000, method: 'bank_transfer', status: 'completed', booking_id: 'bk-005' },
  { id: 'txn-006', date: '2026-06-02T17:33:00', passenger: 'Efua Asante', route: 'Lomé → Kara', amount: 12500, method: 'tmoney', status: 'completed', booking_id: 'bk-006' },
  { id: 'txn-007', date: '2026-06-02T09:47:00', passenger: 'Kwame Boateng', route: 'Atakpamé → Lomé', amount: 6000, method: 'mobile_money', status: 'failed', booking_id: 'bk-007' },
  { id: 'txn-008', date: '2026-06-01T13:20:00', passenger: 'Abena Nyarko', route: 'Lomé → Sokodé', amount: 9500, method: 'flooz', status: 'completed', booking_id: 'bk-008' },
]

// ── Mock customers ────────────────────────────────────────────────────────────

export const mockCustomers: Customer[] = [
  { id: 'c-001', full_name: 'Kofi Mensah', email: 'kofi@example.com', phone_number: '+228 90 12 34 56', booking_count: 7, total_spent: 87500, last_travel: '2026-06-04', is_premium: true },
  { id: 'c-002', full_name: 'Ama Koffi', email: null, phone_number: '+228 91 23 45 67', booking_count: 3, total_spent: 28500, last_travel: '2026-06-04', is_premium: false },
  { id: 'c-003', full_name: 'Yao Agbenyo', email: 'yao@mail.tg', phone_number: '+228 92 34 56 78', booking_count: 12, total_spent: 150000, last_travel: '2026-06-03', is_premium: true },
  { id: 'c-004', full_name: 'Akosua Addo', email: 'akosua@gmail.com', phone_number: null, booking_count: 2, total_spent: 12000, last_travel: '2026-06-03', is_premium: false },
  { id: 'c-005', full_name: 'Komi Djagba', email: null, phone_number: '+228 93 45 67 89', booking_count: 5, total_spent: 90000, last_travel: '2026-06-03', is_premium: false },
  { id: 'c-006', full_name: 'Efua Asante', email: 'efua@mail.tg', phone_number: '+228 94 56 78 90', booking_count: 9, total_spent: 112500, last_travel: '2026-06-02', is_premium: true },
]

// ── Mock reviews ──────────────────────────────────────────────────────────────

export const mockReviews: Review[] = [
  { id: 'r-001', customer_name: 'Kofi Mensah', rating: 5, comment: 'Excellent service! Bus was on time and very clean.', trip_route: 'Lomé → Kara', created_at: '2026-06-03T14:00:00', reply: undefined },
  { id: 'r-002', customer_name: 'Ama Koffi', rating: 4, comment: 'Good trip overall but bus departed 10 minutes late.', trip_route: 'Lomé → Sokodé', created_at: '2026-06-02T11:00:00', reply: 'Thank you for the feedback! We apologize for the small delay.' },
  { id: 'r-003', customer_name: 'Yao Agbenyo', rating: 3, comment: 'AC was not working. Otherwise comfortable.', trip_route: 'Kara → Lomé', created_at: '2026-05-28T09:00:00', reply: undefined },
  { id: 'r-004', customer_name: 'Efua Asante', rating: 5, comment: 'Best bus service in Togo. Will definitely use again!', trip_route: 'Lomé → Kara', created_at: '2026-05-25T16:00:00', reply: 'Thank you, Efua! We look forward to seeing you again.' },
  { id: 'r-005', customer_name: 'Kwame Boateng', rating: 2, comment: 'Bus broke down for 2 hours. Need better maintenance.', trip_route: 'Atakpamé → Lomé', created_at: '2026-05-22T08:00:00', reply: undefined },
]

// ── Mock promotions ───────────────────────────────────────────────────────────

export const mockPromotions: Promotion[] = [
  { id: 'promo-001', code: 'SUMMER25', description: 'Summer holiday 25% off', discount_percent: 25, valid_from: '2026-06-01', valid_until: '2026-07-15', max_uses: 200, used_count: 48, is_active: true, routes: ['Lomé → Kara', 'Lomé → Dapaong'] },
  { id: 'promo-002', code: 'FIRST10', description: 'First booking 10% off', discount_percent: 10, valid_from: '2026-01-01', valid_until: '2026-12-31', max_uses: 500, used_count: 234, is_active: true, routes: ['All routes'] },
  { id: 'promo-003', code: 'RAMP2026', description: 'Ramadan special', discount_percent: 15, valid_from: '2026-03-01', valid_until: '2026-03-30', max_uses: 100, used_count: 100, is_active: false, routes: ['All routes'] },
]

// ── Mock announcements ────────────────────────────────────────────────────────

export const mockAnnouncements: Announcement[] = [
  { id: 'ann-001', title: 'New route: Lomé → Bassar', body: 'We are pleased to announce a new daily service from Lomé to Bassar starting June 10th. Departures at 06:00 and 14:00.', target: 'all', created_at: '2026-06-01T10:00:00', sent_count: 1842 },
  { id: 'ann-002', title: 'Holiday schedule June 20–July 10', body: 'Extra departures have been added during the school holiday period. Check the schedule for full details.', target: 'previous_customers', created_at: '2026-05-28T09:00:00', sent_count: 763 },
  { id: 'ann-003', title: 'Summer discount — 25% off!', body: 'Book your trip before July 15 with code SUMMER25 and save 25% on select routes.', target: 'all', created_at: '2026-05-25T14:00:00', sent_count: 2100 },
]

// ── Route helper for mock data ────────────────────────────────────────────────

export const TOGO_CITIES = [
  'Lomé', 'Kara', 'Sokodé', 'Dapaong', 'Atakpamé', 'Bassar',
  'Notsé', 'Tsévié', 'Bafilo', 'Niamtougou', 'Badou', 'Aného', 'Vogan', 'Tabligbo',
]

// Mock summary stats for dashboard
export const mockDashboardStats = {
  totalRevenue: 6_750_000,
  netRevenue: 6_547_500,
  totalBookings: 135,
  activeTrips: 8,
  cancelledTrips: 2,
  avgRating: 3.9,
  pendingCancellations: 3,
  activeCustomers: 89,
}

// Empty state for bookings when API returns nothing yet
export const mockBookings: Booking[] = []

// Empty trips
export const mockTrips: Trip[] = []

// Empty routes
export const mockRoutes: Route[] = []
