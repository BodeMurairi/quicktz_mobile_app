import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

final _tripDetailProvider = FutureProvider.family<TripModel, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getTripDetail(id);
});

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(_tripDetailProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Trip Details',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
          onPressed: () => context.go('/search-results'),
        ),
      ),
      body: tripAsync.when(
        loading: () => const lw.LoadingWidget(message: 'Loading trip details...'),
        error: (e, _) => lw.ErrorWidget(
          message: 'Failed to load trip',
          onRetry: () => ref.invalidate(_tripDetailProvider(tripId)),
        ),
        data: (trip) => _TripDetailBody(trip: trip),
      ),
    );
  }
}

class _TripDetailBody extends StatelessWidget {
  final TripModel trip;
  const _TripDetailBody({required this.trip});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM yyyy · HH:mm');
    final priceFmt = NumberFormat('#,###');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FROM',
                                    style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(trip.route?.origin ?? '-',
                                    style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.white, size: 28),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('TO',
                                    style: TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(trip.route?.destination ?? '-',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoChip(Icons.schedule_rounded,
                              fmt.format(trip.departureDatetime)),
                          _infoChip(Icons.event_seat_rounded,
                              '${trip.availableSeats} seats left'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionCard('Agency', [
                  _row('Name', trip.route?.agency?.name ?? '-'),
                  if (trip.route?.agency?.isVerified == true)
                    _row('Status', '✓ Verified Agency'),
                ]),
                const SizedBox(height: 12),
                _sectionCard('Trip Info', [
                  if (trip.busNumber != null) _row('Bus', trip.busNumber!),
                  if (trip.route?.durationMinutes != null)
                    _row('Duration', '${trip.route!.durationMinutes} min'),
                  _row('Available Seats', '${trip.availableSeats}/${trip.totalSeats}'),
                  _row('Status', trip.status.toUpperCase()),
                ]),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Price per seat',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  Text(
                    'XOF ${priceFmt.format(trip.price)}',
                    style: const TextStyle(
                        color: AppColors.darkPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: AppStrings.bookNow,
                  onPressed: trip.availableSeats > 0
                      ? () => context.go('/booking/${trip.id}')
                      : null,
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9), fontSize: 12)),
        ],
      );

  Widget _sectionCard(String title, List<Widget> rows) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
}
