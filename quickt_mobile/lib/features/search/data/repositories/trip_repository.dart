import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/trip_model.dart';

class TripRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<TripModel>> searchTrips({
    required String origin,
    required String destination,
    required String departureDate,
    int passengers = 1,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.searchTrips,
      queryParameters: {
        'origin': origin,
        'destination': destination,
        'departure_date': departureDate,
        'passengers': passengers,
      },
    );
    return (response.data as List).map((e) => TripModel.fromJson(e)).toList();
  }

  Future<TripModel> getTripDetail(String tripId) async {
    final response = await _dio.get(ApiEndpoints.tripDetail(tripId));
    return TripModel.fromJson(response.data);
  }

  Future<List<TripModel>> getUpcomingTrips() async {
    final response = await _dio.get(ApiEndpoints.trips);
    return (response.data as List).map((e) => TripModel.fromJson(e)).toList();
  }

  Future<List<AgencyModel>> getAgencies() async {
    final response = await _dio.get(ApiEndpoints.agencies);
    return (response.data as List).map((e) => AgencyModel.fromJson(e)).toList();
  }
}
