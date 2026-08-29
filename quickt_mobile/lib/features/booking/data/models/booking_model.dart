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

class ReviewModel {
  final String id;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'],
        rating: json['rating'],
        comment: json['comment'],
        reply: json['reply'],
        repliedAt: json['replied_at'] != null
            ? DateTime.parse(json['replied_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
      );
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
  final ReviewModel? review;

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
    this.review,
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
        review: json['review'] != null
            ? ReviewModel.fromJson(json['review'])
            : null,
      );

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isPendingApproval => status == 'pending_approval';
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
