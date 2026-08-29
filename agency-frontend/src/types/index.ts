// ── Auth (agency accounts — separate account type from rider Users) ────────────

export interface AgencyLoginRequest {
  login_email: string
  password: string
}

export interface AuthResponse {
  access_token: string
  refresh_token: string
  token_type: string
}

// ── Agency ────────────────────────────────────────────────────────────────────

export interface AgencyLocation {
  label: string
  address: string
  phone?: string | null
}

export interface AgencyContact {
  label: string
  phone?: string | null
  email?: string | null
}

export interface AgencyDayHours {
  open?: string | null   // "HH:MM"
  close?: string | null  // "HH:MM"
  closed: boolean
}

export const WEEKDAY_KEYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'] as const
export type WeekdayKey = typeof WEEKDAY_KEYS[number]
export type AgencyOpeningHours = Partial<Record<WeekdayKey, AgencyDayHours>>

export interface Agency {
  id: string
  name: string
  description: string | null
  logo_url: string | null
  contact_email: string | null
  contact_phone: string | null
  address: string | null
  gallery?: string[] | null
  locations?: AgencyLocation[] | null
  contacts?: AgencyContact[] | null
  opening_hours?: AgencyOpeningHours | null
  is_verified: boolean
  is_active: boolean
  created_at: string
  routes?: Route[]
  // Only present on the authenticated agency's own view of itself (/agency-auth/me) —
  // never sent on public agency reads.
  login_email?: string
}

export interface AgencyCreate {
  name: string
  description?: string
  logo_url?: string
  contact_email?: string
  contact_phone?: string
  address?: string
  gallery?: string[]
  locations?: AgencyLocation[]
  contacts?: AgencyContact[]
  opening_hours?: AgencyOpeningHours
}

export interface AgencyRegisterRequest extends AgencyCreate {
  login_email: string
  password: string
}

// ── Route ─────────────────────────────────────────────────────────────────────

export interface RouteStop {
  name: string
  duration_minutes?: number | null // travel time from the previous stop (or from origin, for the first stop)
}

export interface Route {
  id: string
  agency_id: string
  origin: string
  destination: string
  distance_km: number | null
  duration_minutes: number | null
  stops?: RouteStop[] | null
  is_active: boolean
  created_at: string
}

export interface RouteCreate {
  agency_id: string
  origin: string
  destination: string
  distance_km?: number
  duration_minutes?: number
  stops?: RouteStop[]
}

// ── Trip ──────────────────────────────────────────────────────────────────────

export type TripStatus = 'scheduled' | 'departed' | 'completed' | 'cancelled' | 'delayed'

export interface TripRequirement {
  label: string
  value: string
}

export interface Trip {
  id: string
  route_id: string
  boarding_time?: string | null
  departure_datetime: string
  arrival_datetime: string | null
  total_seats: number
  available_seats: number
  price: number
  bus_number: string | null
  status: TripStatus
  has_wifi: boolean
  has_meal: boolean
  has_ac: boolean
  has_usb: boolean
  requirements?: TripRequirement[] | null
  amenities?: string[] | null
  is_active: boolean
  created_at: string
  route?: Route
}

export interface TripCreate {
  route_id: string
  boarding_time?: string
  departure_datetime: string
  arrival_datetime?: string
  total_seats: number
  price: number
  bus_number?: string
  has_wifi?: boolean
  has_meal?: boolean
  has_ac?: boolean
  has_usb?: boolean
  requirements?: TripRequirement[]
  amenities?: string[]
}

export interface TripUpdate {
  route_id?: string
  boarding_time?: string
  departure_datetime?: string
  arrival_datetime?: string
  total_seats?: number
  available_seats?: number
  price?: number
  bus_number?: string
  status?: TripStatus
  has_wifi?: boolean
  has_meal?: boolean
  has_ac?: boolean
  has_usb?: boolean
  requirements?: TripRequirement[]
  amenities?: string[]
}

// ── Booking ───────────────────────────────────────────────────────────────────

export type BookingStatus = 'pending' | 'pending_approval' | 'confirmed' | 'cancelled' | 'completed'

export interface Booking {
  id: string
  user_id: string
  trip_id: string
  seat_number: number | null
  passenger_name: string
  passenger_phone: string | null
  total_price: number
  status: BookingStatus
  created_at: string
  updated_at: string
  trip?: Trip
  ticket?: Ticket
  payment?: Payment
}

