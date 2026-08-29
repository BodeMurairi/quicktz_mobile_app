from datetime import datetime, timedelta
from typing import Dict, List, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from models.booking import Booking
from models.trip import Trip
from models.route import Route
from models.payment import Payment
from models.ticket import Ticket
from schemas.analytics import RevenuePoint, PaymentMethodShare, DashboardStats, FinanceSummary
from services.review_service import get_agency_rating_summary
from services.customer_service import list_agency_customers
from config.settings import get_settings


def _commission_rate() -> float:
    """Read fresh from .env on every call (via get_settings(), not the cached
    `settings` singleton) so editing COMMISSION_RATE takes effect without a
    server restart. Stored in .env as a percentage (e.g. 4.0 = 4%)."""
    return get_settings().COMMISSION_RATE / 100


async def _agency_bookings(db: AsyncSession, agency_id: str) -> List[Booking]:
    result = await db.execute(
        select(Booking)
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(Route.agency_id == agency_id, Booking.status != "cancelled")
        .options(selectinload(Booking.payment))
    )
    return list(result.scalars().unique().all())


def _bucket_key(dt: datetime, period: str) -> Tuple[datetime, str]:
    if period == "weekly":
        start = (dt - timedelta(days=dt.weekday())).replace(
            hour=0, minute=0, second=0, microsecond=0)
        return start, start.strftime("%d %b")
    if period == "quarterly":
        q = (dt.month - 1) // 3 + 1
        start = datetime(dt.year, 3 * (q - 1) + 1, 1)
        return start, f"Q{q} {dt.year}"
    if period == "yearly":
        start = datetime(dt.year, 1, 1)
        return start, str(dt.year)
    # monthly (default)
    start = datetime(dt.year, dt.month, 1)
    return start, start.strftime("%b")


async def get_revenue_trend(
    db: AsyncSession, agency_id: str, period: str = "monthly", limit: int = 7
) -> List[RevenuePoint]:
    bookings = await _agency_bookings(db, agency_id)
    rate = _commission_rate()

    buckets: Dict[datetime, Dict] = {}
    for b in bookings:
        start, label = _bucket_key(b.created_at, period)
        bucket = buckets.setdefault(start, {"label": label, "revenue": 0.0, "bookings": 0})
        bucket["revenue"] += b.total_price
        bucket["bookings"] += 1

    ordered = sorted(buckets.items(), key=lambda kv: kv[0])[-limit:]
    points = []
    for _, v in ordered:
        commission = v["revenue"] * rate
        points.append(RevenuePoint(
            label=v["label"],
            revenue=v["revenue"],
            commission=commission,
            net=v["revenue"] - commission,
            bookings=v["bookings"],
        ))
    return points


