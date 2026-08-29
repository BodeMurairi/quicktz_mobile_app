from io import BytesIO

import qrcode
from qrcode.image.pil import PilImage
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

from models.booking import Booking

# Mirrors the mobile app's ticket PDF exactly — same fields, colors, fonts, layout.
# See quickt_mobile/lib/features/tickets/presentation/screens/ticket_detail_screen.dart
# (_generateAndSharePdf) — this is the reference design; keep both in sync.

DARK_BLUE = HexColor("#1B3D6E")
GREY_700 = HexColor("#616161")
GREY_600 = HexColor("#757575")
GREY_300 = HexColor("#E0E0E0")
BLUEGREY_200 = HexColor("#B0BEC5")
GREEN_50 = HexColor("#E8F5E9")
GREEN_800 = HexColor("#2E7D32")
RED_50 = HexColor("#FFEBEE")
RED_800 = HexColor("#C62828")

MARGIN_X = 36
MARGIN_TOP = 40
MARGIN_BOTTOM = 40


def _qr_image(data: str) -> ImageReader:
    qr = qrcode.QRCode(border=1, box_size=10)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#1B3D6E", back_color="white", image_factory=PilImage)
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return ImageReader(buf)


def generate_ticket_pdf(booking: Booking) -> bytes:
    ticket = booking.ticket
    trip = booking.trip
    route = trip.route if trip else None

    buf = BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    page_width, page_height = A4
    content_width = page_width - 2 * MARGIN_X
    center_x = page_width / 2

    y = page_height - MARGIN_TOP

    # ── Header ───────────────────────────────────────────────────────────────
    header_height = 130
    c.setFillColor(DARK_BLUE)
    c.roundRect(MARGIN_X, y - header_height, content_width, header_height, 12, fill=1, stroke=0)

    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 26)
    c.drawCentredString(center_x, y - 34, "QuickTZ")

    c.setFillColor(BLUEGREY_200)
    c.setFont("Helvetica", 12)
    c.drawCentredString(center_x, y - 52, "Travel Ticket")

    origin = route.origin if route else "-"
    destination = route.destination if route else "-"
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(center_x, y - 84, f"{origin}   →   {destination}")

    y -= header_height + 28

    # ── QR code ──────────────────────────────────────────────────────────────
    qr_data = (ticket.qr_data if ticket and ticket.qr_data else (ticket.ticket_code if ticket else booking.id))
    qr_size = 160
    c.drawImage(_qr_image(qr_data), center_x - qr_size / 2, y - qr_size, qr_size, qr_size, mask="auto")
    y -= qr_size + 10

    # ── Ticket code ──────────────────────────────────────────────────────────
    c.setFillColor(DARK_BLUE)
    c.setFont("Helvetica-Bold", 18)
    code_text = ticket.ticket_code if ticket else "—"
    c.drawCentredString(center_x, y - 14, _letterspace(code_text, 2.5))
    y -= 30

    # ── Status pill ──────────────────────────────────────────────────────────
    status = (ticket.status if ticket else "unknown").upper()
    is_active = ticket and ticket.status == "active"
    pill_bg = GREEN_50 if is_active else RED_50
    pill_fg = GREEN_800 if is_active else RED_800
    c.setFont("Helvetica-Bold", 11)
    pill_width = c.stringWidth(status, "Helvetica-Bold", 11) + 24
    pill_height = 20
    c.setFillColor(pill_bg)
    c.roundRect(center_x - pill_width / 2, y - pill_height, pill_width, pill_height, 6, fill=1, stroke=0)
    c.setFillColor(pill_fg)
    c.drawCentredString(center_x, y - pill_height + 6, status)
    y -= pill_height + 24

    # ── Divider ──────────────────────────────────────────────────────────────
    c.setStrokeColor(GREY_300)
    c.line(MARGIN_X, y, page_width - MARGIN_X, y)
    y -= 18

    # ── Details ──────────────────────────────────────────────────────────────
    rows = [
        ("Date", trip.departure_datetime.strftime("%a, %-d %b %Y") if trip else "—"),
        ("Departure", trip.departure_datetime.strftime("%H:%M") if trip else "—"),
        ("Passenger", booking.passenger_name),
        ("Seat", f"Seat {booking.seat_number}" if booking.seat_number else "Any available"),
    ]
    if booking.passenger_phone:
        rows.append(("Phone", booking.passenger_phone))
    rows.append(("Amount", f"XOF {int(booking.total_price):,}"))
    rows.append(("Booking Ref", booking.id[:8].upper()))

    for label, value in rows:
        c.setFillColor(GREY_700)
        c.setFont("Helvetica", 11)
        c.drawString(MARGIN_X, y - 9, label)
        c.setFillColor(DARK_BLUE)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(MARGIN_X + 110, y - 9, value)
        y -= 21

    # ── Footer ───────────────────────────────────────────────────────────────
    footer_y = MARGIN_BOTTOM
    c.setStrokeColor(GREY_300)
    c.line(MARGIN_X, footer_y + 20, page_width - MARGIN_X, footer_y + 20)
    c.setFillColor(GREY_600)
    c.setFont("Helvetica", 9)
    c.drawCentredString(center_x, footer_y + 8, "Present this QR code to bus staff before boarding. Issued by QuickTZ.")

    c.showPage()
    c.save()
    buf.seek(0)
    return buf.read()


def _letterspace(text: str, spacing: float) -> str:
    # reportlab's canvas has no built-in letter-spacing for drawCentredString —
    # approximating the mobile PDF's letterSpacing: 2.5 by joining characters
    # with a thin space reads close enough for a short all-caps ticket code.
    return " ".join(text)
