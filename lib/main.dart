import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taketaxi/features/activity/controller/activity_controller.dart';
import 'package:taketaxi/features/home/controller/home_controller.dart';
import 'package:taketaxi/features/notifications/controller/notification_controller.dart';
import 'package:taketaxi/features/profile/controller/profile_controller.dart';
import 'package:taketaxi/routes/app_route.dart';
import 'config/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // initializing supabase
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6emtnc2Vrc3F3YWN5cml2b3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MjcxMDcsImV4cCI6MjA2NjQwMzEwN30.IgL_GCRGgvvCstJFZnLHZw1wqx1JNMU_Hqp1rS9_6BQ",
    url: 'https://yzzkgseksqwacyrivoxc.supabase.co',
    debug: true,
  );

  runApp(TakeTaxiApp());
}

class TakeTaxiApp extends StatelessWidget {
  const TakeTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => NotificationsController()),
        ChangeNotifierProvider(create: (_) => ActivityController()),
      ],
      child: MaterialApp.router(
        title: 'TakeTaxi',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
