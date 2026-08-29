import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/messages/presentation/providers/conversation_provider.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

Future<void> _messageAgency(
    BuildContext context, WidgetRef ref, String agencyId) async {
  try {
    final conversation = await ref
        .read(conversationRepositoryProvider)
        .startConversation(agencyId);
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.push('/messages/${conversation.id}');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not start a conversation. Please try again.')),
      );
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _agencyDetailProvider =
    FutureProvider.family<AgencyModel, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getAgencyDetail(id);
});

final _agencyRoutesProvider =
    FutureProvider.family<List<RouteModel>, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getAgencyRoutes(id);
});

// Star histogram (5★ down to 1★) derived from the agency's real reviews.
List<int> _starBreakdown(List<AgencyReview> reviews) {
  final counts = List.filled(5, 0);
  for (final r in reviews) {
    final star = r.rating.clamp(1, 5);
    counts[5 - star]++;
  }
  return counts;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AgencyScreen extends ConsumerWidget {
  final String agencyId;
  const AgencyScreen({super.key, required this.agencyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyAsync = ref.watch(_agencyDetailProvider(agencyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: agencyAsync.when(
        loading: () => const lw.LoadingWidget(message: 'Loading agency...'),
        error: (e, _) => lw.ErrorWidget(
          message: 'Failed to load agency',
          onRetry: () => ref.invalidate(_agencyDetailProvider(agencyId)),
        ),
        data: (agency) => _AgencyBody(agency: agency),
      ),
    );
  }
}

// ── Tabbed body ───────────────────────────────────────────────────────────────

class _AgencyBody extends ConsumerWidget {
  final AgencyModel agency;
  const _AgencyBody({required this.agency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(_agencyRoutesProvider(agency.id));
    final ratingSummary =
        ref.watch(agencyRatingSummaryProvider(agency.id)).valueOrNull;
    final reviews =
        ref.watch(agencyReviewsProvider(agency.id)).valueOrNull ?? const [];
    final rating = ratingSummary?.averageRating ?? 0.0;
    final reviewCount = ratingSummary?.reviewCount ?? 0;
    final breakdown = _starBreakdown(reviews);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: AppColors.darkPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.mail_outline_rounded,
                    color: AppColors.white),
                tooltip: 'Message this agency',
                onPressed: () => _messageAgency(context, ref, agency.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 44),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: AppColors.white, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(agency.name,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        if (agency.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.lightBlueAccent, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF39C12), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)}  ($reviewCount reviews)',
                          style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.55),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline_rounded, size: 16),
                  text: 'About',
                ),
                Tab(
                  icon: Icon(Icons.star_outline_rounded, size: 16),
                  text: 'Reviews',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _AboutTab(
              agency: agency,
              routesAsync: routesAsync,
              rating: rating,
              reviewCount: reviewCount,
            ),
            _ReviewsTab(
              rating: rating,
              reviewCount: reviewCount,
              breakdown: breakdown,
              reviews: reviews,
            ),
          ],
        ),
      ),
    );
  }
}

