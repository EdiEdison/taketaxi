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

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Duration of the animation
    );

    // Initialize scale animation: Goes from 0.5 to 1.0
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // A cool easing curve
      ),
    );

    // Initialize fade animation: Goes from 0.0 (transparent) to 1.0 (opaque)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn, // A different easing curve for fade
      ),
    );

    // Start the animation
    _animationController.forward();

    // Start the permission and location process after a slight delay
    // to allow the animation to play a bit
    Future.delayed(const Duration(milliseconds: 1000), () {
      _initializePermissionsAndLocation();
    });
  }

  Future<void> _initializePermissionsAndLocation() async {
    // You might want to show a loading indicator or text below the logo
    // while these operations are ongoing. For now, the CircularProgressIndicator
    // will serve this purpose implicitly.

    await _requestLocationPermission();
    await _requestNotificationPermission();
    await _saveCurrentLocation();

    // After all checks, navigate to the next screen.
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
    _animationController
        .dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use AnimatedBuilder to rebuild the widget as the animation value changes
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation, // Apply fade animation
                  child: ScaleTransition(
                    scale: _scaleAnimation, // Apply scale animation
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 190,
                      height: 190,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text("Initializing app..."),
          ],
        ),
      ),
    );
  }
}
