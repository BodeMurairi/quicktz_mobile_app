from pydantic import BaseModel
from typing import List, Optional


class RevenuePoint(BaseModel):
    label: str
    revenue: float
    commission: float
    net: float
    bookings: int


class PaymentMethodShare(BaseModel):
    method: str
    count: int
    pct: float


class DashboardStats(BaseModel):
    revenue_this_month: float
    revenue_trend_pct: Optional[float] = None
    bookings_this_month: int
    bookings_trend_pct: Optional[float] = None
    active_trips_today: int
    average_rating: Optional[float] = None
    review_count: int = 0
    cancelled_this_month: int
    active_customers: int
    net_revenue_this_month: float
    platform_fee_rate: float
    revenue_trend: List[RevenuePoint]
    departures_scheduled_today: int
    checkins_pending_today: int
    new_bookings_today: int
    cancelled_today: int


class FinanceSummary(BaseModel):
    gross_revenue: float
    net_revenue: float
    commission_paid: float
    total_refunds: float
    total_bookings: int
    avg_revenue_per_trip: float
    platform_fee_rate: float
    net_margin_pct: float
    payment_methods: List[PaymentMethodShare]
    revenue_trend: List[RevenuePoint]
