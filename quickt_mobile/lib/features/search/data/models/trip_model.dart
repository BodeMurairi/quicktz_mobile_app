class AgencyModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final bool isVerified;

  AgencyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.phone,
    this.email,
    this.address,
    this.isVerified = false,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) => AgencyModel(
        id: json['id'],
        name: json['name'],
        logoUrl: json['logo_url'],
        description: json['description'],
        phone: json['contact_phone'],
        email: json['contact_email'],
        address: json['address'],
        isVerified: json['is_verified'] ?? false,
      );
}

class RouteStop {
  final String name;
  final int? durationMinutes;

  RouteStop({required this.name, this.durationMinutes});

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
        name: json['name'],
        durationMinutes: json['duration_minutes'],
      );
}

class RouteModel {
  final String id;
  final String origin;
  final String destination;
  final int? durationMinutes;
  final double? distanceKm;
  final List<RouteStop> stops;
  final AgencyModel? agency;

  RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    this.durationMinutes,
    this.distanceKm,
    this.stops = const [],
    this.agency,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'],
        origin: json['origin'],
        destination: json['destination'],
        durationMinutes: json['duration_minutes'],
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        stops: (json['stops'] as List<dynamic>?)
                ?.map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        agency: json['agency'] != null
            ? AgencyModel.fromJson(json['agency'])
            : null,
      );
}

class TripRequirement {
  final String label;
  final String value;

  TripRequirement({required this.label, required this.value});

  factory TripRequirement.fromJson(Map<String, dynamic> json) => TripRequirement(
        label: json['label'],
        value: json['value'],
      );
}

class TripModel {
  final String id;
  final String routeId;
  final DateTime departureDatetime;
  final DateTime? arrivalDatetime;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final String? busNumber;
  final String status;
  final bool hasWifi;
  final bool hasMeal;
  final bool hasAc;
  final bool hasUsb;
  final List<TripRequirement> requirements;
  final List<String> amenities;
  final RouteModel? route;

  TripModel({
    required this.id,
    required this.routeId,
    required this.departureDatetime,
    this.arrivalDatetime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    this.busNumber,
    required this.status,
    this.hasWifi = false,
    this.hasMeal = false,
    this.hasAc = false,
    this.hasUsb = false,
    this.requirements = const [],
    this.amenities = const [],
    this.route,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        id: json['id'],
        routeId: json['route_id'],
        departureDatetime: DateTime.parse(json['departure_datetime']),
        arrivalDatetime: json['arrival_datetime'] != null
            ? DateTime.parse(json['arrival_datetime'])
            : null,
        totalSeats: json['total_seats'],
        availableSeats: json['available_seats'],
        price: (json['price'] as num).toDouble(),
        busNumber: json['bus_number'],
        status: json['status'],
        hasWifi: json['has_wifi'] ?? false,
        hasMeal: json['has_meal'] ?? false,
        hasAc: json['has_ac'] ?? false,
        hasUsb: json['has_usb'] ?? false,
        requirements: (json['requirements'] as List<dynamic>?)
                ?.map((r) => TripRequirement.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        amenities: (json['amenities'] as List<dynamic>?)
                ?.map((a) => a as String)
                .toList() ??
            const [],
        route: json['route'] != null
            ? RouteModel.fromJson(json['route'])
            : null,
      );
}

class AgencyReview {
  final String id;
  final int rating;
  final String? comment;
  final String customerName;
  final String tripRoute;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  AgencyReview({
    required this.id,
    required this.rating,
    this.comment,
    required this.customerName,
    required this.tripRoute,
    this.reply,
    this.repliedAt,
    required this.createdAt,
  });

  factory AgencyReview.fromJson(Map<String, dynamic> json) => AgencyReview(
        id: json['id'],
        rating: json['rating'],
        comment: json['comment'],
        customerName: json['customer_name'],
        tripRoute: json['trip_route'],
        reply: json['reply'],
        repliedAt: json['replied_at'] != null
            ? DateTime.parse(json['replied_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
      );
}

class AgencyRatingSummary {
  final double? averageRating;
  final int reviewCount;

  const AgencyRatingSummary({this.averageRating, required this.reviewCount});

  factory AgencyRatingSummary.fromJson(Map<String, dynamic> json) =>
      AgencyRatingSummary(
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] ?? 0,
      );

  static const empty = AgencyRatingSummary(reviewCount: 0);
}
