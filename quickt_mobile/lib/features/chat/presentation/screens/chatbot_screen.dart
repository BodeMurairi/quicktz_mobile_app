import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/chat_repository.dart';
import '../providers/chat_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHistory(BuildContext context) {
    final history = ref.read(chatProvider).history;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        history: history,
        onSelect: (session) {
          Navigator.pop(context);
          ref.read(chatProvider.notifier).viewHistorySession(session);
          _scrollToBottom();
        },
        onClear: () {
          Navigator.pop(context);
          ref.read(chatProvider.notifier).clearHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    ref.listen(chatProvider, (prev, next) {
      _scrollToBottom();
      // Fire push notification when chatbot confirms a booking.
      if (prev != null && next.messages.length > prev.messages.length) {
        final newest = next.messages.last;
        if (!newest.isUser && newest.hasBooking) {
          NotificationService.instance.show(
            title: 'Booking Confirmed! 🎫',
            body: 'Your ticket ${newest.ticketCode} is ready. Check the Tickets tab.',
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.white),
          onPressed: () => appShellKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QuickTZ AI',
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('Powered by Gemini',
                    style:
                        TextStyle(color: AppColors.secondary, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: AppColors.white),
              tooltip: 'Chat history',
              onPressed: () => _showHistory(context),
            ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.white),
            tooltip: 'New conversation',
            onPressed: () => ref.read(chatProvider.notifier).reset(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: state.messages.length + (state.isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (state.isTyping && i == state.messages.length) {
                  return const _TypingBubble();
                }
                final msg = state.messages[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MessageBubble(msg: msg),
                    if (msg.hasTripOptions)
                      _TripOptionList(
                          options: msg.tripOptions!, onSelect: _send),
                    if (msg.hasBookingPreview)
                      _BookingPreviewCard(
                        preview: msg.bookingPreview!,
                        onConfirm: () => _send(
                          '✅ Confirmed — please book my trip ${msg.bookingPreview!.tripId}',
                        ),
                        onCancel: () =>
                            _send('Cancel this booking, I changed my mind.'),
                      ),
                    if (msg.hasBooking)
                      _BookingConfirmCard(
                        ticketCode: msg.ticketCode!,
                        bookingId: msg.bookingId!,
                        onViewTicket: () => context.go('/tickets'),
                      ),
                    if (msg.chips != null)
                      _ChipRow(chips: msg.chips!, onTap: _send),
                  ],
                );
              },
            ),
          ),
          _InputBar(
              controller: _ctrl,
              onSend: _send,
              isDisabled: state.isTyping),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _RichText(
          text: msg.text,
          baseColor: isUser ? AppColors.white : AppColors.darkPrimary,
        ),
      ),
    );
  }
}

// ── Markdown inline renderer ──────────────────────────────────────────────────

