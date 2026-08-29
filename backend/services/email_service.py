import smtplib
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from html import escape
from typing import Optional

from fastapi import HTTPException

from config.settings import get_settings

# Brand colors — kept in sync with quickt_mobile's AppColors and the ticket PDF.
DARK_BLUE = "#0D2440"
PRIMARY = "#2E5E99"
SECONDARY = "#7BA4D0"
BACKGROUND = "#E7F0FA"


def _build_ticket_html(
    body: str,
    passenger_name: str,
    origin: Optional[str],
    destination: Optional[str],
    departure_label: Optional[str],
    ticket_code: Optional[str],
    agency_name: str,
) -> str:
    body_html = escape(body).replace("\n", "<br>")
    route_row = ""
    if origin and destination:
        route_row = f"""
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{BACKGROUND};border-radius:12px;margin:0 0 20px;">
          <tr>
            <td style="padding:16px 18px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="font-size:16px;font-weight:700;color:{DARK_BLUE};font-family:Arial,Helvetica,sans-serif;">{escape(origin)}</td>
                  <td style="font-size:14px;color:{PRIMARY};font-family:Arial,Helvetica,sans-serif;text-align:center;width:32px;">&#8594;</td>
                  <td style="font-size:16px;font-weight:700;color:{DARK_BLUE};font-family:Arial,Helvetica,sans-serif;text-align:right;">{escape(destination)}</td>
                </tr>
              </table>
              {f'<p style="margin:10px 0 0;font-size:12px;color:#6b7280;font-family:Arial,Helvetica,sans-serif;">{escape(departure_label)}</p>' if departure_label else ''}
            </td>
          </tr>
        </table>
        """

    attachment_note = (
        f'📎 Your QR boarding pass is attached as a PDF'
        + (f' — <strong>{escape(ticket_code)}</strong>' if ticket_code else '')
    )

    return f"""<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;background:{BACKGROUND};font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{BACKGROUND};padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;">
            <tr>
              <td style="background:{DARK_BLUE};padding:28px 24px;text-align:center;">
                <div style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:0.5px;">QuickTZ</div>
                <div style="color:{SECONDARY};font-size:12px;margin-top:4px;">Your Travel Ticket</div>
              </td>
            </tr>
            <tr>
              <td style="padding:28px 24px 8px;">
                <p style="margin:0 0 16px;font-size:15px;color:{DARK_BLUE};">Hi {escape(passenger_name)},</p>
                <div style="margin:0 0 20px;font-size:14px;line-height:1.6;color:#374151;">{body_html}</div>
                {route_row}
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFF7E6;border-radius:10px;">
                  <tr>
                    <td style="padding:12px 14px;font-size:13px;color:#92600a;">{attachment_note}</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="background:#F3F6FB;padding:16px 24px;text-align:center;">
                <p style="margin:0;font-size:11px;color:#9ca3af;">Sent by {escape(agency_name)} via QuickTZ</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>"""


def _build_reset_html(name: str, code: str) -> str:
    return f"""<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;background:{BACKGROUND};font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{BACKGROUND};padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;">
            <tr>
              <td style="background:{DARK_BLUE};padding:28px 24px;text-align:center;">
                <div style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:0.5px;">QuickTZ</div>
                <div style="color:{SECONDARY};font-size:12px;margin-top:4px;">Password Reset</div>
              </td>
            </tr>
            <tr>
              <td style="padding:28px 24px;">
                <p style="margin:0 0 16px;font-size:15px;color:{DARK_BLUE};">Hi {escape(name)},</p>
                <p style="margin:0 0 20px;font-size:14px;line-height:1.6;color:#374151;">
                  Use this code to reset your password. It expires in 15 minutes.
                </p>
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{BACKGROUND};border-radius:10px;">
                  <tr>
                    <td style="padding:18px;text-align:center;">
                      <span style="font-size:28px;font-weight:800;letter-spacing:6px;color:{DARK_BLUE};">{escape(code)}</span>
                    </td>
                  </tr>
                </table>
                <p style="margin:20px 0 0;font-size:12px;color:#9ca3af;">
                  If you didn't request this, you can safely ignore this email.
                </p>
              </td>
            </tr>
            <tr>
              <td style="background:#F3F6FB;padding:16px 24px;text-align:center;">
                <p style="margin:0;font-size:11px;color:#9ca3af;">QuickTZ</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>"""


def send_password_reset_email(to: str, name: str, code: str) -> None:
    settings = get_settings()
    if not (settings.SMTP_HOST and settings.SMTP_USER and settings.SMTP_PASSWORD):
        raise HTTPException(
            status_code=503,
            detail="Email sending is not configured — add SMTP_HOST/SMTP_USER/SMTP_PASSWORD to .env.",
        )

    from_addr = settings.SMTP_FROM_EMAIL or settings.SMTP_USER

    msg = MIMEMultipart("alternative")
    msg["From"] = from_addr
    msg["To"] = to
    msg["Subject"] = "Your QuickTZ password reset code"
    msg.attach(MIMEText(f"Your password reset code is {code}. It expires in 15 minutes.", "plain"))
    msg.attach(MIMEText(_build_reset_html(name or to, code), "html"))

    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as server:
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(from_addr, [to], msg.as_string())
    except smtplib.SMTPException as e:
        raise HTTPException(status_code=502, detail=f"Failed to send email: {e}")


def send_email_with_attachment(
    to: str,
    subject: str,
    body: str,
    attachment_bytes: bytes,
    attachment_filename: str,
    passenger_name: str = "",
    origin: Optional[str] = None,
    destination: Optional[str] = None,
    departure_label: Optional[str] = None,
    ticket_code: Optional[str] = None,
    agency_name: str = "QuickTZ",
) -> None:
    settings = get_settings()
    if not (settings.SMTP_HOST and settings.SMTP_USER and settings.SMTP_PASSWORD):
        raise HTTPException(
            status_code=503,
            detail="Email sending is not configured — add SMTP_HOST/SMTP_USER/SMTP_PASSWORD to .env.",
        )

    from_addr = settings.SMTP_FROM_EMAIL or settings.SMTP_USER

    msg = MIMEMultipart("mixed")
    msg["From"] = from_addr
    msg["To"] = to
    msg["Subject"] = subject

    alt = MIMEMultipart("alternative")
    alt.attach(MIMEText(body, "plain"))
    alt.attach(MIMEText(
        _build_ticket_html(
            body, passenger_name or to, origin, destination,
            departure_label, ticket_code, agency_name,
        ),
        "html",
    ))
    msg.attach(alt)

    part = MIMEApplication(attachment_bytes, Name=attachment_filename)
    part["Content-Disposition"] = f'attachment; filename="{attachment_filename}"'
    msg.attach(part)

    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as server:
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(from_addr, [to], msg.as_string())
    except smtplib.SMTPException as e:
        raise HTTPException(status_code=502, detail=f"Failed to send email: {e}")
