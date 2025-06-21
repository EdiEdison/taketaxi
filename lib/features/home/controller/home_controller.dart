import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/core/utils/helpers.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

enum PaymentMode { momo, orange, directCash }

class HomeController extends ChangeNotifier {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;

  bool _isMapControllerInitialized = false;
  bool _isRequestingRide = false;
  bool _isDrawingRoute = false;

  LatLng? _taxiPosition;
  String? _estimatedArrivalTime;
  LatLng? _taxiStartMovePosition;
  bool _rideFound = false;
  bool _taxiArrived = false;

  LatLng? _destinationLatLng;

  String? _selectedPaymentOption;
  String? get selectedPaymentOption => _selectedPaymentOption;

  String? _selectedCashDenomination;
  String? get selectedCashDenomination => _selectedCashDenomination;

  double? _estimatedFare;
  double? get estimatedFare => _estimatedFare;

  void setEstimatedFare(double fare) {
    _estimatedFare = fare;
    notifyListeners();
  }

  double _sheetChildSize = 0.28;
  double get sheetChildSize => _sheetChildSize;

  Timer? _arrivalCountdownTimer;
  Timer? _taxiMovementTimer;
  int _remainingTimeInSeconds = 0;
  final int _initialSimulatedArrivalTime = 60;
  final int _movementUpdateIntervalMs = 500;

  BitmapDescriptor? _customTaxiIcon;

  static const String _googleApiKey = "AIzaSyBpxYpVUtQlXjQgBCJNDvLkADlgTQ9IbLs";

  GoogleMapController? get mapController => _mapController;
  LatLng? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  TextEditingController get destinationController => _destinationController;
  TextEditingController get amountController => _amountController;
  bool get isLoading => _isLoading;
  bool get isMapControllerInitialized => _isMapControllerInitialized;
  bool get isRequestingRide => _isRequestingRide;
  bool get isDrawingRoute => _isDrawingRoute;
  LatLng? get taxiPosition => _taxiPosition;
  String? get estimatedArrivalTime => _estimatedArrivalTime;
  bool get rideFound => _rideFound;

  String _driverName = "Jean-Pierre";
  String get driverName => _driverName;

  String _carModel = "Toyota Camry";
  String get carModel => _carModel;

  String _licensePlate = "123-ABC-456";
  String get licensePlate => _licensePlate;

  bool get taxiArrived => _taxiArrived;
  PaymentMode _currentPaymentMode = PaymentMode.momo;
  PaymentMode get currentPaymentMode => _currentPaymentMode;

  LatLng? get destinationLatLng => _destinationLatLng;

