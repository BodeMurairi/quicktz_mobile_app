import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../features/booking/data/models/booking_model.dart';
import '../../../../features/booking/presentation/providers/booking_provider.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.white),
          onPressed: () => appShellKey.currentState?.openDrawer(),
        ),
        title: Text(l10n.myTickets,
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.secondary,
          tabs: [
            Tab(
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                text: l10n.tickets),
            Tab(
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                text: l10n.isFr ? 'Paiements' : 'Payments'),
          ],
        ),
      ),
      body: state.isLoading
          ? lw.LoadingWidget(
              message: l10n.isFr ? 'Chargement…' : 'Loading tickets...')
          : TabBarView(
              controller: _tabController,
              children: [
                _TicketsTab(tickets: state.tickets),
                _PaymentsTab(bookings: state.bookings),
              ],
            ),
    );
  }
}

// ── Tickets tab ───────────────────────────────────────────────────────────────

class _TicketsTab extends ConsumerWidget {
  final List<TicketModel> tickets;
  const _TicketsTab({required this.tickets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number_outlined,
                color: AppColors.secondary, size: 64),
            const SizedBox(height: 16),
            Text(l10n.noTickets,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(l10n.bookFirstTrip,
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  Color get _statusColor {
    switch (ticket.status) {
      case 'active':
        return AppColors.success;
      case 'used':
        return AppColors.grey;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  void _copyTicket(BuildContext context) {
    Clipboard.setData(ClipboardData(text: ticket.ticketCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket code copied'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/ticket/${ticket.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 88,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.ticketCode,
                              style: const TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy').format(ticket.issuedAt),
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.status.toUpperCase(),
                            style: TextStyle(
                                color: _statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _copyTicket(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.download_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payments tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  final List<BookingModel> bookings;
  const _PaymentsTab({required this.bookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.secondary, size: 64),
            const SizedBox(height: 16),
            Text(l10n.isFr ? 'Aucun paiement' : 'No payments yet',
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
                l10n.isFr
                    ? 'Les paiements effectués apparaîtront ici'
                    : 'Completed payments will appear here',
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _PaymentCard(booking: bookings[i]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final BookingModel booking;
  const _PaymentCard({required this.booking});

  Color get _statusColor =>
      booking.isConfirmed ? AppColors.success : AppColors.error;

  String get _statusLabel =>
      booking.isConfirmed ? 'SUCCESS' : 'FAILED';

  IconData get _statusIcon => booking.isConfirmed
      ? Icons.check_circle_rounded
      : Icons.cancel_rounded;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');
    final amtFmt = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passengerName,
                  style: const TextStyle(
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  dateFmt.format(booking.createdAt),
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'XOF ${amtFmt.format(booking.totalPrice.toInt())}',
                style: const TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
