import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../providers/conversation_provider.dart';

/// Mounted once at the app root (see app.dart's MaterialApp.router `builder`) so it
/// keeps polling regardless of which screen is currently on top, and pops a SnackBar
/// whenever the rider's total unread-from-agency message count goes up.
class MessageWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const MessageWatcher({required this.child, super.key});

  @override
  ConsumerState<MessageWatcher> createState() => _MessageWatcherState();
}

class _MessageWatcherState extends ConsumerState<MessageWatcher> {
  Timer? _timer;
  int? _lastUnreadTotal;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (ref.read(authProvider).user == null) return;
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(conversationsProvider, (previous, next) {
      final conversations = next.valueOrNull;
      if (conversations == null) return;

      final total = conversations.fold<int>(0, (s, c) => s + c.unreadCount);
      if (_lastUnreadTotal != null && total > _lastUnreadTotal!) {
        final activeId = ref.read(activeConversationIdProvider);
        final unread = conversations
            .where((c) => c.unreadCount > 0 && c.id != activeId)
            .toList();
        unread.sort((a, b) {
          final aTime = a.lastMessage?.createdAt ?? a.createdAt;
          final bTime = b.lastMessage?.createdAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        final ConversationModel? withNew = unread.isNotEmpty ? unread.first : null;

        // The only conversation with new messages is the one already open — the
        // rider is already looking at it, so a popup would just be noise.
        if (withNew == null) {
          _lastUnreadTotal = total;
          return;
        }

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('New message from ${withNew.agencyName}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                final ctx = scaffoldMessengerKey.currentContext;
                if (ctx != null) GoRouter.of(ctx).push('/messages/${withNew.id}');
              },
            ),
          ),
        );
      }
      _lastUnreadTotal = total;
    });

    return widget.child;
  }
}
