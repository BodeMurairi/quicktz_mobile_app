import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    setState(() => _notificationsEnabled = enabled);
  }

  void _showSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.darkPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ),
              const Divider(height: 1, color: Color(0xFFEEF0F5)),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  child: Text(content,
                      style: const TextStyle(
                          color: AppColors.darkPrimary,
                          fontSize: 13,
                          height: 1.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaq(AppL10n l10n) {
    final faqs = l10n.faqItems;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(l10n.frequentlyAskedQuestions,
                    style: const TextStyle(
                        color: AppColors.darkPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ),
              const Divider(height: 1, color: Color(0xFFEEF0F5)),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: faqs.length,
                  itemBuilder: (_, i) => Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.grey,
                      title: Text(faqs[i].$1,
                          style: const TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      children: [
                        Text(faqs[i].$2,
                            style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _contact(AppL10n l10n) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@quicktz.com',
      query: 'subject=QuickTZ Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email: support@quicktz.com'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final currentLang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: Text(l10n.settingsTitle,
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── General ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.general, icon: Icons.tune_rounded),
          _SettingsCard(children: [
            _LangTile(
              current: currentLang,
              l10n: l10n,
              onChanged: (lang) =>
                  ref.read(localeProvider.notifier).setLocale(lang),
            ),
            const _Divider(),
            _SwitchTile(
              icon: Icons.notifications_outlined,
              label: l10n.notifications,
              value: _notificationsEnabled,
              onChanged: _setNotifications,
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: l10n.about, icon: Icons.info_outline_rounded),
          _SettingsCard(children: [
            _TapTile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.privacyPolicy,
              onTap: () =>
                  _showSheet(l10n.privacyPolicy, l10n.privacyPolicyContent),
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.gavel_rounded,
              label: l10n.termsConditions,
              onTap: () =>
                  _showSheet(l10n.termsConditions, l10n.termsContent),
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.info_rounded,
              label: l10n.appVersion,
              trailing: const Text('1.0.0',
                  style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              onTap: null,
            ),
          ]),

          const SizedBox(height: 20),

          // ── Help & Support ────────────────────────────────────────────────
          _SectionHeader(
              title: l10n.helpSupport,
              icon: Icons.help_outline_rounded),
          _SettingsCard(children: [
            _TapTile(
              icon: Icons.quiz_outlined,
              label: l10n.faq,
              onTap: () => _showFaq(l10n),
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.mail_outline_rounded,
              label: l10n.contactUs,
              onTap: () => _contact(l10n),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      );
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: Color(0xFFF0F2F7)),
      );
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LangTile extends StatelessWidget {
  final String current;
  final AppL10n l10n;
  final ValueChanged<String> onChanged;
  const _LangTile(
      {required this.current, required this.l10n, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(l10n.language,
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          _LangChip(
            label: 'FR',
            selected: current == 'fr',
            onTap: () => onChanged('fr'),
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: 'EN',
            selected: current == 'en',
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color:
                      selected ? AppColors.white : AppColors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      );
}

// ── Switch tile ───────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      );
}

// ── Tappable tile ─────────────────────────────────────────────────────────────

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _TapTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                trailing ??
                    (onTap != null
                        ? const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.grey, size: 14)
                        : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
}
