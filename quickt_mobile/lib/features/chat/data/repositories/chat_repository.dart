import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class TripAmenities {
  final bool wifi;
  final bool meal;
  final bool ac;
  final bool usb;

  const TripAmenities({
    this.wifi = false,
    this.meal = false,
    this.ac = false,
    this.usb = false,
  });

  factory TripAmenities.fromJson(Map<String, dynamic> json) => TripAmenities(
        wifi: json['wifi'] as bool? ?? false,
        meal: json['meal'] as bool? ?? false,
        ac: json['ac'] as bool? ?? false,
        usb: json['usb'] as bool? ?? false,
      );
}

class TripOption {
  final String id;
  final String agency;
  final String origin;
  final String destination;
  final String departure;
  final String arrival;
  final int priceXof;
  final int availableSeats;
  final TripAmenities amenities;

  const TripOption({
    required this.id,
    required this.agency,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.priceXof,
    required this.availableSeats,
    required this.amenities,
  });

  factory TripOption.fromJson(Map<String, dynamic> json) => TripOption(
        id: json['id'] as String,
        agency: json['agency'] as String? ?? 'Unknown',
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        departure: json['departure'] as String? ?? '',
        arrival: json['arrival'] as String? ?? 'N/A',
        priceXof: (json['price_xof'] as num?)?.toInt() ?? 0,
        availableSeats: (json['available_seats'] as num?)?.toInt() ?? 0,
        amenities: TripAmenities.fromJson(
            json['amenities'] as Map<String, dynamic>? ?? {}),
      );
}

class BookingPreview {
  final String tripId;
  final String agency;
  final String origin;
  final String destination;
  final String departure;
  final String arrival;
  final int priceXof;
  final String passengerName;
  final String passengerPhone;
  final String paymentMethod;

  const BookingPreview({
    required this.tripId,
    required this.agency,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.priceXof,
    required this.passengerName,
    required this.passengerPhone,
    required this.paymentMethod,
  });

  factory BookingPreview.fromJson(Map<String, dynamic> json) => BookingPreview(
        tripId: json['trip_id'] as String,
        agency: json['agency'] as String? ?? 'Unknown',
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        departure: json['departure'] as String? ?? '',
        arrival: json['arrival'] as String? ?? 'N/A',
        priceXof: (json['price_xof'] as num?)?.toInt() ?? 0,
        passengerName: json['passenger_name'] as String? ?? '',
        passengerPhone: json['passenger_phone'] as String? ?? '',
        paymentMethod: json['payment_method'] as String? ?? 'mobile_money',
      );
}

class AgentChatResult {
  final String response;
  final String sessionId;
  final String? action;
  final String? bookingId;
  final String? ticketCode;
  final List<TripOption>? tripSuggestions;
  final BookingPreview? bookingPreview;
  final List<String>? chips;

  const AgentChatResult({
    required this.response,
    required this.sessionId,
    this.action,
    this.bookingId,
    this.ticketCode,
    this.tripSuggestions,
    this.bookingPreview,
    this.chips,
  });

  factory AgentChatResult.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['trip_suggestions'] as List<dynamic>?;
    final previewJson = json['booking_preview'] as Map<String, dynamic>?;

    return AgentChatResult(
      response: json['response'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      action: json['action'] as String?,
      bookingId: json['booking_id'] as String?,
      ticketCode: json['ticket_code'] as String?,
      tripSuggestions: suggestionsJson
          ?.map((e) => TripOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookingPreview:
          previewJson != null ? BookingPreview.fromJson(previewJson) : null,
      chips: (json['chips'] as List<dynamic>?)?.cast<String>(),
    );
  }

  bool get hasBooking => action == 'booking_confirmed' && bookingId != null;
  bool get hasTripSuggestions =>
      tripSuggestions != null && tripSuggestions!.isNotEmpty;
  bool get hasBookingPreview => bookingPreview != null;
}

class ChatRepository {
  final Dio _dio = ApiClient.instance;

  Future<AgentChatResult> sendMessage(String message, {String? sessionId}) async {
    final body = <String, dynamic>{
      'message': message,
      'session_id': sessionId,
    };
    final response = await _dio.post(ApiEndpoints.agentChat, data: body);
    return AgentChatResult.fromJson(response.data as Map<String, dynamic>);
  }
}
