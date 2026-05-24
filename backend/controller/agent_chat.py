import re
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

# ── Chips extraction ───────────────────────────────────────────────────────────

_CHIPS_RE = re.compile(r'\[CHIPS\](.*?)\[/CHIPS\]', re.DOTALL)


def _extract_chips(text: str) -> tuple[str, Optional[List[str]]]:
    """
    Strip every [CHIPS]...[/CHIPS] block from the agent response,
    return (cleaned_text, chips_list).  Returns None for chips if none found.
    """
    chips: List[str] = []

    def _replace(m: re.Match) -> str:
        items = [c.strip() for c in m.group(1).split('|') if c.strip()]
        chips.extend(items)
        return ''

    clean = _CHIPS_RE.sub(_replace, text).strip()
    # Collapse triple-plus blank lines left after removal
    clean = re.sub(r'\n{3,}', '\n\n', clean).strip()
    return clean, chips if chips else None


# ── Request / response models ──────────────────────────────────────────────────

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
    chips: Optional[List[str]] = None


# ── Endpoint ───────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def agent_chat(
    body: ChatRequest,
    user: User = Depends(get_current_user),
):
    if not body.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    session_id = body.session_id or str(uuid.uuid4())

    # Create fresh mutable containers for this request and bind them so that
    # tool mutations (in-place .extend / .update / .clear) are visible here
    # after run_async completes — ContextVar.set() in child tasks is NOT
    # visible to the parent context, but mutating the shared object IS.
    _trips_buf: list = []
    _booking_buf: dict = {}
    _preview_buf: dict = {}
    last_trip_suggestions.set(_trips_buf)
    last_booking_result.set(_booking_buf)
    pending_booking_preview.set(_preview_buf)
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

    # Strip embedded chips from response text and collect them separately
    response_text, chips = _extract_chips(response_text)

    # Read the mutable containers that tools may have populated in-place.
    booking_data  = last_booking_result.get()    # dict, may be empty {}
    suggestions   = last_trip_suggestions.get()  # list, may be empty []
    preview_raw   = pending_booking_preview.get()  # dict, may be empty {}

    # Build trip suggestion objects
    trip_options: Optional[List[TripOption]] = None
    if suggestions:
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
            for t in suggestions
        ]

    # Build booking preview (only when no confirmed booking this turn)
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
        chips=chips,
    )
