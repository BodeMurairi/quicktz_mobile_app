import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../features/booking/presentation/providers/booking_provider.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

// ── Data bundle ───────────────────────────────────────────────────────────────

class _FullTicketData {
  final TicketModel ticket;
  final BookingModel booking;
  final TripModel trip;
  const _FullTicketData(
      {required this.ticket, required this.booking, required this.trip});
}

final _fullTicketProvider =
    FutureProvider.family<_FullTicketData, String>((ref, ticketId) async {
  final bookingRepo = ref.read(bookingRepositoryProvider);
  final tripRepo = ref.read(tripRepositoryProvider);
  final ticket = await bookingRepo.getTicketDetail(ticketId);
  final booking = await bookingRepo.getBookingDetail(ticket.bookingId);
  final trip = await tripRepo.getTripDetail(booking.tripId);
  return _FullTicketData(ticket: ticket, booking: booking, trip: trip);
});

// ── PDF helper ────────────────────────────────────────────────────────────────

Future<void> _generateAndSharePdf(_FullTicketData d) async {
  final ticket = d.ticket;
  final booking = d.booking;
  final trip = d.trip;
  final dateFmt = DateFormat('EEE, d MMM yyyy');
  final timeFmt = DateFormat('HH:mm');

  final doc = pw.Document(title: 'QuickTZ Ticket ${ticket.ticketCode}');

  // Load a font (uses Helvetica built-in — no asset needed)
  final boldFont = pw.Font.helveticaBold();
  final regularFont = pw.Font.helvetica();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 22, horizontal: 24),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.106, 0.239, 0.431), // darkPrimary
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('QuickTZ',
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 26,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text('Travel Ticket',
                      style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 12,
                          color: PdfColors.blueGrey200)),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    '${trip.route?.origin ?? '-'}  →  ${trip.route?.destination ?? '-'}',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 28),

            // ── QR code ──────────────────────────────────────────────────────
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: ticket.qrData ?? ticket.ticketCode,
              width: 160,
              height: 160,
              color: const PdfColor(0.106, 0.239, 0.431),
            ),

            pw.SizedBox(height: 10),

            pw.Text(ticket.ticketCode,
                style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    letterSpacing: 2.5,
                    color: const PdfColor(0.106, 0.239, 0.431))),

            pw.SizedBox(height: 6),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: ticket.isActive
                    ? PdfColors.green50
                    : PdfColors.red50,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                ticket.status.toUpperCase(),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color:
                      ticket.isActive ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
            ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 18),

            // ── Details ──────────────────────────────────────────────────────
            _pdfRow(boldFont, regularFont, 'Date',
                dateFmt.format(trip.departureDatetime)),
            _pdfRow(boldFont, regularFont, 'Departure',
                timeFmt.format(trip.departureDatetime)),
            _pdfRow(
                boldFont, regularFont, 'Passenger', booking.passengerName),
            _pdfRow(
                boldFont,
                regularFont,
                'Seat',
                booking.seatNumber != null
                    ? 'Seat ${booking.seatNumber}'
                    : 'Any available'),
            if (booking.passengerPhone != null)
              _pdfRow(boldFont, regularFont, 'Phone',
                  booking.passengerPhone!),
            _pdfRow(
                boldFont,
                regularFont,
                'Amount',
                'XOF ${NumberFormat('#,###').format(booking.totalPrice.toInt())}'),
            _pdfRow(boldFont, regularFont, 'Booking Ref',
                booking.id.substring(0, 8).toUpperCase()),

            pw.Spacer(),

            // ── Footer ───────────────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text(
              'Present this QR code to bus staff before boarding. Issued by QuickTZ.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'quicktz-${ticket.ticketCode}.pdf',
  );
}

pw.Widget _pdfRow(
    pw.Font bold, pw.Font regular, String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(label,
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 11,
                  color: PdfColors.grey700)),
        ),
        pw.Expanded(
          child: pw.Text(value,
              style: pw.TextStyle(
                  font: bold,
                  fontSize: 11,
                  color: const PdfColor(0.106, 0.239, 0.431))),
        ),
      ],
    ),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_fullTicketProvider(ticketId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text('My Ticket',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => context.go('/tickets'),
        ),
        actions: [
          dataAsync.whenOrNull(
                data: (d) => IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.white),
                  tooltip: 'Download PDF',
                  onPressed: () => _generateAndSharePdf(d),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: dataAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) =>
            lw.ErrorWidget(message: 'Failed to load ticket'),
        data: (d) => _TicketView(data: d),
      ),
    );
  }
}

// ── Ticket view ───────────────────────────────────────────────────────────────

class _TicketView extends StatelessWidget {
  final _FullTicketData data;
  const _TicketView({required this.data});

  @override
  Widget build(BuildContext context) {
    final ticket = data.ticket;
    final booking = data.booking;
    final trip = data.trip;
    final qrData = ticket.qrData ?? ticket.ticketCode;
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.directions_bus_rounded,
                          color: AppColors.white, size: 28),
                      const SizedBox(height: 6),
                      const Text('QuickTZ',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const Text('Travel Ticket',
                          style: TextStyle(
                              color: AppColors.secondary, fontSize: 12)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.route?.origin ?? '-',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.secondary, size: 18),
                            ),
                            Text(
                              trip.route?.destination ?? '-',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── QR code ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.darkPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  ticket.ticketCode,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: TextStyle(
                        color: ticket.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),

                // ── Tear line ────────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const _TearNotch(left: true),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (_, c) => Row(
                            children: List.generate(
                              (c.maxWidth / 8).floor(),
                              (_) => Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const _TearNotch(left: false),
                    ],
                  ),
                ),

                // ── Trip details ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: dateFmt.format(trip.departureDatetime)),
                      _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Departure',
                          value: timeFmt.format(trip.departureDatetime)),
                      _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Passenger',
                          value: booking.passengerName),
                      _DetailRow(
                          icon: Icons.event_seat_outlined,
                          label: 'Seat',
                          value: booking.seatNumber != null
                              ? 'Seat ${booking.seatNumber}'
                              : 'Any available'),
                      if (booking.passengerPhone != null)
                        _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: booking.passengerPhone!),
                      _DetailRow(
                          icon: Icons.receipt_outlined,
                          label: 'Amount',
                          value:
                              'XOF ${NumberFormat('#,###').format(booking.totalPrice.toInt())}'),
                      _DetailRow(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Booking',
                          value:
                              booking.id.substring(0, 8).toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Show this QR code to the bus staff\nbefore boarding',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── PDF download button ──────────────────────────────────────────
          _DownloadPdfButton(data: data),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TearNotch extends StatelessWidget {
  final bool left;
  const _TearNotch({required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.zero : const Radius.circular(10),
          right: left ? const Radius.circular(10) : Radius.zero,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── PDF download button (stateful for loading state) ──────────────────────────

class _DownloadPdfButton extends StatefulWidget {
  final _FullTicketData data;
  const _DownloadPdfButton({required this.data});

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      await _generateAndSharePdf(widget.data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.picture_as_pdf_rounded, size: 20),
        label: Text(
          _loading ? 'Generating PDF…' : 'Download Ticket as PDF',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _loading ? null : _download,
      ),
    );
  }
}