class _RichText extends StatelessWidget {
  final String text;
  final Color baseColor;
  const _RichText({required this.text, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final inner = m.group(1) ?? m.group(2) ?? '';
      spans.add(TextSpan(
        text: inner,
        style: TextStyle(
          fontWeight:
              m.group(1) != null ? FontWeight.w700 : FontWeight.normal,
          fontStyle:
              m.group(2) != null ? FontStyle.italic : FontStyle.normal,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
        style: TextStyle(color: baseColor, fontSize: 14, height: 1.45),
        children: spans,
      ),
    );
  }
}

// ── Trip option cards (selectable) ───────────────────────────────────────────

class _TripOptionList extends StatelessWidget {
  final List<TripOption> options;
  final ValueChanged<String> onSelect;

  const _TripOptionList({required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Available trips — tap to select:',
              style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ),
        ...options.map((t) => _TripOptionCard(option: t, onSelect: onSelect)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TripOptionCard extends StatelessWidget {
  final TripOption option;
  final ValueChanged<String> onSelect;

  const _TripOptionCard({required this.option, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final dept = option.departure.length >= 16
        ? option.departure.substring(11, 16) // extract HH:mm
        : option.departure;

    return GestureDetector(
      onTap: () => onSelect(
        'I want to book the ${option.agency} trip from ${option.origin} '
        'to ${option.destination} departing at ${option.departure} '
        'for ${fmt.format(option.priceXof)} XOF (trip ID: ${option.id})',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(option.origin,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: AppColors.white, size: 13),
                        ),
                        Flexible(
                          child: Text(option.destination,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('XOF ${fmt.format(option.priceXof)}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ],
              ),
            ),
            // Body
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Agency + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_bus_rounded,
                                color: AppColors.secondary, size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(option.agency,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.darkPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.secondary, size: 13),
                            const SizedBox(width: 4),
                            Text(dept,
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.event_seat_rounded,
                                color: AppColors.secondary, size: 13),
                            const SizedBox(width: 4),
                            Text('${option.availableSeats} seats',
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amenity chips
                  Row(
                    children: [
                      if (option.amenities.wifi)
                        _AmenityDot(
                            icon: Icons.wifi_rounded, label: 'WiFi'),
                      if (option.amenities.ac)
                        _AmenityDot(
                            icon: Icons.ac_unit_rounded, label: 'AC'),
                      if (option.amenities.meal)
                        _AmenityDot(
                            icon: Icons.restaurant_rounded,
                            label: 'Meal'),
                    ],
                  ),
                ],
              ),
            ),
            // Select button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ElevatedButton(
                onPressed: () => onSelect(
                  'I want to book the ${option.agency} trip from ${option.origin} '
                  'to ${option.destination} departing at ${option.departure} '
                  'for ${fmt.format(option.priceXof)} XOF (trip ID: ${option.id})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Select This Trip',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityDot extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityDot({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Tooltip(
          message: label,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                Icon(icon, color: AppColors.primary, size: 12),
          ),
        ),
      );
}

// ── Booking preview card (human-in-the-loop confirmation) ─────────────────────

class _BookingPreviewCard extends StatelessWidget {
  final BookingPreview preview;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BookingPreviewCard({
    required this.preview,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Review Your Booking',
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _PreviewRow(
                  icon: Icons.directions_bus_rounded,
                  label: 'Agency',
                  value: preview.agency,
                ),
                _PreviewRow(
                  icon: Icons.route_rounded,
                  label: 'Route',
                  value: '${preview.origin}  →  ${preview.destination}',
                ),
                _PreviewRow(
                  icon: Icons.schedule_rounded,
                  label: 'Departure',
                  value: preview.departure,
                ),
                if (preview.arrival != 'N/A')
                  _PreviewRow(
                    icon: Icons.flag_rounded,
                    label: 'Arrival',
                    value: preview.arrival,
                  ),
                _PreviewRow(
                  icon: Icons.person_rounded,
                  label: 'Passenger',
                  value: preview.passengerName,
                ),
                if (preview.passengerPhone.isNotEmpty)
                  _PreviewRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: preview.passengerPhone,
                  ),
                _PreviewRow(
                  icon: Icons.payment_rounded,
                  label: 'Payment',
                  value: preview.paymentMethod
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w.isEmpty
                          ? w
                          : '${w[0].toUpperCase()}${w.substring(1)}')
                      .join(' '),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1, color: Color(0xFFEEF0F5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(
                      'XOF ${fmt.format(preview.priceXof)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey,
                      side: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm Booking',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PreviewRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 16),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ── Booking confirmation card (after successful booking) ──────────────────────

class _BookingConfirmCard extends StatelessWidget {
  final String ticketCode;
  final String bookingId;
  final VoidCallback onViewTicket;

  const _BookingConfirmCard({
    required this.ticketCode,
    required this.bookingId,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.white, size: 20),
              SizedBox(width: 8),
              Text('Booking Confirmed!',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Ticket code', value: ticketCode),
          _InfoRow(
              label: 'Booking ref',
              value: bookingId.substring(0, 8).toUpperCase()),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onViewTicket,
              icon: const Icon(Icons.confirmation_number_rounded, size: 16),
              label: const Text('View My Tickets',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_anim.value * 3 - i).clamp(0.0, 1.0);
              final opacity =
                  (0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2))
                      .clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Quick chip row ────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> chips;
  final ValueChanged<String> onTap;
  const _ChipRow({required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips.map((c) {
          return GestureDetector(
            onTap: () => onTap(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(c,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── History bottom sheet ──────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final List<ChatSession> history;
  final ValueChanged<ChatSession> onSelect;
  final VoidCallback onClear;

  const _HistorySheet({
    required this.history,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Chat History',
                        style: TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear all',
                        style: TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            // Sessions list
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text('No past conversations yet.',
                          style: TextStyle(color: AppColors.grey)),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: Color(0xFFEEF0F5)),
                      ),
                      itemBuilder: (_, i) {
                        final s = history[i];
                        final msgCount =
                            s.messages.where((m) => m.isUser).length;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(s.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          subtitle: Text(
                            '${dateFmt.format(s.startedAt)}  ·  $msgCount message${msgCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 13, color: AppColors.grey),
                          onTap: () => onSelect(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isDisabled;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isDisabled,
              onSubmitted: isDisabled ? null : (_) => onSend(),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isDisabled
                    ? 'QuickTZ AI is thinking...'
                    : 'Ask me anything about travel in Togo',
                hintStyle:
                    const TextStyle(color: AppColors.grey, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isDisabled ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isDisabled ? null : AppColors.primaryGradient,
                color: isDisabled ? AppColors.secondary : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDisabled
                    ? Icons.hourglass_empty_rounded
                    : Icons.send_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
