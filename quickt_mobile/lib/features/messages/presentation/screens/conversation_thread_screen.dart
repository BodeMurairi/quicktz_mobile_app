import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../shared/widgets/loading_widget.dart' as lw;
import '../../data/models/conversation_model.dart';
import '../providers/conversation_provider.dart';

class ConversationThreadScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ConversationThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState
    extends ConsumerState<ConversationThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // Tell the global watcher this thread is open, so it won't pop a "new message"
    // notification for messages the rider is already looking at.
    Future.microtask(() =>
        ref.read(activeConversationIdProvider.notifier).state = widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => scaffoldMessengerKey.currentState?.hideCurrentSnackBar());
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      // Keeps the drawer's unread badge and the global watcher's baseline in sync
      // with messages that just got marked read by fetching them above.
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    if (ref.read(activeConversationIdProvider) == widget.conversationId) {
      ref.read(activeConversationIdProvider.notifier).state = null;
    }
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationRepositoryProvider)
          .sendMessage(widget.conversationId, text);
      _controller.clear();
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendAttachments() async {
    if (_uploading) return;
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading = true);
    final repo = ref.read(conversationRepositoryProvider);
    try {
      for (final f in result.files) {
        if (f.path == null) continue;
        final url = await repo.uploadAttachment(f.path!, f.name);
        await repo.sendMessage(
          widget.conversationId,
          f.name,
          attachmentUrl: url,
          attachmentName: f.name,
          attachmentType: f.extension,
        );
      }
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not upload one or more files.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(conversationMessagesProvider(widget.conversationId));
    final conversations = ref.watch(conversationsProvider).valueOrNull;
    ConversationModel? conversation;
    if (conversations != null) {
      for (final c in conversations) {
        if (c.id == widget.conversationId) {
          conversation = c;
          break;
        }
      }
    }

    ref.listen(conversationMessagesProvider(widget.conversationId), (_, _) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        title: Text(conversation?.agencyName ?? 'Conversation',
            style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/messages'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const lw.LoadingWidget(),
              error: (e, _) => lw.ErrorWidget(
                message: 'Failed to load messages',
                onRetry: () => ref.invalidate(
                    conversationMessagesProvider(widget.conversationId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet — say hello 👋',
                        style: TextStyle(color: AppColors.grey)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isAgency = m.isFromAgency;
                    return Align(
                      alignment: isAgency
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAgency
                              ? AppColors.white
                              : AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isAgency ? 4 : 16),
                            bottomRight: Radius.circular(isAgency ? 16 : 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.text.isNotEmpty)
                              Text(m.text,
                                  style: TextStyle(
                                      color: isAgency
                                          ? AppColors.darkPrimary
                                          : AppColors.white,
                                      fontSize: 13)),
                            if (m.hasAttachment)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: m.text.isNotEmpty ? 6 : 0),
                                child: GestureDetector(
                                  onTap: () =>
                                      _openAttachment(m.attachmentUrl!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isAgency
                                          ? AppColors.background
                                          : AppColors.white
                                              .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.insert_drive_file_rounded,
                                            size: 16,
                                            color: isAgency
                                                ? AppColors.primary
                                                : AppColors.white),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            m.attachmentName ?? 'Attachment',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isAgency
                                                    ? AppColors.darkPrimary
                                                    : AppColors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.download_rounded,
                                            size: 14,
                                            color: isAgency
                                                ? AppColors.primary
                                                : AppColors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(m.createdAt),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isAgency
                                      ? AppColors.grey
                                      : AppColors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.background)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _uploading ? null : _pickAndSendAttachments,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.attach_file_rounded,
                            color: AppColors.grey),
                    tooltip: 'Attach files',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: const TextStyle(
                            color: AppColors.grey, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.send_rounded,
                            color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
