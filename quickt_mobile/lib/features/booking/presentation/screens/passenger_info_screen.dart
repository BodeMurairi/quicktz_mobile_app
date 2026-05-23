import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../features/search/data/models/trip_model.dart';
import '../../../../features/search/presentation/providers/search_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

final _tripForPassengerProvider =
    FutureProvider.family<TripModel, String>((ref, id) {
  return ref.read(tripRepositoryProvider).getTripDetail(id);
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class PassengerInfoScreen extends ConsumerStatefulWidget {
  final String tripId;
  const PassengerInfoScreen({super.key, required this.tripId});

  @override
  ConsumerState<PassengerInfoScreen> createState() =>
      _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends ConsumerState<PassengerInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Identity
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Luggage
  int _bagsCount = 1;
  bool _hasExtraLarge = false;

  // Health & Accessibility
  bool _needsWheelchair = false;
  bool _needsSpecialAssistance = false;
  final _dietaryCtrl = TextEditingController();

  // Expansion states
  bool _identityExpanded = true;
  bool _luggageExpanded = false;
  bool _healthExpanded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _dietaryCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _identityExpanded = true);
      return;
    }
    final info = PassengerInfo(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bagsCount: _bagsCount,
      hasExtraLargeLuggage: _hasExtraLarge,
      needsWheelchair: _needsWheelchair,
      needsSpecialAssistance: _needsSpecialAssistance,
      dietaryNotes: _dietaryCtrl.text.trim().isEmpty
          ? null
          : _dietaryCtrl.text.trim(),
    );
    context.go('/booking/${widget.tripId}', extra: info);
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(_tripForPassengerProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Passenger Info',
            style:
                TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trip/${widget.tripId}'),
        ),
      ),
      body: tripAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) => lw.ErrorWidget(message: 'Failed to load trip'),
        data: (trip) => Form(
          key: _formKey,
          child: Column(
            children: [
              const BookingStepIndicator(currentStep: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _TripSummaryBanner(trip: trip),
                      const SizedBox(height: 20),
                      _CollapsibleSection(
                        title: 'Identity',
                        icon: Icons.badge_outlined,
                        subtitle: 'Name & ID document',
                        isExpanded: _identityExpanded,
                        onToggle: (v) =>
                            setState(() => _identityExpanded = v),
                        child: _IdentitySection(
                          nameCtrl: _nameCtrl,
                          phoneCtrl: _phoneCtrl,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CollapsibleSection(
                        title: 'Luggage',
                        icon: Icons.luggage_outlined,
                        subtitle: 'Bags & special items',
                        isExpanded: _luggageExpanded,
                        onToggle: (v) =>
                            setState(() => _luggageExpanded = v),
                        child: _LuggageSection(
                          bagsCount: _bagsCount,
                          hasExtraLarge: _hasExtraLarge,
                          onBagsChanged: (v) =>
                              setState(() => _bagsCount = v),
                          onExtraLargeChanged: (v) =>
                              setState(() => _hasExtraLarge = v),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CollapsibleSection(
                        title: 'Health & Accessibility',
                        icon: Icons.accessible_outlined,
                        subtitle: 'Optional — wheelchair, assistance, diet',
                        isExpanded: _healthExpanded,
                        onToggle: (v) =>
                            setState(() => _healthExpanded = v),
                        child: _HealthSection(
                          needsWheelchair: _needsWheelchair,
                          needsSpecialAssistance: _needsSpecialAssistance,
                          dietaryCtrl: _dietaryCtrl,
                          onWheelchairChanged: (v) =>
                              setState(() => _needsWheelchair = v),
                          onAssistanceChanged: (v) =>
                              setState(() => _needsSpecialAssistance = v),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                child: AppButton(
                  label: 'Continue to Payment',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────────────────

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  const BookingStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: [
          _Step(
              number: 1,
              label: 'Passenger',
              isActive: currentStep == 1,
              isDone: currentStep > 1),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep > 1
                  ? AppColors.primary
                  : AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          _Step(
              number: 2,
              label: 'Payment',
              isActive: currentStep == 2,
              isDone: false),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  const _Step(
      {required this.number,
      required this.label,
      required this.isActive,
      required this.isDone});

  @override
  Widget build(BuildContext context) {
    final active = isActive || isDone;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
                color: active ? AppColors.primary : AppColors.grey, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: AppColors.white, size: 14)
                : Text('$number',
                    style: TextStyle(
                        color: active ? AppColors.white : AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: active ? AppColors.primary : AppColors.grey,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.normal)),
      ],
    );
  }
}

// ── Trip summary banner ────────────────────────────────────────────────────────

class _TripSummaryBanner extends StatelessWidget {
  final TripModel trip;
  const _TripSummaryBanner({required this.trip});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('EEE d MMM');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.route?.origin ?? '-'} → ${trip.route?.destination ?? '-'}',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  '${dateFmt.format(trip.departureDatetime)}  ·  ${timeFmt.format(trip.departureDatetime)}',
                  style: const TextStyle(
                      color: AppColors.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'XOF ${NumberFormat('#,###').format(trip.price.toInt())}',
            style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Collapsible section ────────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  color: AppColors.grey, fontSize: 11)),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onToggle,
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.grey,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }
}

// ── Identity section ───────────────────────────────────────────────────────────

class _IdentitySection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  const _IdentitySection({
    required this.nameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: nameCtrl,
          label: 'Full Name *',
          hint: 'As it appears on your ticket',
          prefixIcon: Icons.person_outline,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required';
            if (v.trim().split(' ').length < 2) {
              return 'Please enter your first and last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: phoneCtrl,
          label: 'Phone Number (optional)',
          hint: '+228 90 00 00 00',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

// ── Luggage section ────────────────────────────────────────────────────────────

class _LuggageSection extends StatelessWidget {
  final int bagsCount;
  final bool hasExtraLarge;
  final ValueChanged<int> onBagsChanged;
  final ValueChanged<bool> onExtraLargeChanged;

  const _LuggageSection({
    required this.bagsCount,
    required this.hasExtraLarge,
    required this.onBagsChanged,
    required this.onExtraLargeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of bags',
                      style: TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Standard size (up to 20 kg each)',
                      style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.8),
                          fontSize: 11)),
                ],
              ),
            ),
            _Counter(
                value: bagsCount,
                min: 0,
                max: 5,
                onChanged: onBagsChanged),
          ],
        ),
        const SizedBox(height: 16),
        _ToggleRow(
          label: 'Extra-large luggage',
          subtitle: 'Oversized or over 20 kg',
          icon: Icons.cases_outlined,
          value: hasExtraLarge,
          onChanged: onExtraLargeChanged,
        ),
      ],
    );
  }
}

