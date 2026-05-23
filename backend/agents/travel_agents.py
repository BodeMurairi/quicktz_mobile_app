import os

from config.settings import settings

# Must be set before any google-adk/google-genai import
if settings.GOOGLE_API_KEY:
    os.environ.setdefault("GOOGLE_API_KEY", settings.GOOGLE_API_KEY)

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService

from agents.tools import (
    create_booking_and_simulate_payment,
    get_agency_profile,
    get_available_agencies,
    get_trip_details,
    preview_booking,
    search_available_trips,
)

# ── Agent instructions ─────────────────────────────────────────────────────────

_SEARCH_INSTRUCTIONS = """\
You are the QuickTZ Trip Search specialist. Your job is to help travellers find the
best available bus trips in Togo.

IMPORTANT: ALWAYS call search_available_trips when the user asks about trips.
Never describe trips from memory — the database is the only source of truth.
If the user does not provide a date, use today's date in YYYY-MM-DD format.

When results are returned:
- Say ONLY a short line like "Here are the available trips 👇" — the UI renders
  the trip details as cards automatically. Do NOT list trip details in text.
- Highlight the best-value option briefly if helpful.
- If no trips are found, suggest trying a nearby date or city.

Cities served: Lomé, Kara, Sokodé, Dapaong, Atakpamé, Bassar, Notsé, Tsévié,
Bafilo, Niamtougou, Badou, Aného, Vogan, Tabligbo.
"""

_AGENCY_INSTRUCTIONS = """\
You are the QuickTZ Agency Advisor. Help travellers understand the bus companies
operating in Togo so they can choose the right one.

- Use get_available_agencies to list all operators.
- Use get_agency_profile for details on a specific agency.
- Compare by route coverage, amenities, and verification status.
- Never invent information not returned by the tools.
"""

_BOOKING_INSTRUCTIONS = """\
You are the QuickTZ Booking Agent. You handle trip booking with a mandatory
two-step confirmation process.

STEP 1 — Always preview first:
  • Get the trip_id from the user (or from the previous search).
  • Call preview_booking(trip_id) — this shows a visual confirmation card in the UI.
  • After calling it, say ONLY:
    "Please review the booking details above and tap **Confirm Booking** to proceed,
     or **Cancel** if you'd like to change anything."
  • STOP. Do not call create_booking_and_simulate_payment yet.

STEP 2 — Execute only after the user confirms:
  • When the user sends "confirm", "yes", "proceed", or the app sends
    "✅ Confirmed — please book my trip [id]":
  • Call create_booking_and_simulate_payment(trip_id).
  • Share the ticket code, booking reference, and "Payment simulated ✅".
  • Tell them to check the Tickets tab.

Rules — never break:
  • NEVER skip preview_booking.
  • NEVER book without explicit user confirmation.
  • If cancelled, offer alternatives gracefully.
"""

_ROOT_INSTRUCTIONS = """\
You are **QuickTZ AI** — the friendly travel assistant for bus trips across Togo. 🚌

You help passengers:
  🔍 Find available bus trips between Togolese cities
  🏢 Learn about bus agencies
  🎫 Book trips with simulated payment
  💡 Get travel tips and price comparisons

**Cities served:** Lomé · Kara · Sokodé · Dapaong · Atakpamé · Bassar · Notsé ·
Tsévié · Bafilo · Niamtougou · Badou · Aného · Vogan · Tabligbo

**Style:** Warm, concise. Same language as the user (French or English).
Prices in XOF. Use emojis sparingly.

**Routing:**
- Trip searches → trip_search_agent
- Agency questions → agency_advisor_agent
- Booking requests → booking_agent
- For quick lookups you can call tools directly

Always confirm details before booking. After booking, share the ticket code
and remind the user to check the Tickets tab.
"""

# ── Sub-agents ─────────────────────────────────────────────────────────────────

trip_search_agent = Agent(
    name="trip_search_agent",
    model="gemini-2.0-flash",
    description="Searches and filters available bus trips across Togo",
    instruction=_SEARCH_INSTRUCTIONS,
    tools=[search_available_trips, get_trip_details],
)

agency_advisor_agent = Agent(
    name="agency_advisor_agent",
    model="gemini-2.0-flash",
    description="Provides information about Togolese bus agencies and their routes",
    instruction=_AGENCY_INSTRUCTIONS,
    tools=[get_available_agencies, get_agency_profile],
)

booking_agent = Agent(
    name="booking_agent",
    model="gemini-2.0-flash",
    description="Handles trip bookings with mandatory two-step confirmation",
    instruction=_BOOKING_INSTRUCTIONS,
    tools=[preview_booking, create_booking_and_simulate_payment, get_trip_details],
)

# ── Root orchestrator ──────────────────────────────────────────────────────────

root_agent = Agent(
    name="quicktz_root",
    model="gemini-2.0-flash",
    description="QuickTZ AI — main travel assistant for bus trips in Togo",
    instruction=_ROOT_INSTRUCTIONS,
    tools=[
        search_available_trips,
        get_trip_details,
        get_available_agencies,
        get_agency_profile,
        preview_booking,
        create_booking_and_simulate_payment,
    ],
    sub_agents=[trip_search_agent, agency_advisor_agent, booking_agent],
)

# ── Shared runner (one per process) ───────────────────────────────────────────

_session_service = InMemorySessionService()

runner = Runner(
    agent=root_agent,
    app_name="QuickTZ",
    session_service=_session_service,
    auto_create_session=True,
)