export interface BookingCreate {
  trip_id: string
  passenger_name: string
  passenger_phone?: string
  seat_number?: number
  payment_method?: string
}

// ── Ticket ────────────────────────────────────────────────────────────────────

export interface Ticket {
  id: string
  booking_id: string
  ticket_code: string
  qr_data: string
  status: 'active' | 'used' | 'cancelled'
  issued_at: string
}

// ── Payment ───────────────────────────────────────────────────────────────────

export type PaymentMethod = 'mobile_money' | 'tmoney' | 'flooz' | 'bank_transfer' | 'cash' | 'simulated'

export interface Payment {
  id: string
  booking_id: string
  amount: number
  payment_method: PaymentMethod
  status: 'pending' | 'completed' | 'failed' | 'refunded'
  paid_at: string | null
  created_at: string
}

// ── Customer (enriched view of User from agency perspective) ──────────────────

export interface Customer {
  id: string
  user_id: string | null
  full_name: string
  email: string | null
  phone_number: string | null
  booking_count: number
  total_spent: number
  last_travel: string | null
  is_premium: boolean
}

// ── Review ────────────────────────────────────────────────────────────────────

export interface Review {
  id: string
  booking_id: string
  agency_id: string
  user_id: string
  customer_name: string
  rating: number
  comment: string | null
  trip_route: string
  created_at: string
  reply?: string | null
  replied_at?: string | null
}

// ── Messaging ─────────────────────────────────────────────────────────────────

export interface ChatMessage {
  id: string
  conversation_id: string
  sender: 'agency' | 'user'
  text: string
  is_read: boolean
  attachment_url?: string | null
  attachment_name?: string | null
  attachment_type?: string | null
  created_at: string
}

export interface Conversation {
  id: string
  user_id: string
  agency_id: string
  customer_name: string
  created_at: string
  last_message: ChatMessage | null
  unread_count: number
}

// ── Promotion ─────────────────────────────────────────────────────────────────

export interface Promotion {
  id: string
  code: string
  description: string
  discount_percent: number
  valid_from: string
  valid_until: string
  max_uses: number
  used_count: number
  is_active: boolean
  routes: string[]
}

// ── Announcement ──────────────────────────────────────────────────────────────

export interface Announcement {
  id: string
  title: string
  body: string
  target: 'all' | 'previous_customers'
  created_at: string
  sent_count: number
}

// ── Notifications (agency dashboard) ────────────────────────────────────────────

export type AgencyNotificationType = 'booking' | 'review' | 'payment' | 'system' | 'message'

export interface AgencyNotification {
  id: string
  type: AgencyNotificationType
  title: string
  description: string
  created_at: string
  read: boolean
  href?: string
}

// ── Finance helpers ───────────────────────────────────────────────────────────

export interface RevenueDataPoint {
  label: string
  revenue: number
  commission: number
  net: number
  bookings: number
}

export interface PaymentMethodShare {
  method: string
  count: number
  pct: number
}

export interface DashboardStats {
  revenue_this_month: number
  revenue_trend_pct: number | null
  bookings_this_month: number
  bookings_trend_pct: number | null
  active_trips_today: number
  average_rating: number | null
  review_count: number
  cancelled_this_month: number
  active_customers: number
  net_revenue_this_month: number
  platform_fee_rate: number
  revenue_trend: RevenueDataPoint[]
  departures_scheduled_today: number
  checkins_pending_today: number
  new_bookings_today: number
  cancelled_today: number
}

export interface FinanceSummary {
  gross_revenue: number
  net_revenue: number
  commission_paid: number
  total_refunds: number
  total_bookings: number
  avg_revenue_per_trip: number
  platform_fee_rate: number
  net_margin_pct: number
  payment_methods: PaymentMethodShare[]
  revenue_trend: RevenueDataPoint[]
}

export interface TransactionRow {
  id: string
  date: string
  passenger: string
  route: string
  amount: number
  method: PaymentMethod
  status: Payment['status']
  booking_id: string
}

// ── Pagination / API wrapper ──────────────────────────────────────────────────

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  size: number
}

export interface ApiError {
  detail: string
}
