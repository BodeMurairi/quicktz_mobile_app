import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

const _announcements = [
  _Announcement(
    icon: Icons.local_offer_rounded,
    color: Color(0xFF27AE60),
    title: '20% off – Lomé to Kara',
    body: 'Book before June 1 and save big on the N1 corridor.',
    link: '/search',
    linkLabel: 'Book now',
  ),
  _Announcement(
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF2E5E99),
    title: 'New route: Lomé → Bassar',
    body: 'Volta Voyages now serves Bassar daily from 06:00.',
    link: '/search',
    linkLabel: 'View trips',
  ),
  _Announcement(
    icon: Icons.star_rounded,
    color: Color(0xFFF39C12),
    title: 'School-holiday schedule',
    body: 'Extra departures added June 20 – July 10.',
    link: '/trip-planner',
    linkLabel: 'Plan trip',
  ),
  _Announcement(
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFF8E44AD),
    title: 'Earn gift cards',
    body: 'Buy 4 tickets and get a free-ride voucher.',
    link: 'https://quicktz.com/rewards',
    linkLabel: 'Learn more',
  ),
];

class _Announcement {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  // Internal route (starts with '/') or external URL; null = not tappable.
  final String? link;
  final String linkLabel;
  const _Announcement({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.link,
    this.linkLabel = 'More info',
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _previewCount = 4;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final searchState = ref.watch(searchProvider);
    final l10n = ref.watch(l10nProvider);
    final firstName = authState.user?.fullName.split(' ').first ??
        (l10n.isFr ? 'Voyageur' : 'Traveler');

    final trips = searchState.upcoming;
    final visibleTrips = _showAll ? trips : trips.take(_previewCount).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        label: const Text('Ask Bot',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(searchProvider.notifier).loadHome(),
        child: CustomScrollView(
          slivers: [
            // ── App bar ─────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.darkPrimary,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.white),
                onPressed: () => appShellKey.currentState?.openDrawer(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Hello, $firstName 👋',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(l10n.whereAreYouGoing,
                          style: const TextStyle(
                              color: AppColors.secondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.white),
                  onPressed: () => context.go('/notifications'),
                ),
              ],
            ),

            // ── Search + Plan cards ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    _SearchCard(onTap: () => context.go('/search')),
                    const SizedBox(height: 12),
                    _PlanCard(onTap: () => context.go('/trip-planner')),
                  ],
                ),
              ),
            ),

            // ── Featured agencies ────────────────────────────────────────────
            if (searchState.agencies.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(l10n.featuredAgencies,
                      style: const TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: searchState.agencies.length,
                    itemBuilder: (_, i) {
                      final a = searchState.agencies[i];
                      return GestureDetector(
                        onTap: () => context.go('/agency/${a.id}'),
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.directions_bus_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(a.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.darkPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── Upcoming trips header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.upcomingTrips,
                        style: const TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                    if (trips.length > _previewCount)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAll = !_showAll),
                        child: Text(
                          _showAll
                              ? (l10n.isFr ? 'Voir moins' : 'Show less')
                              : l10n.viewAll,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Upcoming trips horizontal list ───────────────────────────────
            if (searchState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: lw.LoadingWidget(),
                ),
              )
            else if (trips.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No upcoming trips available',
                        style: TextStyle(color: AppColors.grey)),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 185,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: visibleTrips.length,
                    itemBuilder: (_, i) {
                      final trip = visibleTrips[i];
                      return _TripChip(
                        origin: trip.route?.origin ?? '',
                        destination: trip.route?.destination ?? '',
                        departureTime: trip.departureDatetime,
                        agencyName:
                            trip.route?.agency?.name ?? 'Agency',
                        agencyId: trip.route?.agency?.id,
                        price: trip.price,
                        hasWifi: trip.hasWifi,
                        hasMeal: trip.hasMeal,
                        onTap: () => context.go('/trip/${trip.id}'),
                      );
                    },
                  ),
                ),
              ),

            // ── Announcements ────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Announcements',
                    style: TextStyle(
                        color: AppColors.darkPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 126,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: _announcements.length,
                  itemBuilder: (_, i) =>
                      _AnnouncementCard(item: _announcements[i]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Search card ───────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search trips',
                      style: TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text('Origin → Destination · Date',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.secondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.darkPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route_rounded,
                  color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan a trip',
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text('Multi-leg · Choose agency · Schedule',
                      style: TextStyle(
                          color: AppColors.secondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.secondary, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Trip chip ─────────────────────────────────────────────────────────────────

class _TripChip extends ConsumerWidget {
  final String origin;
  final String destination;
  final DateTime departureTime;
  final String agencyName;
  final String? agencyId;
  final double price;
  final bool hasWifi;
  final bool hasMeal;
  final VoidCallback onTap;

  const _TripChip({
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.agencyName,
    required this.agencyId,
    required this.price,
    required this.hasWifi,
    required this.hasMeal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = agencyId != null
        ? ref.watch(agencyRatingSummaryProvider(agencyId!))
        : null;
    final summary = ratingAsync?.valueOrNull;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(origin,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppColors.white, size: 14),
                  ),
                  Expanded(
                    child: Text(destination,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.secondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                          DateFormat('HH:mm · EEE d MMM')
                              .format(departureTime),
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.directions_bus_rounded,
                          color: AppColors.secondary, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(agencyName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.darkPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (summary?.averageRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF39C12), size: 13),
                        const SizedBox(width: 3),
                        Text(summary!.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                                color: AppColors.darkPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 3),
                        Text('(${summary.reviewCount})',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 10)),
                      ],
                    )
                  else
                    const Text('New',
                        style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _AmenityBadge(
                        icon: Icons.wifi_rounded,
                        label: 'WiFi',
                        active: hasWifi,
                      ),
                      const SizedBox(width: 6),
                      _AmenityBadge(
                        icon: Icons.restaurant_rounded,
                        label: 'Meal',
                        active: hasMeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'XOF ${NumberFormat('#,###').format(price)}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
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

// ── Announcement card ─────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final _Announcement item;
  const _AnnouncementCard({required this.item});

  Future<void> _handleTap(BuildContext context) async {
    final link = item.link;
    if (link == null) return;
    if (link.startsWith('/')) {
      context.go(link);
    } else {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = item.link != null;
    return GestureDetector(
      onTap: hasLink ? () => _handleTap(context) : null,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: hasLink
              ? Border.all(color: item.color.withValues(alpha: 0.25), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            if (hasLink) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.linkLabel,
                    style: TextStyle(
                        color: item.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded,
                      color: item.color, size: 12),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Amenity badge ─────────────────────────────────────────────────────────────

class _AmenityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _AmenityBadge({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: active ? AppColors.primary : AppColors.grey),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.grey)),
        ],
      ),
    );
  }
}
