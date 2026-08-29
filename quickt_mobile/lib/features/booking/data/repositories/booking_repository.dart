import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final Dio _dio = ApiClient.instance;

  Future<BookingModel> createBooking({
    required String tripId,
    required String passengerName,
    String? passengerPhone,
    int? seatNumber,
    required String paymentMethod,
  }) async {
    final body = <String, dynamic>{
      'trip_id': tripId,
      'passenger_name': passengerName,
      'payment_method': paymentMethod,
    };
    if (passengerPhone != null) body['passenger_phone'] = passengerPhone;
    if (seatNumber != null) body['seat_number'] = seatNumber;
    final response = await _dio.post(ApiEndpoints.bookings, data: body);
    return BookingModel.fromJson(response.data);
  }

  Future<BookingModel> simulateBooking(String tripId) async {
    final response = await _dio.post(ApiEndpoints.simulateBooking(tripId));
    return BookingModel.fromJson(response.data);
  }

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _dio.get(ApiEndpoints.bookings);
    return (response.data as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<BookingModel> getBookingDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.bookingDetail(id));
    return BookingModel.fromJson(response.data);
  }

  Future<BookingModel> cancelBooking(String id) async {
    final response = await _dio.post(ApiEndpoints.cancelBooking(id), data: {});
    return BookingModel.fromJson(response.data);
  }

  Future<BookingModel> rescheduleBooking(String id, String newTripId) async {
    final response = await _dio.post(ApiEndpoints.rescheduleBooking(id), data: {
      'new_trip_id': newTripId,
    });
    return BookingModel.fromJson(response.data);
  }

  Future<List<TicketModel>> getMyTickets() async {
    final response = await _dio.get(ApiEndpoints.tickets);
    return (response.data as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicketDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.ticketDetail(id));
    return TicketModel.fromJson(response.data);
  }

  Future<BookingModel> approveBooking(String id, String paymentMethod) async {
    final response = await _dio.post(
      ApiEndpoints.approveBooking(id),
      data: {'payment_method': paymentMethod},
    );
    return BookingModel.fromJson(response.data);
  }

  Future<ReviewModel> submitReview(
    String bookingId, {
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    final response =
        await _dio.post(ApiEndpoints.reviewBooking(bookingId), data: body);
    return ReviewModel.fromJson(response.data);
  }
}
