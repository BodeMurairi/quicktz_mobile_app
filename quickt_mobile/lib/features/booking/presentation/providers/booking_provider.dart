import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

class BookingState {
  final List<BookingModel> bookings;
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isBooking;
  final String? error;
  final BookingModel? lastBooking;

  const BookingState({
    this.bookings = const [],
    this.tickets = const [],
    this.isLoading = false,
    this.isBooking = false,
    this.error,
    this.lastBooking,
  });

  BookingState copyWith({
    List<BookingModel>? bookings,
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isBooking,
    String? error,
    BookingModel? lastBooking,
  }) =>
      BookingState(
        bookings: bookings ?? this.bookings,
        tickets: tickets ?? this.tickets,
        isLoading: isLoading ?? this.isLoading,
        isBooking: isBooking ?? this.isBooking,
        error: error,
        lastBooking: lastBooking ?? this.lastBooking,
      );
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRepository _repo;

  BookingNotifier(this._repo) : super(const BookingState());

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final bookings = await _repo.getMyBookings();
      final tickets = await _repo.getMyTickets();
      state = state.copyWith(bookings: bookings, tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<BookingModel?> book({
    required String tripId,
    required String passengerName,
    String? passengerPhone,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isBooking: true, error: null);
    try {
      final booking = await _repo.createBooking(
        tripId: tripId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(
        isBooking: false,
        lastBooking: booking,
        bookings: [booking, ...state.bookings],
      );
      return booking;
    } catch (e) {
      final msg = e.toString();
      String userMsg;
      if (msg.contains('No seats available')) {
        userMsg = 'No seats available on this trip.';
      } else if (msg.contains('401') || msg.contains('Unauthorized')) {
        userMsg = 'Session expired. Please log in again.';
      } else if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        userMsg = 'Cannot reach server. Check your connection.';
      } else {
        userMsg = 'Booking failed: $msg';
      }
      state = state.copyWith(isBooking: false, error: userMsg);
      return null;
    }
  }

  Future<BookingModel?> simulateBook(String tripId) async {
    state = state.copyWith(isBooking: true, error: null);
    try {
      final booking = await _repo.simulateBooking(tripId);
      state = state.copyWith(
        isBooking: false,
        lastBooking: booking,
        bookings: [booking, ...state.bookings],
      );
      return booking;
    } catch (e) {
      state = state.copyWith(isBooking: false, error: 'Simulate failed: ${e.toString()}');
      return null;
    }
  }

  Future<void> cancelBooking(String id) async {
    try {
      final updated = await _repo.cancelBooking(id);
      state = state.copyWith(
        bookings: state.bookings.map((b) => b.id == id ? updated : b).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Could not cancel booking.');
    }
  }
}

final bookingRepositoryProvider = Provider((_) => BookingRepository());
final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>(
  (ref) => BookingNotifier(ref.read(bookingRepositoryProvider)),
);
