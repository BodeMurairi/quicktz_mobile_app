import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;
import '../../../search/data/models/trip_model.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../providers/conversation_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Arriving here (via drawer or a "View" popup) means any pending new-message
    // notification has been seen — clear it instead of leaving it hanging around.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => scaffoldMessengerKey.currentState?.hideCurrentSnackBar());
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Messages',
            style: TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.white),
            tooltip: 'Message an agency',
            onPressed: () => _openAgencyPicker(context, ref),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const lw.LoadingWidget(),
        error: (e, _) => lw.ErrorWidget(
          message: 'Failed to load conversations',
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 56, color: AppColors.grey),
                    const SizedBox(height: 14),
                    const Text('No conversations yet',
                        style: TextStyle(
                            color: AppColors.darkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Message an agency to ask about a trip — tap the icon above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final sorted = [...conversations]..sort((a, b) {
              final at = a.lastMessage?.createdAt ?? a.createdAt;
              final bt = b.lastMessage?.createdAt ?? b.createdAt;
              return bt.compareTo(at);
            });

          return RefreshIndicator(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.background),
              itemBuilder: (_, i) {
                final c = sorted[i];
                final last = c.lastMessage;
                return ListTile(
                  onTap: () => context.push('/messages/${c.id}'),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      c.agencyName.isNotEmpty ? c.agencyName[0] : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(c.agencyName,
                      style: const TextStyle(
                          color: AppColors.darkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Text(
                    last != null
                        ? '${last.isFromAgency ? '' : 'You: '}${last.text}'
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (last != null)
                        Text(DateFormat('d MMM').format(last.createdAt),
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 11)),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${c.unreadCount}',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openAgencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AgencyPickerSheet(
        onPicked: (agencyId) async {
          Navigator.of(context).pop();
          final repo = ref.read(conversationRepositoryProvider);
          final conversation = await repo.startConversation(agencyId);
          ref.invalidate(conversationsProvider);
          if (context.mounted) context.push('/messages/${conversation.id}');
        },
      ),
    );
  }
}

class _AgencyPickerSheet extends ConsumerWidget {
  final void Function(String agencyId) onPicked;
  const _AgencyPickerSheet({required this.onPicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(_agenciesForPickerProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Message an agency',
                style: TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: agenciesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => const Center(
                    child: Text('Could not load agencies',
                        style: TextStyle(color: AppColors.grey))),
                data: (agencies) => ListView.builder(
                  itemCount: agencies.length,
                  itemBuilder: (_, i) {
                    final a = agencies[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(a.name.isNotEmpty ? a.name[0] : '?',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                      title: Text(a.name,
                          style: const TextStyle(
                              color: AppColors.darkPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      onTap: () => onPicked(a.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _agenciesForPickerProvider = FutureProvider<List<AgencyModel>>((ref) {
  return ref.read(tripRepositoryProvider).getAgencies();
});
