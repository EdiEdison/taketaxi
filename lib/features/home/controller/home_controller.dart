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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/core/utils/helpers.dart';
import 'package:taketaxi/features/activity/controller/activity_controller.dart';
import 'package:taketaxi/features/activity/model/activity_model.dart';
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
  bool _driverFoundPendingConfirmation = false;
  bool get driverFoundPendingConfirmation => _driverFoundPendingConfirmation;
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

  // Getters
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

  void addActivityOnRouteDrawn(
    BuildContext context,
    String destination,
    double estimatedFare,
  ) {
    final activityController = Provider.of<ActivityController>(
      context,
      listen: false,
    );

    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      destination: destination,
      timestamp: DateTime.now(),
      driverName: "Jean-Pierre",
      carModel: "Toyota Camry",
      licensePlate: "123-ABC-456",
      estimatedFare: estimatedFare,
      paymentMethodDetails: currentPaymentMode.name,
    );

    activityController.addActivity(activity);
    log("Activity added on route drawn: $destination");
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

  // Enhanced location selection method
  Future<LatLng?> onLocationSelected(String selectedLocationAddress) async {
    _destinationController.text = selectedLocationAddress;
    notifyListeners();

    final location = await Helpers.addressToCoordinates(
      selectedLocationAddress,
    );
    if (location != null) {
      _destinationLatLng = LatLng(location.latitude, location.longitude);
      log("Destination LatLng: $_destinationLatLng");

      // Add destination marker
      _markers.removeWhere(
        (marker) => marker.markerId == const MarkerId("destination"),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Destination",
            snippet: selectedLocationAddress,
          ),
        ),
      );

      // Calculate estimated fare based on distance (optional)
      if (_currentPosition != null) {
        double distanceKm =
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              _destinationLatLng!.latitude,
              _destinationLatLng!.longitude,
            ) /
            1000; // Convert meters to kilometers

        // Simple fare calculation: base fare + distance rate
        double baseFare = 500;
        double ratePerKm = 200;
        _estimatedFare = baseFare + (distanceKm * ratePerKm);

        log(
          "Distance: ${distanceKm.toStringAsFixed(2)} km, Estimated fare: $_estimatedFare CFA",
        );
      }

      notifyListeners();
      return _destinationLatLng;
    } else {
      log(
        "Could not convert destination address to coordinates: $selectedLocationAddress",
      );
      return null;
    }
  }

  void resetRideState() {
    _destinationController.clear();
    _amountController.clear();
    _isRequestingRide = false;
    _rideFound = false;
    _taxiPosition = null;
    _taxiStartMovePosition = null;
    _taxiArrived = false;
    _selectedPaymentOption = null;
    _currentPaymentMode = PaymentMode.momo;
    _selectedCashDenomination = null;

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

  void cancelPendingRide(BuildContext context) {
    _driverFoundPendingConfirmation = false;
    _isRequestingRide = false;
    _rideFound = false;
    resetRideState();
    notifyListeners();
    showCustomSnackbar(context, "Ride request cancelled.", ToastType.info);
    log("Pending ride cancelled by user.");
  }

  void confirmRide(BuildContext context) {
    print("Ride Confirmed by user!");
    _driverFoundPendingConfirmation = false;
    _rideFound = true;
    notifyListeners();
    if (_currentPosition != null) {
      _remainingTimeInSeconds = _initialSimulatedArrivalTime;
      _startArrivalCountdown(context);
      _startTaxiMovementSimulation();
      addActivityOnRouteDrawn(
        context,
        _destinationController.text,
        _estimatedFare ?? 0.0,
      );
    }
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
      log("Destination location needed");
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
    _driverFoundPendingConfirmation = false;
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

    _markers.add(
      Marker(
        markerId: const MarkerId("Destination"),
        position: _destinationLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destinationController.text),
      ),
    );

    notifyListeners();

    if (_isMapControllerInitialized &&
        _mapController != null &&
        _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    }

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

      _driverFoundPendingConfirmation = true;

      //_rideFound = true;

      showCustomSnackbar(
        context,
        "A taxi has been found! Please confirm your ride.",
        ToastType.info,
      );

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
    _arrivalCountdownTimer?.cancel();
    _arrivalCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (_remainingTimeInSeconds > 0) {
        _remainingTimeInSeconds--;
        notifyListeners();
      } else {
        _arrivalCountdownTimer?.cancel();
        _taxiMovementTimer?.cancel();
        _taxiArrived = true;
        notifyListeners();

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

  void _startTaxiMovementSimulation() {
    _taxiMovementTimer?.cancel();

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
    _polylines.clear();

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
                color: AppColors.primary,
                width: 5,
                jointType: JointType.round,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
              ),
            );

            if (_isMapControllerInitialized && _mapController != null) {
              LatLngBounds bounds = _boundsFromLatLngList(polylineCoordinates);
              _mapController!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 100),
              );
            }
          } else {
            log("Something went wrong");
          }
        } else {
          String errorMessage =
              data['error_message'] ?? "Could not find a route.";

          log("Directions API Error: ${data['status']} - $errorMessage");
        }
      } else {
        log(
          "Directions API HTTP Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
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
