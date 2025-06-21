import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:taketaxi/features/home/controller/home_controller.dart';
import 'package:taketaxi/features/notifications/controller/notification_controller.dart';
import 'package:taketaxi/features/profile/controller/profile_controller.dart';
import 'package:taketaxi/routes/app_route.dart';
import 'config/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
