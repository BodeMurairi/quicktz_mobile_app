// ── Auth ──────────────────────────────────────────────────────────────────────

export interface LoginRequest {
  identifier: string
  password: string
}

export interface RegisterRequest {
  full_name: string
  email: string
  phone_number?: string
  password: string
}

export interface AuthUser {
  id: string
  email: string | null
  phone_number: string | null
  full_name: string
  is_premium: boolean
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
  opening_hours?: AgencyOpeningHours | null
  is_verified: boolean
  is_active: boolean
  created_at: string
  routes?: Route[]
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
  opening_hours?: AgencyOpeningHours
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

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed'

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

export type PaymentMethod = 'mobile_money' | 'tmoney' | 'flooz' | 'bank_transfer' | 'cash'

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
  customer_name: string
  rating: number
  comment: string
  trip_route: string
  created_at: string
  reply?: string
}

// ── Messaging ─────────────────────────────────────────────────────────────────

export interface ChatMessage {
  id: string
  sender: 'agency' | 'customer'
  text: string
  created_at: string
}

export interface Conversation {
  id: string
  customer_id: string
  customer_name: string
  customer_email: string | null
  customer_phone: string | null
  messages: ChatMessage[]
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

export type AgencyNotificationType = 'booking' | 'review' | 'payment' | 'system'

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
