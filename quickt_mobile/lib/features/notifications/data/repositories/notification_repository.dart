import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiEndpoints.notifications);
    return (response.data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<void> markAllRead() => _dio.post(ApiEndpoints.readAllNotifications);

  Future<void> markRead(String id) =>
      _dio.post(ApiEndpoints.readNotification(id));
}
