import uuid
from datetime import datetime
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from models.review import Review
from models.booking import Booking
from models.trip import Trip
from schemas.review import ReviewCreate, ReviewResponse, AgencyRatingSummary

_LIST_OPTIONS = (
    selectinload(Review.booking).selectinload(Booking.user),
    selectinload(Review.booking).selectinload(Booking.trip).selectinload(Trip.route),
)


def _to_response(review: Review) -> ReviewResponse:
    booking = review.booking
    route = booking.trip.route if booking and booking.trip else None
    trip_route = f"{route.origin} → {route.destination}" if route else ""
    return ReviewResponse(
        id=review.id,
        booking_id=review.booking_id,
        agency_id=review.agency_id,
        user_id=review.user_id,
        customer_name=booking.user.full_name if booking and booking.user else "Unknown",
        rating=review.rating,
        comment=review.comment,
        trip_route=trip_route,
        reply=review.reply,
        replied_at=review.replied_at,
        created_at=review.created_at,
    )


async def _refetch(db: AsyncSession, review_id: str) -> ReviewResponse:
    result = await db.execute(
        select(Review).where(Review.id == review_id).options(*_LIST_OPTIONS)
    )
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    return _to_response(review)


async def create_review(db: AsyncSession, booking_id: str, user_id: str, data: ReviewCreate) -> ReviewResponse:
    result = await db.execute(
        select(Booking)
        .where(Booking.id == booking_id, Booking.user_id == user_id)
        .options(selectinload(Booking.trip).selectinload(Trip.route))
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != "confirmed":
        raise HTTPException(status_code=400, detail="Only confirmed bookings can be reviewed")
    if not booking.trip or booking.trip.departure_datetime > datetime.utcnow():
        raise HTTPException(status_code=400, detail="You can only review a trip after it has departed")

    existing = await db.execute(select(Review.id).where(Review.booking_id == booking_id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="This booking has already been reviewed")

    review = Review(
        id=str(uuid.uuid4()),
        booking_id=booking_id,
        agency_id=booking.trip.route.agency_id,
        user_id=user_id,
        rating=data.rating,
        comment=data.comment,
    )
    db.add(review)
    await db.commit()
    return await _refetch(db, review.id)


async def list_agency_reviews(db: AsyncSession, agency_id: str) -> List[ReviewResponse]:
    result = await db.execute(
        select(Review)
        .where(Review.agency_id == agency_id)
        .options(*_LIST_OPTIONS)
        .order_by(Review.created_at.desc())
    )
    return [_to_response(r) for r in result.scalars().all()]


async def reply_to_review(db: AsyncSession, review_id: str, agency_id: str, reply_text: str) -> ReviewResponse:
    result = await db.execute(
        select(Review).where(Review.id == review_id, Review.agency_id == agency_id)
    )
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found for this agency")
    review.reply = reply_text
    review.replied_at = datetime.utcnow()
    await db.commit()
    return await _refetch(db, review_id)


async def get_agency_rating_summary(db: AsyncSession, agency_id: str) -> AgencyRatingSummary:
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(Review.agency_id == agency_id)
    )
    avg_rating, count = result.one()
    return AgencyRatingSummary(
        agency_id=agency_id,
        average_rating=round(avg_rating, 1) if avg_rating is not None else None,
        review_count=count or 0,
    )
