import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_keys.dart';
import 'core/l10n/app_l10n.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/search/presentation/screens/search_results_screen.dart';
import 'features/booking/presentation/screens/trip_detail_screen.dart';
import 'features/booking/presentation/screens/passenger_info_screen.dart';
import 'features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'features/booking/presentation/screens/payment_success_screen.dart';
import 'features/tickets/presentation/screens/my_tickets_screen.dart';
import 'features/tickets/presentation/screens/ticket_detail_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/notifications/presentation/screens/notification_detail_screen.dart';
import 'features/notifications/data/models/notification_model.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/agency/presentation/screens/agency_screen.dart';
import 'features/trip_planner/presentation/screens/trip_planner_screen.dart';
import 'features/chat/presentation/screens/chatbot_screen.dart';
import 'features/messages/presentation/screens/conversations_screen.dart';
import 'features/messages/presentation/screens/conversation_thread_screen.dart';
import 'features/messages/presentation/widgets/message_watcher.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'shared/widgets/app_drawer.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) =>
          ResetPasswordScreen(prefillEmail: state.extra as String?),
    ),
    GoRoute(path: '/search-results', builder: (_, _) => const SearchResultsScreen()),
    GoRoute(
      path: '/trip/:id',
      builder: (_, state) => TripDetailScreen(tripId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/passenger-info/:tripId',
      builder: (_, state) =>
          PassengerInfoScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/booking/:tripId',
      builder: (_, state) =>
          BookingConfirmationScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/booking-success/:bookingId',
      builder: (_, state) =>
          PaymentSuccessScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/ticket/:id',
      builder: (_, state) =>
          TicketDetailScreen(ticketId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/trip-planner', builder: (_, _) => const TripPlannerScreen()),
    GoRoute(
      path: '/agency/:id',
      builder: (_, state) =>
          AgencyScreen(agencyId: state.pathParameters['id']!),
    ),
    // Full-screen routes (no bottom nav) — accessible via drawer
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    GoRoute(
      path: '/notification/:id',
      builder: (_, state) => NotificationDetailScreen(
        notificationId: state.pathParameters['id']!,
        notification: state.extra as NotificationModel?,
      ),
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/chat', builder: (_, _) => const ChatbotScreen()),
    GoRoute(path: '/messages', builder: (_, _) => const ConversationsScreen()),
    GoRoute(
      path: '/messages/:id',
      builder: (_, state) => ConversationThreadScreen(
          conversationId: state.pathParameters['id']!),
    ),
    // Shell with 3-item bottom nav
    ShellRoute(
      builder: (_, state, child) =>
          _MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/tickets', builder: (_, _) => const MyTicketsScreen()),
      ],
    ),
  ],
);

// ── Shell ─────────────────────────────────────────────────────────────────────

class _MainShell extends ConsumerWidget {
  final String location;
  final Widget child;
  const _MainShell({required this.location, required this.child});

  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/tickets')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return Scaffold(
      key: appShellKey,
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          const paths = ['/home', '/search', '/tickets'];
          context.go(paths[i]);
        },
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon:
                const Icon(Icons.home_rounded, color: AppColors.primary),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon:
                const Icon(Icons.search_rounded, color: AppColors.primary),
            label: l10n.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(Icons.confirmation_number_rounded,
                color: AppColors.primary),
            label: l10n.tickets,
          ),
        ],
      ),
    );
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

class QuickTZApp extends ConsumerWidget {
  const QuickTZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'QuickTZ',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: _router,
      builder: (context, child) =>
          MessageWatcher(child: child ?? const SizedBox.shrink()),
      locale: Locale(lang),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11);
            }
            return const TextStyle(color: AppColors.grey, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.grey);
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
