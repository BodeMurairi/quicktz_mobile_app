import type { AgencyNotification, Promotion, Announcement } from '../types'

// ── Mock notifications (agency dashboard bell) ────────────────────────────────
// Still mock — the backend has no agency-side notification feed (only per-rider
// notifications). Real activity to feed this would need its own backend endpoint.

export const mockAgencyNotifications: AgencyNotification[] = [
  { id: 'n-001', type: 'booking', title: 'New booking received', description: 'Kofi Mensah booked Lomé → Kara, departing 04 Jun.', created_at: '2026-08-04T09:10:00', read: false, href: '/bookings' },
  { id: 'n-002', type: 'review', title: 'New review needs a reply', description: 'Yao Agbenyo left a 3-star review — the AC was not working.', created_at: '2026-08-04T08:40:00', read: false, href: '/customers' },
  { id: 'n-003', type: 'payment', title: 'Payment received', description: 'Mobile money payment of 12,500 XOF confirmed.', created_at: '2026-08-03T18:05:00', read: true, href: '/finance' },
  { id: 'n-004', type: 'system', title: 'Weekly summary ready', description: 'Your agency performance report for last week is ready to view.', created_at: '2026-08-03T07:00:00', read: true, href: '/dashboard' },
]

// ── Mock promotions ───────────────────────────────────────────────────────────
// Still mock — promo codes and usage tracking don't exist in the backend yet
// (no Promotion model). Wiring this up for real is a separate backend feature.

export const mockPromotions: Promotion[] = [
  { id: 'promo-001', code: 'SUMMER25', description: 'Summer holiday 25% off', discount_percent: 25, valid_from: '2026-06-01', valid_until: '2026-07-15', max_uses: 200, used_count: 48, is_active: true, routes: ['Lomé → Kara', 'Lomé → Dapaong'] },
  { id: 'promo-002', code: 'FIRST10', description: 'First booking 10% off', discount_percent: 10, valid_from: '2026-01-01', valid_until: '2026-12-31', max_uses: 500, used_count: 234, is_active: true, routes: ['All routes'] },
  { id: 'promo-003', code: 'RAMP2026', description: 'Ramadan special', discount_percent: 15, valid_from: '2026-03-01', valid_until: '2026-03-30', max_uses: 100, used_count: 100, is_active: false, routes: ['All routes'] },
]

// ── Mock announcements ────────────────────────────────────────────────────────
// Still mock — same reason as promotions: no backend model or send pipeline yet.

export const mockAnnouncements: Announcement[] = [
  { id: 'ann-001', title: 'New route: Lomé → Bassar', body: 'We are pleased to announce a new daily service from Lomé to Bassar starting June 10th. Departures at 06:00 and 14:00.', target: 'all', created_at: '2026-06-01T10:00:00', sent_count: 1842 },
  { id: 'ann-002', title: 'Holiday schedule June 20–July 10', body: 'Extra departures have been added during the school holiday period. Check the schedule for full details.', target: 'previous_customers', created_at: '2026-05-28T09:00:00', sent_count: 763 },
  { id: 'ann-003', title: 'Summer discount — 25% off!', body: 'Book your trip before July 15 with code SUMMER25 and save 25% on select routes.', target: 'all', created_at: '2026-05-25T14:00:00', sent_count: 2100 },
]

// ── Real, static reference data (not database-backed dummy data) ───────────────

export const TOGO_CITIES = [
  'Lomé', 'Kara', 'Sokodé', 'Dapaong', 'Atakpamé', 'Bassar',
  'Notsé', 'Tsévié', 'Bafilo', 'Niamtougou', 'Badou', 'Aného', 'Vogan', 'Tabligbo',
]
