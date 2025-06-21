import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:taketaxi/shared/widgets/custom_toast.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // AnimationController to control the animation
  late AnimationController _animationController;
  // Animation<double> for scaling the logo
  late Animation<double> _scaleAnimation;
  // Animation<double> for fading the logo
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start the animation
    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 1000), () {
      _initializePermissionsAndLocation();
    });
  }

  Future<void> _initializePermissionsAndLocation() async {
    await _requestLocationPermission();
    await _requestNotificationPermission();
    await _saveCurrentLocation();

    if (mounted) {
      context.go('/signin');
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      log("Location permission status: $status. Requesting...");
      status = await Permission.locationWhenInUse.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        log(
          "Location permission denied by user. Guiding to settings if permanently denied.",
        );
        if (mounted) {
          showCustomSnackbar(
            context,
            "Location permission is required to use this app. Please enable it in settings.",
            ToastType.error,
          );
        }
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
      } else {
        log("Location permission granted.");
      }
    } else {
      log("Location permission already granted.");
    }
  }

  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      log("Notification permission status: $status. Requesting...");
      status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        log("Notification permission denied by user.");
        if (mounted) {
          showCustomSnackbar(
            context,
            "Notification permission is recommended for ride updates.",
            ToastType.warning,
          );
        }
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
      } else {
        log("Notification permission granted.");
      }
    } else {
      log("Notification permission already granted.");
    }
  }

  Future<void> _saveCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log("Location services are disabled.");
        if (mounted) {
          showCustomSnackbar(
            context,
            "Location services are disabled. Please enable them.",
            ToastType.error,
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log("Location permission not granted, cannot get current location.");
        return;
      }

      log("Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLatLng = "${position.latitude},${position.longitude}";
      log("Current position obtained: $currentLatLng");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastKnownLocation', currentLatLng);
      log("Location saved to SharedPreferences.");
    } catch (e) {
      log("Error getting and saving location in splash: $e");
      if (mounted) {
        showCustomSnackbar(
          context,
          "Could not get your current location.",
          ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 190,
                      height: 190,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
