import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taketaxi/features/activity/activity_screen.dart';
import 'package:taketaxi/features/auth/screens/complete_profile.dart';
import 'package:taketaxi/features/auth/screens/signin.dart';
import 'package:taketaxi/features/auth/screens/verify_phone.dart';
import 'package:taketaxi/features/home/placesapi/places_api_google.dart';
import 'package:taketaxi/features/home/screens/request_ride_screen.dart';
import 'package:taketaxi/features/notifications/screens/notification_screen.dart';
import 'package:taketaxi/features/profile/screens/profile_screen.dart';
import 'package:taketaxi/main_app_shell.dart';
import 'package:taketaxi/shared/widgets/splash_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'splash',
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: 'signin',
      path: '/signin',
      builder: (context, state) => const SignIn(),
    ),
    GoRoute(
      name: 'verifyphone',
      path: '/verifyphone',
      builder: (context, state) {
        final phoneNumber = state.extra as String?;
        return EnterCodeScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      name: 'complete_profile',
      path: '/complete_profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainAppShell(child: child);
      },
      routes: [
        GoRoute(
          name: 'home_tab',
          path: '/main/home',
          builder: (context, state) => const RequestRideScreen(),
          routes: [
            GoRoute(
              name: 'location_search',
              path: 'location',
              builder: (context, state) {
                final Function(String)? onLocationSelected =
                    state.extra as Function(String)?;
                if (onLocationSelected != null) {
                  return PlacesApiGoogleMapSearch(
                    onLocationSelected: onLocationSelected,
                  );
                }
                return const Text('Error: Callback not provided');
              },
            ),
            GoRoute(
              name: 'notifications',
              path: 'notifications',
              builder: (BuildContext context, GoRouterState state) {
                return const NotificationsScreen();
              },
            ),
          ],
        ),
        GoRoute(
          name: 'activity_tab',
          path: '/main/activity',
          builder: (context, state) => const ActivityScreen(),
        ),
        GoRoute(
          name: 'profile_tab',
          path: '/main/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfileScreen();
          },
        ),
      ],
    ),
  ],
);
