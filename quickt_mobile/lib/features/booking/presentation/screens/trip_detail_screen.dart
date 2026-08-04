import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

// ── Providers ─────────────────────────────────────────────────────────────────

final _tripDetailProvider = FutureProvider.family<TripModel, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getTripDetail(id);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

double _mockRating(String id) {
  final code = id.codeUnits.fold(0, (a, b) => a + b);
  return 3.5 + (code % 15) / 10;
}

int _mockReviews(String id) {
  final code = id.codeUnits.fold(0, (a, b) => a + b);
  return 20 + (code % 180);
}

// Intermediate stops for well-known Togolese corridors (origin → destination).
// Only the stops between the two endpoints are listed.
const _intermediateStops = <String, List<String>>{
  'Lomé-Kara':         ['Tsévié', 'Notsé', 'Atakpamé', 'Sokodé'],
  'Lomé-Dapaong':      ['Tsévié', 'Notsé', 'Atakpamé', 'Sokodé', 'Kara'],
  'Lomé-Sokodé':       ['Tsévié', 'Notsé', 'Atakpamé'],
  'Lomé-Atakpamé':     ['Tsévié', 'Notsé'],
  'Lomé-Bassar':       ['Tsévié', 'Notsé', 'Atakpamé', 'Sokodé'],
  'Kara-Lomé':         ['Sokodé', 'Atakpamé', 'Notsé', 'Tsévié'],
  'Dapaong-Lomé':      ['Kara', 'Sokodé', 'Atakpamé', 'Notsé', 'Tsévié'],
  'Sokodé-Lomé':       ['Atakpamé', 'Notsé', 'Tsévié'],
  'Atakpamé-Lomé':     ['Notsé', 'Tsévié'],
  'Atakpamé-Kara':     ['Sokodé'],
  'Kara-Atakpamé':     ['Sokodé'],
  'Kara-Dapaong':      [],
  'Dapaong-Kara':      [],
  'Sokodé-Kara':       [],
  'Kara-Sokodé':       [],
};

List<String> _stops(String? origin, String? destination) {
  if (origin == null || destination == null) return [];
  return _intermediateStops['$origin-$destination'] ?? [];
}

// ── Screen ────────────────────────────────────────────────────────────────────

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/search-results'),
        ),
      ),
      body: tripAsync.when(
        loading: () =>
            const lw.LoadingWidget(message: 'Loading trip details...'),
        error: (e, _) => lw.ErrorWidget(
          message: 'Failed to load trip',
          onRetry: () => ref.invalidate(_tripDetailProvider(tripId)),
        ),
        data: (trip) => _TripDetailBody(trip: trip),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _TripDetailBody extends ConsumerWidget {
  final TripModel trip;
  const _TripDetailBody({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final priceFmt = NumberFormat('#,###');
    final timeFmt  = DateFormat('HH:mm');
    final dateFmt  = DateFormat('EEE, d MMM yyyy');

    final dep = trip.departureDatetime;
    final arr = trip.arrivalDatetime;
    final dur = trip.route?.durationMinutes;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero card ────────────────────────────────────────────
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
                                Text(timeFmt.format(dep),
                                    style: TextStyle(
                                        color: AppColors.white
                                            .withValues(alpha: 0.75),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.white, size: 24),
                              if (dur != null)
                                Text(
                                  _fmtDuration(dur),
                                  style: TextStyle(
                                      color: AppColors.white
                                          .withValues(alpha: 0.7),
                                      fontSize: 11),
                                ),
                            ],
                          ),
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
                                if (arr != null)
                                  Text(timeFmt.format(arr),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.75),
                                          fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                          color: AppColors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _infoChip(Icons.calendar_today_rounded,
                              dateFmt.format(dep)),
                          _infoChip(Icons.event_seat_rounded,
                              '${trip.availableSeats} seats left'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Route info ───────────────────────────────────────────
                _RouteInfoCard(
                  origin: trip.route?.origin,
                  destination: trip.route?.destination,
                  departure: dep,
                  arrival: arr,
                  durationMinutes: dur,
                  distanceKm: trip.route?.distanceKm,
                  routeStops: trip.route?.stops ?? const [],
                ),

                const SizedBox(height: 12),

                // ── Amenities ────────────────────────────────────────────
                _AmenitiesCard(
                  hasWifi: trip.hasWifi,
                  hasMeal: trip.hasMeal,
                  hasAc: trip.hasAc,
                  hasUsb: trip.hasUsb,
                ),

                if (trip.requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // ── Travel requirements ─────────────────────────────────
                  _RequirementsCard(requirements: trip.requirements),
                ],

                const SizedBox(height: 12),

                // ── Ratings ──────────────────────────────────────────────
                _RatingCard(tripId: trip.id),

                const SizedBox(height: 12),

                // ── Agency ───────────────────────────────────────────────
                if (trip.route?.agency != null)
                  _AgencyCard(agency: trip.route!.agency!),

                const SizedBox(height: 12),

                // ── Trip info ────────────────────────────────────────────
                _sectionCard('Trip Info', [
                  if (trip.busNumber != null)
                    _row('Bus number', trip.busNumber!),
                  _row('Seats', '${trip.availableSeats}/${trip.totalSeats} available'),
                  _row('Status', trip.status.toUpperCase()),
                ]),
              ],
            ),
          ),
        ),

        // ── Book bar ─────────────────────────────────────────────────────
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
                      style:
                          TextStyle(color: AppColors.grey, fontSize: 12)),
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
                  label: l10n.bookNow,
                  onPressed: trip.availableSeats > 0
                      ? () => context.go('/passenger-info/${trip.id}')
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

  String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Widget _infoChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: AppColors.white.withValues(alpha: 0.8), size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 12)),
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

