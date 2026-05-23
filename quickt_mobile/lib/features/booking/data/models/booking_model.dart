class PassengerInfo {
  final String fullName;
  final String phone;
  final String idType;
  final String idNumber;
  final int bagsCount;
  final bool hasExtraLargeLuggage;
  final bool needsWheelchair;
  final bool needsSpecialAssistance;
  final String? dietaryNotes;

  const PassengerInfo({
    required this.fullName,
    this.phone = '',
    this.idType = 'national_id',
    this.idNumber = '',
    this.bagsCount = 1,
    this.hasExtraLargeLuggage = false,
    this.needsWheelchair = false,
    this.needsSpecialAssistance = false,
    this.dietaryNotes,
  });
}

class BookingModel {
  final String id;
  final String userId;
  final String tripId;
  final int? seatNumber;
  final String passengerName;
  final String? passengerPhone;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.tripId,
    this.seatNumber,
    required this.passengerName,
    this.passengerPhone,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'],
        userId: json['user_id'],
        tripId: json['trip_id'],
        seatNumber: json['seat_number'],
        passengerName: json['passenger_name'],
        passengerPhone: json['passenger_phone'],
        totalPrice: (json['total_price'] as num).toDouble(),
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
      );

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}

class TicketModel {
  final String id;
  final String bookingId;
  final String ticketCode;
  final String? qrData;
  final String status;
  final DateTime issuedAt;

  TicketModel({
    required this.id,
    required this.bookingId,
    required this.ticketCode,
    this.qrData,
    required this.status,
    required this.issuedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
        id: json['id'],
        bookingId: json['booking_id'],
        ticketCode: json['ticket_code'],
        qrData: json['qr_data'],
        status: json['status'],
        issuedAt: DateTime.parse(json['issued_at']),
      );

  bool get isActive => status == 'active';
}
