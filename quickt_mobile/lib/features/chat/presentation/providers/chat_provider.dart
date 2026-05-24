import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/chat_repository.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kCurrentMessages = 'chat_current_messages';
const _kCurrentSession  = 'chat_current_session_id';
const _kHistorySessions = 'chat_history_sessions';

// ── Models ────────────────────────────────────────────────────────────────────

class ChatMessage {
  final bool isUser;
  final String text;
  final String? bookingId;
  final String? ticketCode;
  final List<String>? chips;
  // Rich UI-only fields — not persisted (they are ephemeral per-response).
  final List<TripOption>? tripOptions;
  final BookingPreview? bookingPreview;

  const ChatMessage({
    required this.isUser,
    required this.text,
    this.bookingId,
    this.ticketCode,
    this.chips,
    this.tripOptions,
    this.bookingPreview,
  });

  bool get hasBooking       => bookingId != null && ticketCode != null;
  bool get hasTripOptions   => tripOptions != null && tripOptions!.isNotEmpty;
  bool get hasBookingPreview => bookingPreview != null;

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        if (bookingId != null) 'bookingId': bookingId,
        if (ticketCode != null) 'ticketCode': ticketCode,
        if (chips != null) 'chips': chips,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        isUser:    j['isUser'] as bool,
        text:      j['text'] as String,
        bookingId: j['bookingId'] as String?,
        ticketCode: j['ticketCode'] as String?,
        chips: (j['chips'] as List<dynamic>?)?.cast<String>(),
      );
}

/// A completed past conversation stored in history.
class ChatSession {
  final String id;
  final DateTime startedAt;
  final List<ChatMessage> messages;

  const ChatSession({
    required this.id,
    required this.startedAt,
    required this.messages,
  });

  String get preview {
    final first = messages.firstWhere((m) => m.isUser,
        orElse: () => messages.first);
    return first.text.length > 60
        ? '${first.text.substring(0, 60)}…'
        : first.text;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id:        j['id'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        messages: (j['messages'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? sessionId;
  final String? error;
  final List<ChatSession> history;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.sessionId,
    this.error,
    this.history = const [],
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? sessionId,
    String? error,
    List<ChatSession>? history,
  }) =>
      ChatState(
        messages:  messages  ?? this.messages,
        isTyping:  isTyping  ?? this.isTyping,
        sessionId: sessionId ?? this.sessionId,
        error:     error,
        history:   history   ?? this.history,
      );
}

// ── Welcome message ───────────────────────────────────────────────────────────

const _kWelcome = ChatMessage(
  isUser: false,
  text: "👋 Welcome to **QuickTZ AI Travel Companion**!\n\n"
      "I'm your personal bus travel assistant across Togo. Tell me where "
      "you want to go and I'll find the best options, compare prices, and "
      "even book your ticket — all right here in chat.\n\n"
      "How can I assist you today?",
  chips: [
    'Find a bus trip 🔍',
    'Learn about agencies 🏢',
    'I need help ℹ️',
  ],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._repo)
      : super(const ChatState(messages: [_kWelcome])) {
    _load();
  }

  final ChatRepository _repo;

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawHist   = prefs.getString(_kHistorySessions);
      final rawMsgs   = prefs.getString(_kCurrentMessages);
      final sessionId = prefs.getString(_kCurrentSession);

      var history = rawHist != null
          ? (jsonDecode(rawHist) as List<dynamic>)
              .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ChatSession>[];

      // Auto-archive any previous unfinished session that had user messages.
      if (rawMsgs != null && rawMsgs.isNotEmpty && sessionId != null) {
        final loaded = (jsonDecode(rawMsgs) as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        final hasUserMessages = loaded.any((m) => m.isUser);
        if (hasUserMessages) {
          final session = ChatSession(
            id: sessionId,
            startedAt: DateTime.now(),
            messages: loaded,
          );
          history = [session, ...history].take(30).toList();
          await _saveHistory(history);
        }
        // Clear the current session so next open starts fresh.
        await prefs.remove(_kCurrentMessages);
        await prefs.remove(_kCurrentSession);
      }

      // Always start with a clean welcome screen.
      state = state.copyWith(
        messages: const [_kWelcome],
        history: history,
      );
    } catch (_) {
      // Corrupted prefs — start fresh.
    }
  }

  Future<void> _saveCurrentMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCurrentMessages,
        jsonEncode(state.messages.map((m) => m.toJson()).toList()),
      );
      if (state.sessionId != null) {
        await prefs.setString(_kCurrentSession, state.sessionId!);
      }
    } catch (_) {}
  }

  Future<void> _saveHistory(List<ChatSession> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kHistorySessions,
        jsonEncode(history.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(isUser: true, text: text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      error: null,
    );

    try {
      final result =
          await _repo.sendMessage(text.trim(), sessionId: state.sessionId);

      final botMsg = ChatMessage(
        isUser:         false,
        text:           result.response,
        bookingId:      result.bookingId,
        ticketCode:     result.ticketCode,
        tripOptions:    result.tripSuggestions,
        bookingPreview: result.bookingPreview,
        chips:          result.chips,
      );

      state = state.copyWith(
        messages:  [...state.messages, botMsg],
        isTyping:  false,
        sessionId: result.sessionId,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(
            isUser: false,
            text: 'Sorry, I ran into an issue. Please check your connection and try again.',
          ),
        ],
        isTyping: false,
        error: e.toString(),
      );
    }

    await _saveCurrentMessages();
  }

  /// Saves the current conversation to history and starts a fresh session.
  Future<void> reset() async {
    // Archive non-trivial conversations (more than just the welcome message).
    final userMessages = state.messages.where((m) => m.isUser).toList();
    if (userMessages.isNotEmpty && state.sessionId != null) {
      final session = ChatSession(
        id:        state.sessionId!,
        startedAt: DateTime.now(),
        messages:  List.from(state.messages),
      );
      final updated = [session, ...state.history].take(30).toList();
      state = state.copyWith(history: updated);
      await _saveHistory(updated);
    }

    state = state.copyWith(
      messages: const [_kWelcome],
      sessionId: null,
      isTyping:  false,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCurrentMessages);
      await prefs.remove(_kCurrentSession);
    } catch (_) {}
  }

  /// Restores a past session so the user can read it (read-only replay).
  void viewHistorySession(ChatSession session) {
    state = state.copyWith(messages: session.messages, sessionId: session.id);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(history: const []);
    await _saveHistory([]);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider((ref) => ChatRepository());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.read(chatRepositoryProvider)),
);
