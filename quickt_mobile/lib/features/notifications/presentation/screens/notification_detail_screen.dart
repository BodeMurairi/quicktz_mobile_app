import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;
  final NotificationModel? notification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).markRead(widget.notificationId);
    });
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'trip_reminder':
        return Icons.schedule_rounded;
      case 'trip_update':
        return Icons.warning_amber_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'booking':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'trip_update':
        return AppColors.warning;
      case 'promotion':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'trip_reminder':
        return 'Trip Reminder';
      case 'trip_update':
        return 'Trip Update';
      case 'promotion':
        return 'Promotion';
      case 'booking':
        return 'Booking';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final n = widget.notification ??
        state.notifications
            .cast<NotificationModel?>()
            .firstWhere((n) => n?.id == widget.notificationId,
                orElse: () => null);

    if (n == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.darkPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Notification not found',
              style: TextStyle(color: AppColors.grey)),
        ),
      );
    }

    final color = _typeColor(n.type);
    final icon = _typeIcon(n.type);
    final label = _typeLabel(n.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notification',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon + type badge ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Content card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: const TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.3)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.secondary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy · HH:mm')
                            .format(n.createdAt),
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFEEF0F5)),
                  const SizedBox(height: 18),

                  Text(n.body,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          height: 1.65)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Contextual action ─────────────────────────────────────────
            if (n.type == 'booking' || n.type == 'trip_reminder')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/tickets'),
                  icon: const Icon(Icons.confirmation_number_rounded,
                      size: 18),
                  label: const Text('View My Tickets',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

            if (n.type == 'promotion')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Browse Trips',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
