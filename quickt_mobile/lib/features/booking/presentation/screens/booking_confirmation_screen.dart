import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;
import '../providers/booking_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../features/notifications/presentation/providers/notification_provider.dart';
import 'passenger_info_screen.dart' show BookingStepIndicator;

final _tripForBookingProvider =
    FutureProvider.family<TripModel, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getTripDetail(id);
});

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String tripId;
  const BookingConfirmationScreen({super.key, required this.tripId});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  String _paymentMethod = 'tmoney';
  PassengerInfo? _passengerInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is PassengerInfo) _passengerInfo = extra;
  }

  Future<void> _confirm(TripModel trip) async {
    final info = _passengerInfo;
    final booking = await ref.read(bookingProvider.notifier).book(
          tripId: widget.tripId,
          passengerName: info?.fullName ?? 'Passenger',
          passengerPhone: info?.phone.isEmpty == true ? null : info?.phone,
          paymentMethod: _paymentMethod,
        );
    if (mounted && booking != null) {
      final origin = trip.route?.origin ?? '';
      final dest = trip.route?.destination ?? '';
      final amount = trip.price.toStringAsFixed(0);
      final notifier = ref.read(notificationProvider.notifier);

      // In-app notifications
      notifier.addLocalNotification(
        title: 'Booking Confirmed!',
        body: 'Your trip from $origin to $dest has been booked.',
        type: 'booking',
      );
      notifier.addLocalNotification(
        title: 'Payment Successful',
        body: 'XOF $amount paid via $_paymentMethod.',
        type: 'booking',
      );

      // Device push notifications (fire-and-forget, no await needed)
      unawaited(NotificationService.instance.showBookingConfirmed(
        origin: origin,
        destination: dest,
        ticketCode: booking.id.substring(0, 8).toUpperCase(),
      ));
      unawaited(NotificationService.instance.showPaymentSuccess(
        amount: amount,
        method: _paymentMethod,
      ));

      if (mounted) context.go('/booking-success/${booking.id}');
    }
  }

  Future<void> _simulatePayment() async {
    final booking =
        await ref.read(bookingProvider.notifier).simulateBook(widget.tripId);
    if (mounted && booking != null) {
      ref.read(notificationProvider.notifier).addLocalNotification(
        title: 'Booking Confirmed!',
        body: 'Your trip has been booked and payment simulated successfully.',
        type: 'booking',
      );
      unawaited(NotificationService.instance.show(
        title: 'Booking Confirmed! 🎫',
        body: 'Payment simulated. Check your ticket in the Tickets tab.',
      ));
      if (mounted) context.go('/booking-success/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(_tripForBookingProvider(widget.tripId));
    final bookingState = ref.watch(bookingProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: Text(l10n.confirmBooking,
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.go('/passenger-info/${widget.tripId}'),
        ),
      ),
      body: tripAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) => lw.ErrorWidget(message: 'Failed to load trip'),
        data: (trip) => Column(
          children: [
            const BookingStepIndicator(currentStep: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip summary
                    _TripSummaryCard(trip: trip),
                    const SizedBox(height: 16),
                    // Passenger summary (read-only)
                    if (_passengerInfo != null) ...[
                      _PassengerSummaryCard(info: _passengerInfo!),
                      const SizedBox(height: 16),
                    ],
                    // Payment method
                    Text(l10n.paymentMethod,
                        style: const TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 12),
                    ...[
                      ('tmoney', l10n.tmoney, Icons.phone_android_rounded),
                      ('flooz', l10n.flooz, Icons.smartphone_rounded),
                      ('bank_transfer', l10n.bankTransfer,
                          Icons.account_balance_rounded),
                    ].map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _paymentMethod = m.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _paymentMethod == m.$1
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paymentMethod == m.$1
                                    ? AppColors.primary
                                    : AppColors.secondary
                                        .withValues(alpha: 0.3),
                                width: _paymentMethod == m.$1 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(m.$3,
                                    color: _paymentMethod == m.$1
                                        ? AppColors.primary
                                        : AppColors.grey,
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(m.$2,
                                    style: TextStyle(
                                        color: _paymentMethod == m.$1
                                            ? AppColors.primary
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                if (_paymentMethod == m.$1)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (bookingState.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(bookingState.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label:
                        'Confirm & Pay  XOF ${trip.price.toStringAsFixed(0)}',
                    onPressed: () => _confirm(trip),
                    isLoading: bookingState.isBooking,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed:
                        bookingState.isBooking ? null : _simulatePayment,
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Simulate Payment (Test)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip summary card ─────────────────────────────────────────────────────────

class _TripSummaryCard extends StatelessWidget {
  final TripModel trip;
  const _TripSummaryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded,
              color: AppColors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${trip.route?.origin ?? '-'} → ${trip.route?.destination ?? '-'}',
              style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ),
          Text(
            'XOF ${trip.price.toStringAsFixed(0)}',
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// ── Passenger summary (read-only collapsed card) ──────────────────────────────

class _PassengerSummaryCard extends StatelessWidget {
  final PassengerInfo info;
  const _PassengerSummaryCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Passenger Details',
                  style: TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Name', value: info.fullName),
          if (info.phone.isNotEmpty)
            _InfoRow(label: 'Phone', value: info.phone),
          _InfoRow(
              label: 'Luggage',
              value: '${info.bagsCount} bag(s)'
                  '${info.hasExtraLargeLuggage ? '  +  Extra-large' : ''}'),
          if (info.needsWheelchair)
            _InfoRow(label: 'Accessibility', value: 'Wheelchair access'),
          if (info.needsSpecialAssistance)
            _InfoRow(label: 'Assistance', value: 'Boarding/alighting help'),
          if (info.dietaryNotes != null)
            _InfoRow(label: 'Dietary', value: info.dietaryNotes!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