// ── Route info card ───────────────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final String? origin;
  final String? destination;
  final DateTime departure;
  final DateTime? arrival;
  final int? durationMinutes;
  final double? distanceKm;
  final List<RouteStop> routeStops;

  const _RouteInfoCard({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.durationMinutes,
    required this.distanceKm,
    this.routeStops = const [],
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    // Prefer the agency's own stops for this route; fall back to the
    // built-in corridor list only when the agency hasn't defined any.
    final stops = routeStops.isNotEmpty
        ? routeStops.map((s) => s.name).toList()
        : _stops(origin, destination);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Route',
                  style: TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              if (durationMinutes != null || distanceKm != null)
                Row(
                  children: [
                    if (distanceKm != null) ...[
                      const Icon(Icons.straighten_rounded,
                          color: AppColors.secondary, size: 13),
                      const SizedBox(width: 3),
                      Text('${distanceKm!.toStringAsFixed(0)} km',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                      const SizedBox(width: 10),
                    ],
                    if (durationMinutes != null) ...[
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.secondary, size: 13),
                      const SizedBox(width: 3),
                      Text(_fmtDur(durationMinutes!),
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Origin stop
          _StopRow(
            name: origin ?? '-',
            time: timeFmt.format(departure),
            type: _StopType.origin,
          ),

          // Intermediate stops
          ...stops.map((s) => _StopRow(
                name: s,
                time: null,
                type: _StopType.intermediate,
              )),

          // Destination stop
          _StopRow(
            name: destination ?? '-',
            time: arrival != null ? timeFmt.format(arrival!) : null,
            type: _StopType.destination,
          ),
        ],
      ),
    );
  }

  String _fmtDur(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

enum _StopType { origin, intermediate, destination }

class _StopRow extends StatelessWidget {
  final String name;
  final String? time;
  final _StopType type;

  const _StopRow({
    required this.name,
    required this.time,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isEndpoint = type != _StopType.intermediate;
    final dotColor =
        isEndpoint ? AppColors.primary : AppColors.secondary;
    final dotSize = isEndpoint ? 12.0 : 8.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isEndpoint
                      ? Border.all(color: AppColors.white, width: 2)
                      : null,
                  boxShadow: isEndpoint
                      ? [BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 4)]
                      : null,
                ),
              ),
              if (type != _StopType.destination)
                Container(
                  width: 2,
                  height: type == _StopType.intermediate ? 24 : 28,
                  color: AppColors.secondary.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Stop info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isEndpoint
                        ? AppColors.darkPrimary
                        : AppColors.grey,
                    fontWeight: isEndpoint
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: isEndpoint ? 14 : 13,
                  ),
                ),
                if (time != null)
                  Text(time!,
                      style: TextStyle(
                          color: isEndpoint
                              ? AppColors.primary
                              : AppColors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Amenities card ────────────────────────────────────────────────────────────

class _AmenitiesCard extends StatelessWidget {
  final bool hasWifi;
  final bool hasMeal;
  final bool hasAc;
  final bool hasUsb;

  const _AmenitiesCard({
    required this.hasWifi,
    required this.hasMeal,
    required this.hasAc,
    required this.hasUsb,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amenities',
              style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            children: [
              _AmenityTile(Icons.wifi_rounded, 'WiFi', hasWifi),
              const SizedBox(width: 10),
              _AmenityTile(Icons.restaurant_rounded, 'Meal', hasMeal),
              const SizedBox(width: 10),
              _AmenityTile(Icons.ac_unit_rounded, 'A/C', hasAc),
              const SizedBox(width: 10),
              _AmenityTile(Icons.usb_rounded, 'USB', hasUsb),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;

  const _AmenityTile(this.icon, this.label, this.available);

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.primary : AppColors.grey;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: available
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.grey.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            Text(available ? 'Yes' : 'No',
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Travel requirements card ─────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  final List<TripRequirement> requirements;
  const _RequirementsCard({required this.requirements});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded,
                  color: AppColors.darkPrimary, size: 17),
              const SizedBox(width: 6),
              const Text('Travel Requirements',
                  style: TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...requirements.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle,
                          color: AppColors.secondary, size: 6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: const TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(r.value,
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Rating card ───────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final String tripId;
  const _RatingCard({required this.tripId});

  @override
  Widget build(BuildContext context) {
    final rating = _mockRating(tripId);
    final reviews = _mockReviews(tripId);
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ratings & Reviews',
              style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 36)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      if (i < full) {
                        return const Icon(Icons.star_rounded,
                            color: Color(0xFFF39C12), size: 20);
                      } else if (i == full && hasHalf) {
                        return const Icon(Icons.star_half_rounded,
                            color: Color(0xFFF39C12), size: 20);
                      }
                      return const Icon(Icons.star_outline_rounded,
                          color: Color(0xFFF39C12), size: 20);
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text('$reviews reviews',
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Agency card ───────────────────────────────────────────────────────────────

class _AgencyCard extends StatelessWidget {
  final AgencyModel agency;
  const _AgencyCard({required this.agency});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/agency/${agency.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_bus_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(agency.name,
                          style: const TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      if (agency.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 15),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Tap to view agency profile',
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 12)),
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
