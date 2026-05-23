import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from google.genai import types
from pydantic import BaseModel

from agents.tools import (
    current_user_id,
    last_booking_result,
    last_trip_suggestions,
    pending_booking_preview,
)
from agents.travel_agents import runner
from middleware.auth import get_current_user
from models.user import User

router = APIRouter()


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class TripAmenities(BaseModel):
    wifi: bool = False
    meal: bool = False
    ac: bool = False
    usb: bool = False


class TripOption(BaseModel):
    id: str
    agency: str
    origin: str
    destination: str
    departure: str
    arrival: str
    price_xof: int
    available_seats: int
    amenities: TripAmenities


class BookingPreview(BaseModel):
    trip_id: str
    agency: str
    origin: str
    destination: str
    departure: str
    arrival: str
    price_xof: int
    passenger_name: str
    passenger_phone: str
    payment_method: str


class ChatResponse(BaseModel):
    response: str
    session_id: str
    action: Optional[str] = None
    booking_id: Optional[str] = None
    ticket_code: Optional[str] = None
    trip_suggestions: Optional[List[TripOption]] = None
    booking_preview: Optional[BookingPreview] = None


@router.post("/chat", response_model=ChatResponse)
async def agent_chat(
    body: ChatRequest,
    user: User = Depends(get_current_user),
):
    if not body.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    session_id = body.session_id or str(uuid.uuid4())

    # Reset all per-request surface vars
    last_booking_result.set(None)
    last_trip_suggestions.set(None)
    pending_booking_preview.set(None)
    current_user_id.set(str(user.id))

    response_text = ""
    try:
        async for event in runner.run_async(
            user_id=str(user.id),
            session_id=session_id,
            new_message=types.Content(
                role="user",
                parts=[types.Part(text=body.message.strip())],
            ),
        ):
            # Collect the final response text; do NOT break — breaking sends
            # GeneratorExit into the ADK generator which triggers an OpenTelemetry
            # cleanup bug (ContextVar created in a different context).
            if event.is_final_response():
                if event.content and event.content.parts:
                    response_text = event.content.parts[0].text or ""
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Agent error: {exc}") from exc

    if not response_text:
        response_text = "I'm sorry, I couldn't process your request right now. Please try again."

    booking_data = last_booking_result.get()
    suggestions_raw = last_trip_suggestions.get()
    preview_raw = pending_booking_preview.get()

    # Build trip suggestion objects
    trip_options: Optional[List[TripOption]] = None
    if suggestions_raw:
        trip_options = [
            TripOption(
                id=t["id"],
                agency=t["agency"],
                origin=t["origin"],
                destination=t["destination"],
                departure=t["departure"],
                arrival=t["arrival"],
                price_xof=t["price_xof"],
                available_seats=t["available_seats"],
                amenities=TripAmenities(**t.get("amenities", {})),
            )
            for t in suggestions_raw
        ]

    # Build booking preview object (only if no booking was confirmed this turn)
    booking_preview: Optional[BookingPreview] = None
    if preview_raw and not booking_data:
        booking_preview = BookingPreview(
            trip_id=preview_raw["trip_id"],
            agency=preview_raw["agency"],
            origin=preview_raw["origin"],
            destination=preview_raw["destination"],
            departure=preview_raw["departure"],
            arrival=preview_raw.get("arrival", "N/A"),
            price_xof=preview_raw["price_xof"],
            passenger_name=preview_raw["passenger_name"],
            passenger_phone=preview_raw["passenger_phone"],
            payment_method=preview_raw["payment_method"],
        )

    return ChatResponse(
        response=response_text,
        session_id=session_id,
        action="booking_confirmed" if booking_data else None,
        booking_id=booking_data.get("booking_id") if booking_data else None,
        ticket_code=booking_data.get("ticket_code") if booking_data else None,
        trip_suggestions=trip_options,
        booking_preview=booking_preview,
    )
