import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'fr';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'fr';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _language = lang);
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

  void _showFaq() {
    const faqs = [
      (
        'How do I book a trip?',
        'Search for your route using the Search tab. Select a trip, fill in your passenger details, choose a payment method and confirm. You\'ll receive a ticket instantly.',
      ),
      (
        'Can I cancel my booking?',
        'Yes. Go to My Tickets, open the ticket you want to cancel, and tap "Cancel Booking". Refunds are processed within 3–5 business days depending on your payment method.',
      ),
      (
        'What payment methods are accepted?',
        'We accept T-Money, Flooz, and bank transfer. All payments are processed securely.',
      ),
      (
        'How do I get my ticket?',
        'Your ticket is available immediately after booking under the "Tickets" tab. You can download it as a PDF or show the QR code at the bus station.',
      ),
      (
        'What cities does QuickTZ serve?',
        'We cover Lomé, Kara, Sokodé, Dapaong, Atakpamé, Bassar, Notsé, Tsévié, Bafilo, Niamtougou, Badou, Aného, Vogan, and Tabligbo.',
      ),
      (
        'How does the AI chatbot work?',
        'The QuickTZ AI can search for trips, compare agencies, and even book your ticket — all through conversation. Just describe what you need in plain language.',
      ),
    ];

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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Frequently Asked Questions',
                    style: TextStyle(
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

  Future<void> _contact() async {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Settings',
            style: TextStyle(
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
          _SectionHeader(title: 'General', icon: Icons.tune_rounded),
          _SettingsCard(children: [
            _LangTile(
              current: _language,
              onChanged: _setLanguage,
            ),
            const _Divider(),
            _SwitchTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              value: _notificationsEnabled,
              onChanged: _setNotifications,
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'About', icon: Icons.info_outline_rounded),
          _SettingsCard(children: [
            _TapTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showSheet('Privacy Policy', _kPrivacyPolicy),
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.gavel_rounded,
              label: 'Terms & Conditions',
              onTap: () =>
                  _showSheet('Terms & Conditions', _kTermsConditions),
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.info_rounded,
              label: 'App Version',
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
              title: 'Help & Support',
              icon: Icons.help_outline_rounded),
          _SettingsCard(children: [
            _TapTile(
              icon: Icons.quiz_outlined,
              label: 'FAQ',
              onTap: _showFaq,
            ),
            const _Divider(),
            _TapTile(
              icon: Icons.mail_outline_rounded,
              label: 'Contact Us',
              onTap: _contact,
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
  final ValueChanged<String> onChanged;
  const _LangTile({required this.current, required this.onChanged});

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
          const Expanded(
            child: Text('Language',
                style: TextStyle(
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

// ── Legal content ──────────────────────────────────────────────────────────────

const _kPrivacyPolicy = '''
Last updated: May 2025

QuickTZ ("we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use the QuickTZ mobile application.

1. Information We Collect
We collect information you provide directly when you create an account, book a trip, or contact us. This includes your name, phone number, email address, and payment information.

2. How We Use Your Information
We use your personal data to:
• Process and confirm your trip bookings
• Send booking confirmations and trip reminders
• Improve the app and personalise your experience
• Comply with legal obligations

3. Data Sharing
We do not sell your personal data. We may share your information with:
• Bus agencies to fulfil your bookings
• Payment processors to complete transactions
• Legal authorities if required by law

4. Data Security
We implement industry-standard security measures including encrypted storage and secure HTTPS connections to protect your data.

5. Your Rights
You have the right to access, correct, or delete your personal data. Contact us at privacy@quicktz.com for any requests.

6. Cookies & Analytics
The app may collect anonymised usage data to improve performance and user experience.

7. Contact
For privacy-related questions: privacy@quicktz.com
''';

const _kTermsConditions = '''
Last updated: May 2025

These Terms & Conditions govern your use of the QuickTZ mobile application and the services provided through it.

1. Acceptance of Terms
By using QuickTZ, you agree to these terms. If you do not agree, please do not use the app.

2. Booking Policy
• Bookings are confirmed only after successful payment
• Ticket prices are displayed in XOF (CFA Francs) and are inclusive of all fees
• Seats are allocated on a first-come, first-served basis

3. Cancellation & Refunds
• Cancellations made more than 24 hours before departure are eligible for a full refund
• Cancellations within 24 hours of departure are non-refundable
• Refunds are processed within 3–5 business days

4. User Responsibilities
• You are responsible for providing accurate passenger information
• You must present a valid ticket (digital or printed) at boarding
• QuickTZ is not liable for missed trips due to incorrect information

5. Agency Relationships
QuickTZ acts as a booking platform. The bus agencies are independent operators responsible for service delivery, schedules, and on-board experience.

6. Limitation of Liability
QuickTZ is not liable for delays, cancellations, or service failures caused by the bus agencies or events beyond our control.

7. Changes to Terms
We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of the updated terms.

8. Contact
For legal inquiries: legal@quicktz.com
''';
