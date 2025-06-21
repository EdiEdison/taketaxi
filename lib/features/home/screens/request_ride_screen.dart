import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taketaxi/features/home/controller/home_controller.dart';
import 'package:taketaxi/features/home/screens/ride_request_ui.dart';

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(),
      child: const RequestRideScreenUI(),
    );
  }
}
