class AgencyModel {
  final String id;
  final String name;
  final String? logoUrl;
  final bool isVerified;

  AgencyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isVerified = false,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) => AgencyModel(
        id: json['id'],
        name: json['name'],
        logoUrl: json['logo_url'],
        isVerified: json['is_verified'] ?? false,
      );
}

class RouteModel {
  final String id;
  final String origin;
  final String destination;
  final int? durationMinutes;
  final AgencyModel? agency;

  RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    this.durationMinutes,
    this.agency,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'],
        origin: json['origin'],
        destination: json['destination'],
        durationMinutes: json['duration_minutes'],
        agency: json['agency'] != null
            ? AgencyModel.fromJson(json['agency'])
            : null,
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
        route: json['route'] != null
            ? RouteModel.fromJson(json['route'])
            : null,
      );
}
