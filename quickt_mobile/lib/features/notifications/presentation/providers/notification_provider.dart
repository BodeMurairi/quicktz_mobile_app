import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;

  NotificationNotifier(this._repo) : super(const NotificationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getNotifications();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                title: n.title,
                body: n.body,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList(),
    );
  }

  void addLocalNotification({
    required String title,
    required String body,
    required String type,
  }) {
    final n = NotificationModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(notifications: [n, ...state.notifications]);
  }

  Future<void> markRead(String id) async {
    final already = state.notifications
        .where((n) => n.id == id)
        .any((n) => n.isRead);
    if (already) return;
    try {
      await _repo.markRead(id);
    } catch (_) {}
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id != id
              ? n
              : NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
          .toList(),
    );
  }
}

final notificationRepositoryProvider =
    Provider((_) => NotificationRepository());
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.read(notificationRepositoryProvider)),
);