// ── About tab ─────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final AgencyModel agency;
  final AsyncValue<List<RouteModel>> routesAsync;
  final double rating;
  final int reviewCount;

  const _AboutTab({
    required this.agency,
    required this.routesAsync,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        if (agency.isVerified) ...[
          _VerifiedBadge(),
          const SizedBox(height: 4),
        ],

        _StatsRow(
          routeCount: routesAsync.valueOrNull?.length,
          rating: rating,
          reviewCount: reviewCount,
        ),
        const SizedBox(height: 28),

        // About / Description
        if (agency.description != null) ...[
          _SectionTitle('About'),
          const SizedBox(height: 10),
          _Card(
            child: Text(agency.description!,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.7)),
          ),
          const SizedBox(height: 28),
        ],

        // Services
        _SectionTitle('Services'),
        const SizedBox(height: 10),
        const _ServicesGrid(),
        const SizedBox(height: 28),

        // Available routes
        _SectionTitle('Available Routes'),
        const SizedBox(height: 10),
        routesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => const Text('Could not load routes',
              style: TextStyle(color: AppColors.grey)),
          data: (routes) => routes.isEmpty
              ? const Text('No routes available',
                  style: TextStyle(color: AppColors.grey))
              : Column(
                  children: routes
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RouteRow(route: r),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 28),

        // Contact
        _SectionTitle('Contact'),
        const SizedBox(height: 10),
        _Card(
          child: Column(
            children: [
              if (agency.phone != null)
                _ContactRow(
                    icon: Icons.phone_outlined, label: agency.phone!),
              if (agency.email != null)
                _ContactRow(
                    icon: Icons.email_outlined, label: agency.email!),
              if (agency.address != null)
                _ContactRow(
                    icon: Icons.location_on_outlined,
                    label: agency.address!,
                    isLast: true),
              if (agency.phone == null &&
                  agency.email == null &&
                  agency.address == null)
                const Text('No contact info available',
                    style: TextStyle(
                        color: AppColors.grey, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reviews tab ───────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<int> breakdown;
  final List<AgencyReview> reviews;

  const _ReviewsTab({
    required this.rating,
    required this.reviewCount,
    required this.breakdown,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _RatingBreakdownCard(
          rating: rating,
          reviewCount: reviewCount,
          breakdown: breakdown,
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Recent Reviews'),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          const Text('No reviews yet — be the first to rate a trip with this agency.',
              style: TextStyle(color: AppColors.grey, fontSize: 13))
        else
          ...reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: r),
              )),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.darkPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16));
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded,
                color: AppColors.success, size: 16),
            SizedBox(width: 6),
            Text('Verified Agency',
                style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  final int? routeCount;
  final double rating;
  final int reviewCount;
  const _StatsRow(
      {required this.routeCount,
      required this.rating,
      required this.reviewCount});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _StatTile(
              icon: Icons.route_rounded,
              label: 'Routes',
              value: routeCount != null ? '$routeCount' : '—'),
          const SizedBox(width: 12),
          _StatTile(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: rating.toStringAsFixed(1)),
          const SizedBox(width: 12),
          _StatTile(
              icon: Icons.rate_review_rounded,
              label: 'Reviews',
              value: '$reviewCount'),
        ],
      );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _RatingBreakdownCard extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<int> breakdown;
  const _RatingBreakdownCard(
      {required this.rating,
      required this.reviewCount,
      required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 44)),
              Row(
                children: List.generate(5, (i) {
                  if (i < full) {
                    return const Icon(Icons.star_rounded,
                        color: Color(0xFFF39C12), size: 16);
                  } else if (i == full && hasHalf) {
                    return const Icon(Icons.star_half_rounded,
                        color: Color(0xFFF39C12), size: 16);
                  }
                  return const Icon(Icons.star_outline_rounded,
                      color: Color(0xFFF39C12), size: 16);
                }),
              ),
              const SizedBox(height: 4),
              Text('$reviewCount reviews',
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = breakdown[i];
                final fraction =
                    reviewCount > 0 ? count / reviewCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF39C12), size: 11),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.grey.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF39C12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 28,
                        child: Text('$count',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final AgencyReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0]
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName,
                        style: const TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text(
                      '${DateFormat('d MMM yyyy').format(review.createdAt)} · ${review.tripRoute}',
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF39C12),
                          size: 14,
                        )),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment!,
                style: const TextStyle(
                    color: AppColors.grey, fontSize: 13, height: 1.5)),
          ],
          if (review.reply != null && review.reply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Response from the agency',
                      style: TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(review.reply!,
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final RouteModel route;
  const _RouteRow({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.origin}  →  ${route.destination}',
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (route.distanceKm != null) ...[
                      const Icon(Icons.straighten_rounded,
                          color: AppColors.grey, size: 12),
                      const SizedBox(width: 3),
                      Text(
                          '${route.distanceKm!.toStringAsFixed(0)} km',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                      const SizedBox(width: 10),
                    ],
                    if (route.durationMinutes != null) ...[
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.grey, size: 12),
                      const SizedBox(width: 3),
                      Text(_fmtDur(route.durationMinutes!),
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.secondary, size: 14),
        ],
      ),
    );
  }

  String _fmtDur(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;
  const _ContactRow(
      {required this.icon, required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.darkPrimary, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _ServicesGrid extends StatelessWidget {
  static const _items = [
    (Icons.confirmation_number_outlined, 'Ticket booking'),
    (Icons.luggage_rounded, 'Luggage storage'),
    (Icons.swap_horiz_rounded, 'Easy rebooking'),
    (Icons.headset_mic_rounded, '24/7 support'),
  ];

  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: _items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(item.$1, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.$2,
                          style: const TextStyle(
                              color: AppColors.darkPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
