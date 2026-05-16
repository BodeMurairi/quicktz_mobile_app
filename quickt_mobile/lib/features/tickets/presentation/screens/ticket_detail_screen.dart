import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../features/booking/presentation/providers/booking_provider.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

final _ticketDetailProvider =
    FutureProvider.family<TicketModel, String>((ref, id) {
  return ref.read(bookingRepositoryProvider).getTicketDetail(id);
});

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(_ticketDetailProvider(ticketId));

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
      ),
      body: ticketAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) =>
            lw.ErrorWidget(message: 'Failed to load ticket'),
        data: (ticket) => _TicketView(ticket: ticket),
      ),
    );
  }
}

class _TicketView extends StatelessWidget {
  final TicketModel ticket;
  const _TicketView({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final qrData = ticket.qrData ?? ticket.ticketCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.directions_bus_rounded,
                          color: AppColors.white, size: 32),
                      const SizedBox(height: 8),
                      const Text('QuickTZ',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const Text('Travel Ticket',
                          style: TextStyle(
                              color: AppColors.secondary, fontSize: 13)),
                    ],
                  ),
                ),
                // QR Code
                Padding(
                  padding: const EdgeInsets.all(24),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
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
                        fontSize: 12),
                  ),
                ),
                // Dashed divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(
                      30,
                      (_) => Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      _row('Issued',
                          DateFormat('d MMM yyyy, HH:mm').format(ticket.issuedAt)),
                      _row('Booking ID',
                          ticket.bookingId.substring(0, 8).toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Show this QR code to the bus staff\nbefore boarding',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
}
