import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _Leg {
  String origin;
  String destination;
  DateTime date;

  _Leg({required this.origin, required this.destination, required this.date});

  _Leg copyWith({String? origin, String? destination, DateTime? date}) =>
      _Leg(
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
        date: date ?? this.date,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final List<_Leg> _legs = [
    _Leg(
      origin: '',
      destination: '',
      date: DateTime.now().add(const Duration(days: 1)),
    ),
  ];
  String? _preferredAgencyId;
  int _passengers = 1;

  List<String> get _knownCities => const [
        'Lomé', 'Kara', 'Atakpamé', 'Sokodé', 'Dapaong',
        'Tsévié', 'Notsé', 'Bassar',
      ];

  void _addLeg() {
    if (_legs.length >= 4) return;
    setState(() {
      _legs.add(_Leg(
        origin: _legs.last.destination,
        destination: '',
        date: _legs.last.date.add(const Duration(days: 1)),
      ));
    });
  }

  void _removeLeg(int i) {
    if (_legs.length <= 1) return;
    setState(() => _legs.removeAt(i));
  }

  Future<void> _pickDate(int legIndex) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _legs[legIndex].date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _legs[legIndex] = _legs[legIndex].copyWith(date: picked));
    }
  }

  bool get _isValid =>
      _legs.every((l) => l.origin.isNotEmpty && l.destination.isNotEmpty);

  void _submit() {
    if (!_isValid) return;
    // Navigate to search results for the first leg; future legs shown in summary
    final first = _legs.first;
    context.go(
      '/search-results',
      extra: {
        'origin': first.origin,
        'destination': first.destination,
        'date': DateFormat('yyyy-MM-dd').format(first.date),
        'passengers': _passengers,
        'agencyId': _preferredAgencyId,
        'legs': _legs
            .map((l) => {
                  'origin': l.origin,
                  'destination': l.destination,
                  'date': DateFormat('yyyy-MM-dd').format(l.date),
                })
            .toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final agencies = searchState.agencies;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Plan a Trip',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Legs ────────────────────────────────────────────────
                  const _SectionLabel('Trip Legs'),
                  const SizedBox(height: 10),
                  ...List.generate(_legs.length, (i) => _LegCard(
                        index: i,
                        leg: _legs[i],
                        cities: _knownCities,
                        canRemove: _legs.length > 1,
                        onOriginChanged: (v) =>
                            setState(() => _legs[i] = _legs[i].copyWith(origin: v)),
                        onDestinationChanged: (v) =>
                            setState(() => _legs[i] = _legs[i].copyWith(destination: v)),
                        onDateTap: () => _pickDate(i),
                        onRemove: () => _removeLeg(i),
                      )),
                  if (_legs.length < 4)
                    TextButton.icon(
                      onPressed: _addLeg,
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 18),
                      label: const Text('Add leg',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 20),

                  // ── Passengers ──────────────────────────────────────────
                  const _SectionLabel('Passengers'),
                  const SizedBox(height: 10),
                  _PassengerSelector(
                    value: _passengers,
                    onChanged: (v) => setState(() => _passengers = v),
                  ),
                  const SizedBox(height: 20),

                  // ── Preferred agency ────────────────────────────────────
                  const _SectionLabel('Preferred Agency (optional)'),
                  const SizedBox(height: 10),
                  _AgencySelector(
                    agencies: agencies,
                    selectedId: _preferredAgencyId,
                    onSelected: (id) =>
                        setState(() => _preferredAgencyId = id),
                  ),
                  const SizedBox(height: 20),

                  // ── Summary ─────────────────────────────────────────────
                  if (_legs.length > 1) ...[
                    const _SectionLabel('Trip Summary'),
                    const SizedBox(height: 10),
                    _TripSummary(legs: _legs, passengers: _passengers),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          // ── Bottom action ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: AppButton(
              label: 'Search trips',
              onPressed: _isValid ? _submit : null,
              icon: Icons.search_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leg card ──────────────────────────────────────────────────────────────────

class _LegCard extends StatelessWidget {
  final int index;
  final _Leg leg;
  final List<String> cities;
  final bool canRemove;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onDateTap;
  final VoidCallback onRemove;

  const _LegCard({
    required this.index,
    required this.leg,
    required this.cities,
    required this.canRemove,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onDateTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Text('Leg ${index + 1}',
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.remove_circle_outline,
                      color: AppColors.grey, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CityDropdown(
                  label: 'From',
                  value: leg.origin.isEmpty ? null : leg.origin,
                  cities: cities,
                  onChanged: onOriginChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.secondary, size: 18),
              ),
              Expanded(
                child: _CityDropdown(
                  label: 'To',
                  value: leg.destination.isEmpty ? null : leg.destination,
                  cities: cities,
                  onChanged: onDestinationChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(leg.date),
                    style: const TextStyle(
                        color: AppColors.darkPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── City dropdown ─────────────────────────────────────────────────────────────

class _CityDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> cities;
  final ValueChanged<String> onChanged;

  const _CityDropdown({
    required this.label,
    required this.value,
    required this.cities,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(label,
          style: const TextStyle(color: AppColors.grey, fontSize: 13)),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppColors.grey.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppColors.grey.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      isDense: true,
      isExpanded: true,
      style:
          const TextStyle(color: AppColors.darkPrimary, fontSize: 13),
      items: cities
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ── Passenger selector ────────────────────────────────────────────────────────

class _PassengerSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PassengerSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.secondary),
          const SizedBox(width: 10),
          const Text('Passengers',
              style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          _CountButton(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$value',
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          _CountButton(
            icon: Icons.add,
            onTap: value < 9 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? AppColors.primary : AppColors.grey),
      ),
    );
  }
}

// ── Agency selector ───────────────────────────────────────────────────────────

class _AgencySelector extends StatelessWidget {
  final List<AgencyModel> agencies;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _AgencySelector({
    required this.agencies,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (agencies.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AgencyChip(
            label: 'Any',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          ...agencies.map((a) => _AgencyChip(
                label: a.name,
                selected: selectedId == a.id,
                onTap: () => onSelected(a.id),
              )),
        ],
      ),
    );
  }
}

class _AgencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AgencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? AppColors.white : AppColors.darkPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Trip summary ──────────────────────────────────────────────────────────────

class _TripSummary extends StatelessWidget {
  final List<_Leg> legs;
  final int passengers;

  const _TripSummary({required this.legs, required this.passengers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: legs.asMap().entries.map((e) {
          final i = e.key;
          final leg = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < legs.length - 1)
                      Container(
                          width: 2, height: 24, color: AppColors.secondary),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${leg.origin} → ${leg.destination}',
                        style: const TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      Text(
                        DateFormat('EEE, d MMM yyyy').format(leg.date),
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.darkPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15));
}
