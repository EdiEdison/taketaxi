import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return MaterialApp.router(
      title: 'TakeTaxi',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