  String get formattedRemainingTime {
    int minutes = _remainingTimeInSeconds ~/ 60;
    int seconds = _remainingTimeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  HomeController() {
    _loadLocationFromSharedPreferences();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    _mapController?.dispose();
    _arrivalCountdownTimer?.cancel();
    _taxiMovementTimer?.cancel();
    super.dispose();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapControllerInitialized = true;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16.5),
      );
    }
    notifyListeners();
  }

  void updateSelectedPaymentMode(PaymentMode mode) {
    _currentPaymentMode = mode;
    switch (mode) {
      case PaymentMode.momo:
        _selectedPaymentOption = "MoMo";
        _selectedCashDenomination = null;
        break;
      case PaymentMode.orange:
        _selectedPaymentOption = "Orange Money";
        _selectedCashDenomination = null;
        break;
      case PaymentMode.directCash:
        _selectedPaymentOption = "Direct Cash";
        break;
    }
    notifyListeners();
  }

  void selectCashDenomination(String? denomination) {
    _selectedCashDenomination = denomination;
    notifyListeners();
  }

  void onLocationSelected(String selectedLocationAddress) async {
    _destinationController.text = selectedLocationAddress;
    notifyListeners();

    final location = await Helpers.addressToCoordinates(
      selectedLocationAddress,
    );
    if (location != null) {
      _destinationLatLng = LatLng(location.latitude, location.longitude);
      log("Destination LatLng: $_destinationLatLng");
      _markers.add(
        Marker(
          markerId: const MarkerId("destinationLocation"),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Destination",
            snippet: selectedLocationAddress,
          ),
        ),
      );
      notifyListeners();
      if (_isMapControllerInitialized && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_destinationLatLng!, 16.5),
        );
      }
    } else {
      log(
        "Could not convert destination address to coordinates: $selectedLocationAddress",
      );
    }
  }

  void updateSheetSize(double size) {
    _sheetChildSize = size;
    notifyListeners();
  }

  void resetSheetToInitialSize() {
    _sheetChildSize = 0.28;
    notifyListeners();
  }

  void resetRideState() {
    _destinationController.clear();
    _amountController.clear();
    _isRequestingRide = false;
    _rideFound = false;
    _taxiPosition = null;
    _taxiStartMovePosition = null;
    _taxiArrived = false;
    _selectedPaymentOption = "Direct Cash";
    _currentPaymentMode = PaymentMode.directCash;

    _remainingTimeInSeconds = 0;

    _destinationLatLng = null;
    _polylines.clear();
    _isDrawingRoute = false;

    _arrivalCountdownTimer?.cancel();
    _taxiMovementTimer?.cancel();
    _arrivalCountdownTimer = null;
    _taxiMovementTimer = null;

    _markers.clear();
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    }

    notifyListeners();
    log("Ride state reset for new request.");
  }

  void confirmRide() {
    print("Ride Confirmed by user!");
    // Implement actual logic for confirming the ride, e.g., navigate to a ride-in-progress screen
    // For now, let's reset for demonstration
    _markers.clear();
    notifyListeners();
  }

  Future<void> _loadLocationFromSharedPreferences() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedLocation = prefs.getString('lastKnownLocation');

    if (storedLocation != null) {
      try {
        final parts = storedLocation.split(',');
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final LatLng loadedLatLng = LatLng(lat, lng);
        log("Loaded location from SharedPreferences: $loadedLatLng");

        _currentPosition = loadedLatLng;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: loadedLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: "My Location"),
          ),
        );
        _isLoading = false;
        notifyListeners();

        if (_isMapControllerInitialized && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(loadedLatLng, 16.5),
          );
        }
      } catch (e) {
        log("Error parsing stored location: $e");
        getCurrentLocation();
      }
    } else {
      log("No location found in SharedPreferences. Getting current location.");
      getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation({
    bool forceFetch = false,
    BuildContext? context,
  }) async {
    if (forceFetch || _currentPosition == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      var status = await Permission.location.status;
      if (status.isDenied) {
        log("Location permission denied. Requesting again...");
        status = await Permission.location.request();
        if (status.isDenied) {
          log("Location permission still denied after request.");
          if (context != null) {
            showCustomSnackbar(
              context,
              "Location permission is required to get your current location.",
              ToastType.error,
            );
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        log("Location permission permanently denied. Guiding to settings.");
        if (context != null) {
          showCustomSnackbar(
            context,
            "Location permission is permanently denied. Please enable it in app settings.",
            ToastType.error,
          );
        }
        await openAppSettings();
        _isLoading = false;
        notifyListeners();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log("Location services are disabled.");
        if (context != null) {
          showCustomSnackbar(
            context,
            "Location services are disabled. Please enable them.",
            ToastType.error,
          );
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLatLng = LatLng(position.latitude, position.longitude);
      log("Current position fetched: $currentLatLng");

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'lastKnownLocation',
        "${position.latitude},${position.longitude}",
      );
      log("Updated location in SharedPreferences.");

      _currentPosition = currentLatLng;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "My Location"),
          rotation: position.heading,
        ),
      );
      _isLoading = false;
      notifyListeners();

      if (_isMapControllerInitialized && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 16.5),
        );
      }
    } catch (e) {
      log("Error getting location: $e");
      if (context != null) {
        showCustomSnackbar(context, "Error getting location", ToastType.error);
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestRide(BuildContext context) async {
    log("Ride request initiated!");
    String destination = _destinationController.text;

    if (_estimatedFare == null || _estimatedFare! <= 0) {
      log("Error: Fare not estimated. Please try again.");
      _estimatedFare = 400;
      return;
    }

    if (_currentPaymentMode == PaymentMode.directCash) {
      if (_selectedCashDenomination == null ||
          _selectedCashDenomination!.isEmpty) {
        log("Error: Please select your cash denomination or 'Exact Cash'.");
        return;
      }
    } else if (_currentPaymentMode == null) {
      log("Error: Please select a payment method.");
      return;
    }

    if (destination.isEmpty || _destinationLatLng == null) {
      showCustomSnackbar(
        context,
        "Please enter a destination",
        ToastType.error,
      );
      return;
    }

    if (_currentPosition == null) {
      showCustomSnackbar(
        context,
        "Unable to get your current location. Please ensure location services are enabled.",
        ToastType.error,
      );
      return;
    }

    _isRequestingRide = true;
    _rideFound = false;
    _taxiArrived = false;
    _polylines.clear();
    _arrivalCountdownTimer?.cancel();
    _taxiMovementTimer?.cancel();
    _remainingTimeInSeconds = 0;

    _markers.clear();

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    }

    notifyListeners();

    if (_isMapControllerInitialized &&
        _mapController != null &&
        _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    }

    updateSheetSize(0.12);

    await Future.delayed(const Duration(seconds: 3));

    _isRequestingRide = false;

    try {
      _customTaxiIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/taxi_medium.png',
      );
    } catch (e) {
      log("Error loading custom taxi icon: $e");
      _customTaxiIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      );
    }

    if (_currentPosition != null) {
      _taxiPosition = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude + 0.0008,
      );
      _taxiStartMovePosition = _taxiPosition;

      _markers.clear();

      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId("taxiLocation"),
          position: _taxiPosition!,
          icon: _customTaxiIcon!,
          infoWindow: const InfoWindow(title: "Your Taxi"),
        ),
      );

      _rideFound = true;

      showCustomSnackbar(
        context,
        "Taxi found! Arriving in ${(_initialSimulatedArrivalTime / 60).round()} min",
        ToastType.success,
      );

      // Adjust camera to show user and taxi
      if (_isMapControllerInitialized && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                _currentPosition!.latitude < _taxiPosition!.latitude
                    ? _currentPosition!.latitude
                    : _taxiPosition!.latitude,
                _currentPosition!.longitude < _taxiPosition!.longitude
                    ? _currentPosition!.longitude
                    : _taxiPosition!.longitude,
              ),
              northeast: LatLng(
                _currentPosition!.latitude > _taxiPosition!.latitude
                    ? _currentPosition!.latitude
                    : _taxiPosition!.latitude,
                _currentPosition!.longitude > _taxiPosition!.longitude
                    ? _currentPosition!.longitude
                    : _taxiPosition!.longitude,
              ),
            ),
            100.0,
          ),
        );
      }

      _remainingTimeInSeconds = _initialSimulatedArrivalTime;
      _startArrivalCountdown(context);
      // _startTaxiMovementSimulation(); // Uncomment if you want taxi movement
    } else {
      showCustomSnackbar(
        context,
        "Could not find taxi. Location unavailable.",
        ToastType.error,
      );
    }

    notifyListeners();
  }

  void _startArrivalCountdown(BuildContext context) {
    _arrivalCountdownTimer?.cancel(); // Cancel any existing timer
    _arrivalCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (_remainingTimeInSeconds > 0) {
        _remainingTimeInSeconds--;
        notifyListeners(); // Update UI with new time
      } else {
        _arrivalCountdownTimer?.cancel();
        _taxiMovementTimer?.cancel(); // Stop taxi movement too
        _taxiArrived = true; // Set flag
        notifyListeners(); // Update UI to dismiss timer text
        showCustomSnackbar(
          context,
          "Your taxi has arrived!",
          ToastType.success,
        );

        if (_currentPosition != null && _destinationLatLng != null) {
          _drawRouteToDestination(
            context,
            _currentPosition!,
            _destinationLatLng!,
          );
        } else {
          log(
            "Cannot draw route: currentPosition or destinationLatLng is null.",
          );
        }

        // Optionally, recenter map on user after arrival
        if (_isMapControllerInitialized &&
            _mapController != null &&
            _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 16.5),
          );
        }
      }
    });
  }

  // New: Method to start taxi movement simulation
  void _startTaxiMovementSimulation() {
    _taxiMovementTimer?.cancel(); // Cancel any existing timer

    // Calculate total steps based on total simulated time and update interval
    final int totalSteps =
        (_initialSimulatedArrivalTime * 1000) ~/ _movementUpdateIntervalMs;
    int currentStep = 0;

    _taxiMovementTimer = Timer.periodic(
      Duration(milliseconds: _movementUpdateIntervalMs),
      (timer) {
        if (_taxiArrived || currentStep >= totalSteps) {
          _taxiMovementTimer?.cancel();
          // Ensure taxi is exactly at user location on arrival
          if (_currentPosition != null) {
            _updateTaxiMarkerPosition(_currentPosition!);
          }
          return;
        }

        currentStep++;
        double t = currentStep / totalSteps; // Progress from 0.0 to 1.0

        if (_taxiStartMovePosition != null && _currentPosition != null) {
          // Interpolate the taxi's position
          final newLat =
              _taxiStartMovePosition!.latitude +
              (_currentPosition!.latitude - _taxiStartMovePosition!.latitude) *
                  t;
          final newLng =
              _taxiStartMovePosition!.longitude +
              (_currentPosition!.longitude -
                      _taxiStartMovePosition!.longitude) *
                  t;

          _updateTaxiMarkerPosition(LatLng(newLat, newLng));
        }
      },
    );
  }

  // Helper to update taxi marker position
  void _updateTaxiMarkerPosition(LatLng newPosition) {
    _taxiPosition = newPosition;
    _markers.removeWhere(
      (marker) => marker.markerId == const MarkerId("taxiLocation"),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId("taxiLocation"),
        position: _taxiPosition!,
        icon:
            _customTaxiIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: "Your Taxi"),
      ),
    );
    notifyListeners();
  }

  Future<void> _drawRouteToDestination(
    BuildContext context,
    LatLng origin,
    LatLng destination,
  ) async {
    _isDrawingRoute = true;
    notifyListeners();
    _polylines.clear(); // Clear existing polylines

    log(
      "Drawing route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}",
    );

    try {
      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "&key=$_googleApiKey"
          "&mode=driving"
          "&alternatives=false";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(
            encodedPolyline,
          );

          List<LatLng> polylineCoordinates = [];
          if (result.isNotEmpty) {
            for (var point in result) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          }

          if (polylineCoordinates.isNotEmpty) {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("user_to_destination_route"),
                points: polylineCoordinates,
                color:
                    AppColors.primary, // Or any color you prefer for the route
                width: 5,
                jointType: JointType.round,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
              ),
            );

            // Animate camera to fit the entire route
            if (_isMapControllerInitialized && _mapController != null) {
              LatLngBounds bounds = _boundsFromLatLngList(polylineCoordinates);
              _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 100),
              ); // Padding of 100
            }

            showCustomSnackbar(
              context,
              "Route drawn successfully!",
              ToastType.success,
            );
          } else {
            showCustomSnackbar(
              context,
              "No polyline points found for route.",
              ToastType.info,
            );
          }
        } else {
          String errorMessage =
              data['error_message'] ?? "Could not find a route.";
          showCustomSnackbar(
            context,
            "Route Error: $errorMessage",
            ToastType.error,
          );
          log("Directions API Error: ${data['status']} - $errorMessage");
        }
      } else {
        showCustomSnackbar(
          context,
          "Failed to fetch route. Status: ${response.statusCode}",
          ToastType.error,
        );
        log(
          "Directions API HTTP Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      showCustomSnackbar(context, "Error drawing route: $e", ToastType.error);
      log("Exception in _drawRouteToDestination: $e");
    } finally {
      _isDrawingRoute = false;
      notifyListeners();
    }
  }

  // Helper to calculate LatLngBounds from a list of LatLng points
  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (LatLng point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}
