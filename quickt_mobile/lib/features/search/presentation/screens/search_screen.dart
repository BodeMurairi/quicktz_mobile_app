import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  int _passengers = 1;

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      setState(() {
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(searchProvider.notifier).search(
          origin: _originCtrl.text.trim(),
          destination: _destinationCtrl.text.trim(),
          departureDate: _dateCtrl.text.trim(),
          passengers: _passengers,
        );
    if (mounted) context.go('/search-results');
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = ref.watch(searchProvider).isSearching;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text(AppStrings.searchTrips,
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              AppTextField(
                controller: _originCtrl,
                label: AppStrings.from,
                hint: 'e.g. Lomé',
                prefixIcon: Icons.trip_origin_rounded,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    final tmp = _originCtrl.text;
                    _originCtrl.text = _destinationCtrl.text;
                    _destinationCtrl.text = tmp;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert_rounded,
                        color: AppColors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _destinationCtrl,
                label: AppStrings.to,
                hint: 'e.g. Kara',
                prefixIcon: Icons.location_on_outlined,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _dateCtrl,
                label: AppStrings.date,
                hint: 'Select date',
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.passengers,
                      style: TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded),
                          color: AppColors.primary,
                          onPressed: _passengers > 1
                              ? () => setState(() => _passengers--)
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            '$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.darkPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          color: AppColors.primary,
                          onPressed: _passengers < 9
                              ? () => setState(() => _passengers++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                label: AppStrings.search,
                onPressed: _search,
                isLoading: isSearching,
                icon: Icons.search_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
