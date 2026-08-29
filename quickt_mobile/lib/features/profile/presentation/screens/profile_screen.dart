import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.darkPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.white, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    if (user?.isPremium == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(l10n.premiumMember,
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info card
                  _InfoCard(user: user),
                  const SizedBox(height: 16),
                  // Menu items
                  _menuCard([
                    _MenuItem(
                      icon: Icons.confirmation_number_outlined,
                      label: l10n.bookingHistory,
                      onTap: () => context.go('/tickets'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: l10n.notifications,
                      onTap: () => context.go('/notifications'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (user?.isPremium == false) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  color: AppColors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.upgradeToPremium,
                                  style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.isFr
                                ? 'Réservation prioritaire · Annulation flexible · Offres exclusives'
                                : 'Priority booking · Flexible cancellation · Exclusive deals',
                            style: const TextStyle(
                                color: AppColors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: l10n.upgradeToPremium,
                            color: AppColors.white,
                            isLoading: authState.isLoading,
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(authProvider.notifier)
                                    .upgradeToPremium();
                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Welcome to Premium!')),
                                );
                              } catch (_) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        ref.read(authProvider).error ??
                                            'Something went wrong. Please try again.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _menuCard([
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: l10n.logOut,
                      color: AppColors.error,
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(List<Widget> items) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: items),
      );
}

class _InfoCard extends StatelessWidget {
  final dynamic user;
  const _InfoCard({required this.user});

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
        children: [
          if (user?.email != null)
            _row(Icons.email_outlined, user.email),
          if (user?.phoneNumber != null)
            _row(Icons.phone_outlined, user.phoneNumber),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 18),
            const SizedBox(width: 12),
            Text(value,
                style: const TextStyle(
                    color: AppColors.darkPrimary, fontSize: 14)),
          ],
        ),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.darkPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.grey, size: 14),
    );
  }
}
