import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  // Web (Docker): Nginx proxies /api/ → backend container — use relative origin.
  // Mobile (emulator): 10.0.2.2 = host machine from Android emulator.
  // Mobile (physical device): set to your machine's LAN IP, e.g. http://192.168.1.x:8000/api/v1
  static String get baseUrl =>
      kIsWeb ? '/api/v1' : 'https://unparched-morris-unfinishable.ngrok-free.dev/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Users
  static const String userProfile = '/users/me';
  static const String upgradePremium = '/users/me/upgrade-premium';

  // Agencies
  static const String agencies = '/agencies';
  static String agencyDetail(String id) => '/agencies/$id';

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

  // Tickets
  static const String tickets = '/tickets';
  static String ticketDetail(String id) => '/tickets/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String readAllNotifications = '/notifications/read-all';
  static String readNotification(String id) => '/notifications/$id/read';
}
