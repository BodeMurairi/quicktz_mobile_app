import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiEndpoints {
  // Web prod (Docker): Nginx proxies /api/ → backend container — use relative origin.
  // Web dev (flutter run -d chrome): no proxy in front, hit the local backend directly.
  // Mobile on same WiFi: uses LAN IP directly (avoids carrier DNS blocks on ngrok).
  // Mobile on different network: switch back to ngrok URL below.
  static String get baseUrl => kIsWeb
      ? (kDebugMode ? 'http://localhost:8000/api/v1' : '/api/v1')
      : kDebugMode
          ? 'http://192.168.1.77:8000/api/v1'
          : 'https://quickt.dessartstudio.com/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String userProfile = '/users/me';
  static const String upgradePremium = '/users/me/upgrade-premium';

  // Agencies
  static const String agencies = '/agencies';
  static String agencyDetail(String id) => '/agencies/$id';
  static String agencyRoutes(String id) => '/agencies/$id/routes';
  static String agencyReviews(String id) => '/agencies/$id/reviews';
  static String agencyRatingSummary(String id) => '/agencies/$id/rating-summary';

  // Trips
  static const String trips = '/trips';
  static const String searchTrips = '/trips/search';
  static String tripDetail(String id) => '/trips/$id';

  // Bookings
  static const String bookings = '/bookings';
  static String simulateBooking(String tripId) => '/bookings/simulate/$tripId';
  static String bookingDetail(String id) => '/bookings/$id';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String rescheduleBooking(String id) => '/bookings/$id/reschedule';
  static String reviewBooking(String id) => '/bookings/$id/review';
  static String approveBooking(String id) => '/bookings/$id/approve';

  // Tickets
  static const String tickets = '/tickets';
  static String ticketDetail(String id) => '/tickets/$id';

  // AI Agent
  static const String agentChat = '/agent/chat';

  // Notifications
  static const String notifications = '/notifications';
  static const String readAllNotifications = '/notifications/read-all';
  static String readNotification(String id) => '/notifications/$id/read';

  // Conversations (rider ↔ agency messaging)
  static const String conversations = '/conversations';
  static String conversationMessages(String id) => '/conversations/$id/messages';

  // Uploads (message attachments)
  static const String uploads = '/uploads';
}
