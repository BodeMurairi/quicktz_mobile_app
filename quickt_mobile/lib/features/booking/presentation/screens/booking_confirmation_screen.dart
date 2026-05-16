import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;
import '../providers/booking_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _paymentMethod = 'tmoney';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final booking = await ref.read(bookingProvider.notifier).book(
          tripId: widget.tripId,
          passengerName: _nameCtrl.text.trim(),
          passengerPhone:
              _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text.trim() : null,
          paymentMethod: _paymentMethod,
        );
    if (mounted && booking != null) {
      context.go('/tickets');
    }
  }

  Future<void> _simulatePayment() async {
    final booking = await ref
        .read(bookingProvider.notifier)
        .simulateBook(widget.tripId);
    if (mounted && booking != null) {
      context.go('/tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(_tripForBookingProvider(widget.tripId));
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text(AppStrings.confirmBooking,
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => context.go('/trip/${widget.tripId}'),
        ),
      ),
      body: tripAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) => lw.ErrorWidget(message: 'Failed to load trip'),
        data: (trip) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trip summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${trip.route?.origin ?? '-'} → ${trip.route?.destination ?? '-'}',
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
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
                      ),
                      const SizedBox(height: 24),
                      const Text(AppStrings.passengerDetails,
                          style: TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'Passenger Name',
                        hint: 'Full name as on ID',
                        prefixIcon: Icons.person_outline,
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone (optional)',
                        hint: '+228 90 00 00 00',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      const Text(AppStrings.paymentMethod,
                          style: TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 12),
                      ...[
                        ('tmoney', AppStrings.tmoney, Icons.phone_android_rounded),
                        ('flooz', AppStrings.flooz, Icons.smartphone_rounded),
                        ('bank_transfer', AppStrings.bankTransfer,
                            Icons.account_balance_rounded),
                      ].map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _paymentMethod = m.$1),
                            child: Container(
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
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Confirm & Pay  XOF ${trip.price.toStringAsFixed(0)}',
                    onPressed: _confirm,
                    isLoading: bookingState.isBooking,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: bookingState.isBooking ? null : _simulatePayment,
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
