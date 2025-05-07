import 'package:go_router/go_router.dart';
import 'package:taketaxi/features/home/screens/home_screen.dart';
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
      name: 'home',
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
