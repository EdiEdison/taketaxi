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
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String _currentRideId = '';
  String _driverName = 'N/A';
  String _carModel = 'N/A';
  String _licensePlate = 'N/A';
  String _plateNumber = 'N/A';
  String _badgeNumber = 'N/A';
  String _profile_pic = '';

  LatLng? _driverLocation;
  int _estimatedEtaSeconds = 0;

  Timer? _etaCountdownTimer;

  LatLng? _destinationLatLng;

  String? _selectedPaymentOption;
  String? get selectedPaymentOption => _selectedPaymentOption;
  String get profilePicUrl => _profile_pic;

  String? _selectedCashDenomination;
  String? get selectedCashDenomination => _selectedCashDenomination;
  String get driverName => _driverName;
  String get carModel => _carModel;
  String get licensePlate => _licensePlate;
  String get plateNumber => _plateNumber;
  String get badgeNumber => _badgeNumber;
  double? _estimatedFare = 0.0;
  double? get estimatedFare => _estimatedFare;

  bool _isCalculatingFare = false;
  bool get isCalculatingFare => _isCalculatingFare;

  double _sheetChildSize = 0.28;
  double get sheetChildSize => _sheetChildSize;

  Timer? _arrivalCountdownTimer;
  Timer? _taxiMovementTimer;
  int _remainingTimeInSeconds = 0;
  final int _initialSimulatedArrivalTime = 60;
  final int _movementUpdateIntervalMs = 500;

  BitmapDescriptor? _customTaxiIcon;

  static const String _googleApiKey = "AIzaSyBpxYpVUtQlXjQgBCJNDvLkADlgTQ9IbLs";
  final SupabaseClient _supabaseClient = Supabase.instance.client;

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

  bool get taxiArrived => _taxiArrived;
  PaymentMode _currentPaymentMode = PaymentMode.momo;
  PaymentMode get currentPaymentMode => _currentPaymentMode;

  LatLng? get destinationLatLng => _destinationLatLng;

  String get formattedRemainingTime {
    int minutes = _remainingTimeInSeconds ~/ 60;
    int seconds = _remainingTimeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  StreamSubscription<SupabaseStreamEvent>? _rideSubscription;

  // Fare calculation constants (based on Cameroon rates)
  static const double baseFare = 500.0; // Minimum fare
  static const double perKmRate = 16.0; // Government rate per km
  static const double perMinuteRate = 10.0; // For traffic considerations
  static const double nightSurcharge = 1.2; // 20% extra at night
  static const double peakHourMultiplier = 1.15; // 15% extra during peak hours

  void setEstimatedFare(double fare) {
    _estimatedFare = fare;
    notifyListeners();
  }

  Future<void> calculateEstimatedFare() async {
    if (_currentPosition == null || _destinationLatLng == null) {
      _estimatedFare = null;
      _isCalculatingFare = true;
      notifyListeners();
      return;
    }
    try {
      // Calculate distance in km
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude,
      );

      double distanceKm = distanceInMeters / 1000;

      distanceKm = distanceKm < 0.1 ? 0.1 : distanceKm;

      // Calculate estimated time (assuming average speed of 30km/h in city)
      double estimatedMinutes = (distanceKm / 30) * 60;

      // Base fare calculation
      double fare =
          baseFare +
          (distanceKm * perKmRate) +
          (estimatedMinutes * perMinuteRate);

      // Apply time-based adjustments
      final now = DateTime.now();
      final isNightTime = now.hour >= 20 || now.hour < 6;
      final isPeakHour =
          (now.hour >= 7 && now.hour <= 9) ||
          (now.hour >= 16 && now.hour <= 19);

      if (isNightTime) {
        fare *= nightSurcharge;
      } else if (isPeakHour) {
        fare *= peakHourMultiplier;
      }

      _estimatedFare = (fare / 50).round() * 50.0;
      log("Estimated fare : $_estimatedFare ");
    } catch (e) {
      _estimatedFare = null;
      log("Error calculating fare: $e");
    } finally {
      _isCalculatingFare = false;
      notifyListeners();
    }
    notifyListeners();
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

      // Calculate estimated fare based on distance
      await calculateEstimatedFare();

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

  // void cancelPendingRide(BuildContext context) {
  //   _driverFoundPendingConfirmation = false;
  //   _isRequestingRide = false;
  //   _rideFound = false;
  //   resetRideState();
  //   notifyListeners();
  //   showCustomSnackbar(context, "Ride request cancelled.", ToastType.info);
  //   log("Pending ride cancelled by user.");
  // }

  // void confirmRide(BuildContext context) {
  //   print("Ride Confirmed by user!");
  //   _driverFoundPendingConfirmation = false;
  //   _rideFound = true;
  //   notifyListeners();
  //   if (_currentPosition != null) {
  //     _remainingTimeInSeconds = _initialSimulatedArrivalTime;
  //     _startArrivalCountdown(context);
  //     _startTaxiMovementSimulation();
  //     addActivityOnRouteDrawn(
  //       context,
  //       _destinationController.text,
  //       _estimatedFare ?? 0.0,
  //     );
  //   }
  // }

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
    log("Attempting to send ride request to Supabase...");

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      showCustomSnackbar(
        context,
        "You must be logged in to request a ride.",
        ToastType.error,
      );
      log("Error: User not authenticated.");
      return;
    }

    if (_currentPosition == null ||
        _destinationLatLng == null ||
        _estimatedFare == null ||
        _currentPaymentMode == null) {
      log("Error: Missing crucial ride details.");
      return;
    }

    if (_currentPaymentMode == PaymentMode.directCash &&
        (_selectedCashDenomination == null ||
            _selectedCashDenomination!.isEmpty)) {
      log("Error: Cash denomination missing for direct cash.");
      return;
    }

    _isRequestingRide = true;
    _driverFoundPendingConfirmation = false;
    _rideFound = false;
    _taxiArrived = false;
    _markers.clear();
    _polylines.clear();
    _etaCountdownTimer?.cancel(); // Cancel any previous timers
    _estimatedEtaSeconds = 0; // Reset ETA display

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
        markerId: const MarkerId("destination"),
        position: _destinationLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: _destinationController.text),
      ),
    );

    if (_mapController != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _destinationLatLng!.latitude
              ? _currentPosition!.latitude
              : _destinationLatLng!.latitude,
          _currentPosition!.longitude < _destinationLatLng!.longitude
              ? _currentPosition!.longitude
              : _destinationLatLng!.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _destinationLatLng!.latitude
              ? _currentPosition!.latitude
              : _destinationLatLng!.latitude,
          _currentPosition!.longitude > _destinationLatLng!.longitude
              ? _currentPosition!.longitude
              : _destinationLatLng!.longitude,
        ),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }

    notifyListeners(); // Update UI to show "Looking for a ride..."

    try {
      final response =
          await _supabaseClient.from('rides').insert({
            'passenger_id': currentUser.id,
            'pickup_location':
                'POINT(${_currentPosition!.longitude} ${_currentPosition!.latitude})',
            'destination_location':
                'POINT(${_destinationLatLng!.longitude} ${_destinationLatLng!.latitude})',
            'payment_method': _currentPaymentMode!.toString().split('.').last,
            'price': _estimatedFare!,
            'status': 'pending', // Initial status
          }).select();

      if (response.isNotEmpty) {
        _currentRideId = response.first['id'] as String;
        log("Ride request successfully sent, ID: $_currentRideId");
        showCustomSnackbar(
          context,
          "Ride requested successfully! Looking for a driver...",
          ToastType.success,
        );

        _listenForRideUpdates(context);
      } else {
        log("Supabase insert did not return a response or was empty.");
        showCustomSnackbar(
          context,
          "Failed to register ride request.",
          ToastType.error,
        );
        _isRequestingRide = false; // Reset state on failure
      }
    } on PostgrestException catch (e) {
      log("Supabase Postgrest Error during ride request: ${e.message}");
      showCustomSnackbar(
        context,
        "Failed to register ride request: ${e.message}",
        ToastType.error,
      );
      _isRequestingRide = false; // Reset state on failure
    } catch (e) {
      log("General Error during ride request: $e");
      showCustomSnackbar(
        context,
        "An unexpected error occurred during ride request.",
        ToastType.error,
      );
      _isRequestingRide = false;
    } finally {}
  }

  void _listenForRideUpdates(BuildContext context) {
    if (_currentRideId.isEmpty) {
      log("No current ride ID to listen for updates.");
      return;
    }

    _rideSubscription?.cancel();

    _rideSubscription = _supabaseClient
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', _currentRideId) // Filter for the current ride
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) {
              final rideData = data.first;
              log("Realtime ride update received: $rideData");

              final String newStatus = rideData['status'] as String;
              final int? newEta = rideData['estimated_eta'] as int?;
              final String? driverId =
                  rideData['driver_id'] as String?; // Get driver ID

              if (newEta != null && newEta >= 0) {
                _estimatedEtaSeconds = newEta;
                _startEtaCountdown(); // Restart or update countdown
              }

              if (newStatus == 'accepted' && driverId != null) {
                _isRequestingRide = false; // No longer just "looking"
                _driverFoundPendingConfirmation = true;
                _fetchDriverDetails(
                  driverId,
                ); // New function to get driver info
                showCustomSnackbar(
                  context,
                  "A driver has accepted your ride! Please confirm.",
                  ToastType.info,
                );
              } else if (newStatus == 'confirmed') {
                _driverFoundPendingConfirmation =
                    false; // No longer pending confirmation
                _rideFound = true; // Ride is confirmed and ongoing
                _taxiArrived = false; // Not yet arrived
                showCustomSnackbar(
                  context,
                  "Your ride is confirmed! Driver is on the way.",
                  ToastType.success,
                );
                // You might start real-time driver location updates here
                // This would replace your simulated taxi movement
                // For now, let's just make sure the ETA countdown starts if provided
                if (newEta != null && newEta > 0) {
                  _estimatedEtaSeconds = newEta;
                  _startEtaCountdown();
                }
              } else if (newStatus == 'arrived') {
                _rideFound = true;
                _taxiArrived = true; // Driver has arrived
                _etaCountdownTimer?.cancel(); // Stop ETA countdown
                _estimatedEtaSeconds = 0; // Reset ETA
                showCustomSnackbar(
                  context,
                  "Your taxi has arrived!",
                  ToastType.info,
                );
              } else if (newStatus == 'completed') {
                _rideFound = false;
                _taxiArrived = false;
                _isRequestingRide = false;
                _driverFoundPendingConfirmation = false;
                _etaCountdownTimer?.cancel();
                showCustomSnackbar(
                  context,
                  "Ride completed! Thank you.",
                  ToastType.success,
                );
                // Navigate to rating screen or reset UI
              } else if (newStatus == 'cancelled') {
                _rideFound = false;
                _taxiArrived = false;
                _isRequestingRide = false;
                _driverFoundPendingConfirmation = false;
                _etaCountdownTimer?.cancel();
                showCustomSnackbar(
                  context,
                  "Ride cancelled by driver or system.",
                  ToastType.error,
                );
              }
              notifyListeners();
            }
          },
          onError: (error) {
            log("Error in ride subscription: $error");
            showCustomSnackbar(
              context,
              "Lost connection to ride updates. Please check your internet.",
              ToastType.error,
            );
            _isRequestingRide = false;
            notifyListeners();
          },
        );
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    try {
      final response =
          await _supabaseClient
              .from('users') // Assuming 'users' table stores driver profiles
              .select('name, plate_number, badge_number, profile_pic_url')
              .eq('id', driverId)
              .single(); // Expecting one driver

      if (response != null) {
        log("Response: $response");
        _driverName = response['name'] ?? 'Unknown Driver';
        _plateNumber = response['plate_number'] ?? 'N/A';
        _badgeNumber = response['badge_number'] ?? 'N/A';
        _profile_pic = response['profile_pic_url'] ?? 'N/A';
        notifyListeners();
      }
    } catch (e) {
      log("Error fetching driver details: $e");
      _driverName = 'Error';
      _carModel = 'Error';
      _licensePlate = 'Error';
      notifyListeners();
    }
  }

  Future<void> confirmRide(BuildContext context) async {
    if (_currentRideId.isEmpty) {
      log("No current ride ID to confirm.");
      showCustomSnackbar(
        context,
        "No active ride to confirm.",
        ToastType.error,
      );
      return;
    }

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      showCustomSnackbar(
        context,
        "You must be logged in to confirm ride.",
        ToastType.error,
      );
      return;
    }

    try {
      log("Confirming ride $_currentRideId");

      final response = await _supabaseClient.rpc(
        'confirm_ride_by_passenger',
        params: {'ride_id': _currentRideId, 'passenger_id': currentUser.id},
      );

      log("Confirm ride response: $response");

      if (response == true) {
        log("Ride $_currentRideId successfully confirmed.");
        showCustomSnackbar(
          context,
          "Ride confirmed! Your driver is on the way.",
          ToastType.success,
        );

        // Update local state
        _driverFoundPendingConfirmation = false;
        _rideFound = true;

        if (_currentPosition != null && _destinationLatLng != null) {
          await _drawRouteToDestination(
            context,
            _currentPosition!,
            _destinationLatLng!,
          );

          // Optionally zoom to fit the route
          if (_isMapControllerInitialized && _mapController != null) {
            final bounds = _boundsFromLatLngList(_polylines.first.points);
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 100),
            );
          }
        }
        notifyListeners();
      } else {
        log("Failed to confirm ride $_currentRideId");
        showCustomSnackbar(
          context,
          "Failed to confirm ride. It may have been cancelled.",
          ToastType.error,
        );

        // Reset state
        resetRideState();
        ();
      }
    } on PostgrestException catch (e) {
      log("Error confirming ride: ${e.message}");
      showCustomSnackbar(
        context,
        "Failed to confirm ride: ${e.message}",
        ToastType.error,
      );
    } catch (e) {
      log("Unexpected error confirming ride: $e");
      showCustomSnackbar(
        context,
        "An unexpected error occurred.",
        ToastType.error,
      );
    }
  }

  Future<void> cancelPendingRide(BuildContext context) async {
    if (_currentRideId.isEmpty) {
      log("No current ride ID to cancel.");
      showCustomSnackbar(context, "No active ride to cancel.", ToastType.error);
      return;
    }

    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      showCustomSnackbar(
        context,
        "You must be logged in to cancel ride.",
        ToastType.error,
      );
      return;
    }

    try {
      log("Cancelling ride $_currentRideId");

      final response = await _supabaseClient.rpc(
        'cancel_ride_by_passenger',
        params: {'ride_id': _currentRideId, 'passenger_id': currentUser.id},
      );

      log("Cancel ride response: $response");

      if (response == true) {
        log("Ride $_currentRideId successfully cancelled.");
        showCustomSnackbar(
          context,
          "Ride cancelled successfully.",
          ToastType.info,
        );

        // Reset all ride-related state
        resetRideState();
      } else {
        log("Failed to cancel ride $_currentRideId");
        showCustomSnackbar(
          context,
          "Failed to cancel ride. It may have already been processed.",
          ToastType.error,
        );
      }
    } on PostgrestException catch (e) {
      log("Error cancelling ride: ${e.message}");
      showCustomSnackbar(
        context,
        "Failed to cancel ride: ${e.message}",
        ToastType.error,
      );
    } catch (e) {
      log("Unexpected error cancelling ride: $e");
      showCustomSnackbar(
        context,
        "An unexpected error occurred.",
        ToastType.error,
      );
    }
  }

  void _startEtaCountdown() {
    _etaCountdownTimer?.cancel(); // Cancel any existing timer
    if (_estimatedEtaSeconds > 0) {
      _etaCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_estimatedEtaSeconds > 0) {
          _estimatedEtaSeconds--;
        } else {
          timer.cancel();
        }
        notifyListeners(); // Update UI every second
      });
    }
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
