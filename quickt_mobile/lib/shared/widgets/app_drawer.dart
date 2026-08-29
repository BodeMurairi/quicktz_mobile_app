import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/messages/presentation/providers/conversation_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final l10n = ref.watch(l10nProvider);
    final conversations = ref.watch(conversationsProvider).valueOrNull ?? const [];
    final unreadCount = conversations.fold<int>(0, (s, c) => s + c.unreadCount);
    final firstName = user?.fullName.split(' ').first ?? l10n.guest;
    final email = user?.email ?? user?.phoneNumber ?? '';

    return Drawer(
      backgroundColor: AppColors.white,
      width: 290,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? l10n.guest,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                _PremiumBadge(
                    isPremium: user?.isPremium ?? false, l10n: l10n),
              ],
            ),
          ),
          // ── Nav items ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: l10n.myProfile,
                  onTap: () => _nav(context, '/profile'),
                ),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.notifications,
                  onTap: () => _nav(context, '/notifications'),
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: l10n.askBot,
                  onTap: () => _nav(context, '/chat'),
                  highlighted: true,
                ),
                _DrawerItem(
                  icon: Icons.mail_outline_rounded,
                  label: l10n.messages,
                  trailingCount: unreadCount,
                  onTap: () => _nav(context, '/messages'),
                ),
                _DrawerItem(
                  icon: Icons.map_outlined,
                  label: l10n.tripPlanner,
                  onTap: () => _nav(context, '/trip-planner'),
                ),
                _DrawerItem(
                  icon: Icons.confirmation_number_outlined,
                  label: l10n.myTickets,
                  onTap: () => _nav(context, '/tickets'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(color: AppColors.background, thickness: 1.5),
                ),
                _DrawerItem(
                  icon: Icons.card_giftcard_rounded,
                  label: l10n.giftCards,
                  badge: l10n.locale == 'fr' ? 'Nouveau' : 'New',
                  onTap: () =>
                      _showComingSoon(context, l10n.giftCards, l10n.comingSoon),
                ),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: l10n.helpSupport,
                  onTap: () => _showComingSoon(
                      context, l10n.helpSupport, l10n.comingSoon),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: l10n.settings,
                  onTap: () => _nav(context, '/settings'),
                ),
              ],
            ),
          ),
          // ── Footer ──────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.background, thickness: 1.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            child: _DrawerItem(
              icon: Icons.logout_rounded,
              label: l10n.logOut,
              color: AppColors.error,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _nav(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  void _showComingSoon(BuildContext context, String feature, String label) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — $label'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Premium badge ─────────────────────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final AppL10n l10n;
  const _PremiumBadge({required this.isPremium, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFF39C12)
            : AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isPremium ? l10n.premiumMember : l10n.freePlan,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Drawer item ───────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final int? trailingCount;
  final Color? color;
  final bool highlighted;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.trailingCount,
    this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.darkPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: highlighted ? AppColors.primary : itemColor,
                  size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: highlighted ? AppColors.primary : itemColor,
                      fontWeight: highlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              if (trailingCount != null && trailingCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailingCount! > 9 ? '9+' : '$trailingCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              if (highlighted)
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
