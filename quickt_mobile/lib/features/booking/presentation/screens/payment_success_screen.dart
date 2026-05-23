import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/booking_provider.dart';

// Fetches all tickets and returns the one matching this bookingId (or null).
final _ticketForBookingProvider =
    FutureProvider.family<TicketModel?, String>((ref, bookingId) async {
  final tickets =
      await ref.read(bookingRepositoryProvider).getMyTickets();
  try {
    return tickets.firstWhere((t) => t.bookingId == bookingId);
  } catch (_) {
    return null;
  }
});

class PaymentSuccessScreen extends ConsumerWidget {
  final String bookingId;
  const PaymentSuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider).lastBooking;
    final ticketAsync = ref.watch(_ticketForBookingProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // ── Success animation ──────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.white, size: 56),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Payment Successful!',
                  style: TextStyle(
                      color: AppColors.darkPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Your booking is confirmed.\nYour ticket is ready to use.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 15),
              ),
              const SizedBox(height: 36),
              // ── Booking summary card ───────────────────────────────────
              if (booking != null) _BookingSummaryCard(booking: booking),
              const Spacer(),
              // ── CTAs ──────────────────────────────────────────────────
              ticketAsync.when(
                loading: () => AppButton(
                  label: 'Loading ticket…',
                  isLoading: true,
                  onPressed: null,
                ),
                error: (e, _) => _ActionButtons(
                  ticketId: null,
                  onViewHistory: () => context.go('/tickets'),
                ),
                data: (ticket) => _ActionButtons(
                  ticketId: ticket?.id,
                  onViewHistory: () => context.go('/tickets'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Booking summary card ──────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingSummaryCard({required this.booking});

  Color get _statusColor {
    if (booking.isConfirmed) return AppColors.success;
    if (booking.isCancelled) return AppColors.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy, HH:mm');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Reference',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            booking.id.substring(0, 8).toUpperCase(),
            style: const TextStyle(
                color: AppColors.darkPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontFamily: 'monospace'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.background),
          ),
          _Row('Passenger', booking.passengerName),
          _Row('Amount',
              'XOF ${NumberFormat('#,###').format(booking.totalPrice.toInt())}'),
          _Row('Date', fmt.format(booking.createdAt)),
          if (booking.seatNumber != null)
            _Row('Seat', 'Seat ${booking.seatNumber}'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ── CTA buttons ───────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final String? ticketId;
  final VoidCallback onViewHistory;
  const _ActionButtons(
      {required this.ticketId, required this.onViewHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'View My Ticket',
          icon: Icons.confirmation_number_rounded,
          onPressed: ticketId != null
              ? () => context.go('/ticket/$ticketId')
              : onViewHistory,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Go to History',
          outlined: true,
          icon: Icons.history_rounded,
          onPressed: onViewHistory,
        ),
      ],
    );
  }
}