async def get_dashboard_stats(db: AsyncSession, agency_id: str) -> DashboardStats:
    now = datetime.utcnow()
    month_start = datetime(now.year, now.month, 1)
    if now.month == 1:
        last_month_start = datetime(now.year - 1, 12, 1)
    else:
        last_month_start = datetime(now.year, now.month - 1, 1)

    bookings = await _agency_bookings(db, agency_id)
    this_month = [b for b in bookings if b.created_at >= month_start]
    last_month = [b for b in bookings if last_month_start <= b.created_at < month_start]

    revenue_this_month = sum(b.total_price for b in this_month)
    revenue_last_month = sum(b.total_price for b in last_month)
    revenue_trend_pct = (
        round((revenue_this_month - revenue_last_month) / revenue_last_month * 100, 1)
        if revenue_last_month > 0 else None
    )
    bookings_trend_pct = (
        round((len(this_month) - len(last_month)) / len(last_month) * 100, 1)
        if len(last_month) > 0 else None
    )
    rate = _commission_rate()
    net_revenue_this_month = revenue_this_month * (1 - rate)

    today_start = datetime(now.year, now.month, now.day)
    today_end = today_start + timedelta(days=1)

    trip_result = await db.execute(
        select(Trip).join(Route, Trip.route_id == Route.id)
        .where(
            Route.agency_id == agency_id,
            Trip.departure_datetime >= today_start,
            Trip.departure_datetime < today_end,
            Trip.status != "cancelled",
        )
    )
    todays_trips = list(trip_result.scalars().all())
    active_trips_today = len(todays_trips)
    departures_scheduled_today = len([t for t in todays_trips if t.status == "scheduled"])

    checkins_pending_today = 0
    todays_trip_ids = [t.id for t in todays_trips]
    if todays_trip_ids:
        ticket_result = await db.execute(
            select(func.count(Ticket.id))
            .join(Booking, Ticket.booking_id == Booking.id)
            .where(Booking.trip_id.in_(todays_trip_ids), Ticket.status == "active")
        )
        checkins_pending_today = ticket_result.scalar_one()

    cancelled_today_result = await db.execute(
        select(func.count(Booking.id))
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(
            Route.agency_id == agency_id, Booking.status == "cancelled",
            Booking.updated_at >= today_start, Booking.updated_at < today_end,
        )
    )
    cancelled_today = cancelled_today_result.scalar_one()

    cancelled_month_result = await db.execute(
        select(func.count(Booking.id))
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(
            Route.agency_id == agency_id, Booking.status == "cancelled",
            Booking.updated_at >= month_start,
        )
    )
    cancelled_this_month = cancelled_month_result.scalar_one()

    new_bookings_today = len([
        b for b in bookings if today_start <= b.created_at < today_end
    ])

    rating_summary = await get_agency_rating_summary(db, agency_id)
    customers = await list_agency_customers(db, agency_id)
    revenue_trend = await get_revenue_trend(db, agency_id, period="monthly", limit=7)

    return DashboardStats(
        revenue_this_month=revenue_this_month,
        revenue_trend_pct=revenue_trend_pct,
        bookings_this_month=len(this_month),
        bookings_trend_pct=bookings_trend_pct,
        active_trips_today=active_trips_today,
        average_rating=rating_summary.average_rating,
        review_count=rating_summary.review_count,
        cancelled_this_month=cancelled_this_month,
        active_customers=len(customers),
        net_revenue_this_month=net_revenue_this_month,
        platform_fee_rate=rate,
        revenue_trend=revenue_trend,
        departures_scheduled_today=departures_scheduled_today,
        checkins_pending_today=checkins_pending_today,
        new_bookings_today=new_bookings_today,
        cancelled_today=cancelled_today,
    )


async def get_finance_summary(db: AsyncSession, agency_id: str, period: str = "monthly") -> FinanceSummary:
    bookings = await _agency_bookings(db, agency_id)
    rate = _commission_rate()
    gross_revenue = sum(b.total_price for b in bookings)
    commission_paid = gross_revenue * rate
    net_revenue = gross_revenue - commission_paid
    total_bookings = len(bookings)
    avg_revenue_per_trip = gross_revenue / total_bookings if total_bookings else 0.0
    net_margin_pct = round(net_revenue / gross_revenue * 100, 1) if gross_revenue else 0.0

    refund_result = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0.0))
        .join(Booking, Payment.booking_id == Booking.id)
        .join(Trip, Booking.trip_id == Trip.id)
        .join(Route, Trip.route_id == Route.id)
        .where(Route.agency_id == agency_id, Payment.status == "refunded")
    )
    total_refunds = refund_result.scalar_one() or 0.0

    method_counts: Dict[str, int] = {}
    for b in bookings:
        method = b.payment.payment_method if b.payment else "unknown"
        method_counts[method] = method_counts.get(method, 0) + 1
    payment_methods = [
        PaymentMethodShare(method=method, count=count, pct=round(count / total_bookings * 100, 1))
        for method, count in sorted(method_counts.items(), key=lambda kv: -kv[1])
    ] if total_bookings else []

    revenue_trend = await get_revenue_trend(db, agency_id, period=period, limit=7)

    return FinanceSummary(
        gross_revenue=gross_revenue,
        net_revenue=net_revenue,
        commission_paid=commission_paid,
        total_refunds=total_refunds,
        total_bookings=total_bookings,
        avg_revenue_per_trip=avg_revenue_per_trip,
        platform_fee_rate=rate,
        net_margin_pct=net_margin_pct,
        payment_methods=payment_methods,
        revenue_trend=revenue_trend,
    )
