import 'package:go_router/go_router.dart';
import 'package:taketaxi/features/auth/screens/signin.dart';
import 'package:taketaxi/features/auth/screens/verify_phone.dart';
import 'package:taketaxi/features/home/screens/request_ride_screen.dart';
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
      builder: (context, state) => const EnterCodeScreen(),
    ),
    GoRoute(
      name: 'home',
      path: '/home',
      builder: (context, state) => const RequestRideScreen(),
    ),
  ],
);