// ── Health & Accessibility section ─────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  final bool needsWheelchair;
  final bool needsSpecialAssistance;
  final TextEditingController dietaryCtrl;
  final ValueChanged<bool> onWheelchairChanged;
  final ValueChanged<bool> onAssistanceChanged;

  const _HealthSection({
    required this.needsWheelchair,
    required this.needsSpecialAssistance,
    required this.dietaryCtrl,
    required this.onWheelchairChanged,
    required this.onAssistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleRow(
          label: 'Wheelchair access',
          subtitle: 'I need wheelchair-accessible seating',
          icon: Icons.accessible_rounded,
          value: needsWheelchair,
          onChanged: onWheelchairChanged,
        ),
        const SizedBox(height: 12),
        _ToggleRow(
          label: 'Special assistance',
          subtitle: 'I need help boarding or alighting',
          icon: Icons.support_agent_outlined,
          value: needsSpecialAssistance,
          onChanged: onAssistanceChanged,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: dietaryCtrl,
          label: 'Dietary notes (optional)',
          hint: 'e.g. Vegetarian, halal, no nuts…',
          prefixIcon: Icons.restaurant_outlined,
        ),
      ],
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _Counter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Counter(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleBtn(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPrimary)),
        ),
        _CircleBtn(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(
              color: enabled
                  ? AppColors.primary
                  : AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? AppColors.primary : AppColors.grey),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.subtitle,
      required this.icon,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: value ? AppColors.primary : AppColors.grey, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11)),
            ],
          ),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary),
      ],
    );
  }
}
