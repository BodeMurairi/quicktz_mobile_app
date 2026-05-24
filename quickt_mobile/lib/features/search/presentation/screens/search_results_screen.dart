import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../providers/search_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final results = state.results;
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: Text(
          l10n.isFr
              ? '${results.length} ${results.length != 1 ? 'voyages trouvés' : 'voyage trouvé'}'
              : '${results.length} trip${results.length != 1 ? 's' : ''} found',
          style: const TextStyle(
              color: AppColors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => context.go('/search'),
        ),
      ),
      body: state.isSearching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          color: AppColors.secondary, size: 64),
                      const SizedBox(height: 16),
                      Text(l10n.noTripsFound,
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Modify Search',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final trip = results[i];
                    return TripCard(
                      origin: trip.route?.origin ?? '',
                      destination: trip.route?.destination ?? '',
                      departureTime: trip.departureDatetime,
                      agencyName: trip.route?.agency?.name ?? 'Agency',
                      price: trip.price,
                      availableSeats: trip.availableSeats,
                      onTap: () => context.go('/trip/${trip.id}'),
                    );
                  },
                ),
    );
  }
}
