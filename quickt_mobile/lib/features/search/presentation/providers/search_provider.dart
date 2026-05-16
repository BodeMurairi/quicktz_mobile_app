import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip_model.dart';
import '../../data/repositories/trip_repository.dart';

class SearchState {
  final List<TripModel> results;
  final List<TripModel> upcoming;
  final List<AgencyModel> agencies;
  final bool isLoading;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.results = const [],
    this.upcoming = const [],
    this.agencies = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    List<TripModel>? results,
    List<TripModel>? upcoming,
    List<AgencyModel>? agencies,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) =>
      SearchState(
        results: results ?? this.results,
        upcoming: upcoming ?? this.upcoming,
        agencies: agencies ?? this.agencies,
        isLoading: isLoading ?? this.isLoading,
        isSearching: isSearching ?? this.isSearching,
        error: error,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final TripRepository _repo;

  SearchNotifier(this._repo) : super(const SearchState()) {
    loadHome();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);
    try {
      final upcoming = await _repo.getUpcomingTrips();
      final agencies = await _repo.getAgencies();
      state = state.copyWith(upcoming: upcoming, agencies: agencies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search({
    required String origin,
    required String destination,
    required String departureDate,
    int passengers = 1,
  }) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await _repo.searchTrips(
        origin: origin,
        destination: destination,
        departureDate: departureDate,
        passengers: passengers,
      );
      state = state.copyWith(results: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: 'Search failed. Please try again.');
    }
  }

  void clearResults() => state = state.copyWith(results: []);
}

final tripRepositoryProvider = Provider((_) => TripRepository());
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref.read(tripRepositoryProvider)),
);
