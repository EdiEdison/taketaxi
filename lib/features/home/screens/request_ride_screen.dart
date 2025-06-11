import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/features/home/widgets/payment_option_bottom_sheet.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = true;
  bool _isMapControllerInitialized = false;
  bool _isRequestingRide = false;

  LatLng? _taxiPosition;
  String? _estimatedArrivalTime;
  bool _rideFound = false;

  String _selectedPaymentOption = "I have cash";

  @override
  void initState() {
    super.initState();
    _loadLocationFromSharedPreferences();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationFromSharedPreferences() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedLocation = prefs.getString('lastKnownLocation');

    if (storedLocation != null) {
      try {
        final parts = storedLocation.split(',');
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final LatLng loadedLatLng = LatLng(lat, lng);
        log("Loaded location from SharedPreferences: $loadedLatLng");

        setState(() {
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
        });

        if (_isMapControllerInitialized) {
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(loadedLatLng, 16.5),
          );
        }
      } catch (e) {
        log("Error parsing stored location: $e");
        // Fallback to getting current location if parsing fails
        _getCurrentLocation();
      }
    } else {
      log("No location found in SharedPreferences. Getting current location.");
      // If no stored location, try to get it directly
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation({bool forceFetch = false}) async {
    if (forceFetch || _currentPosition == null) {
      setState(() => _isLoading = true);
    }

    try {
      var status = await Permission.location.status;
      if (status.isDenied) {
        log("Location permission denied. Requesting again...");
        status = await Permission.location.request();
        if (status.isDenied) {
          log("Location permission still denied after request.");
          if (mounted) {
            showCustomSnackbar(
              context,
              "Location permission is required to get your current location.",
              ToastType.error,
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        log("Location permission permanently denied. Guiding to settings.");
        if (mounted) {
          showCustomSnackbar(
            context,
            "Location permission is permanently denied. Please enable it in app settings.",
            ToastType.error,
          );
        }
        await openAppSettings();
        setState(() => _isLoading = false);
        return;
      }

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
        setState(() => _isLoading = false);
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

      setState(() {
        _currentPosition = currentLatLng;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: currentLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: "My Location"),
            rotation: position.heading,
          ),
        );
        _isLoading = false;
      });

      if (_isMapControllerInitialized) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 16.5),
        );
      }
    } catch (e) {
      log("Error getting location: $e");
      if (mounted) {
        showCustomSnackbar(context, "Error getting location", ToastType.error);
      }
      setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _isMapControllerInitialized = true;
    if (_currentPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16.5),
      );
    }
  }

  void _showPaymentOptionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PaymentOptionBottomSheet(
          onOptionSelected: (option) {
            setState(() {
              _selectedPaymentOption = option;
            });
          },
        );
      },
    );
  }

  void _onLocationSelected(String selectedLocation) {
    setState(() {
      _destinationController.text = selectedLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  _currentPosition ??
                  const LatLng(
                    3.8480,
                    11.5021,
                  ), // Default to a known location if none
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          if (_rideFound && _estimatedArrivalTime != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Taxi arriving in: $_estimatedArrivalTime",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 40),
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icons/ic_notification.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              "5",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    context.go('/home/location', extra: _onLocationSelected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _destinationController.text.isEmpty
                          ? "Where to?"
                          : _destinationController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _destinationController.text.isEmpty
                                ? AppColors.black
                                : AppColors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "How much are you willing to pay?",
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showPaymentOptionBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedPaymentOption.length > 8
                                  ? "${_selectedPaymentOption.substring(0, 6)}..."
                                  : _selectedPaymentOption,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomRoundedButton(
                  text: "Request",
                  backgroundColor:
                      _destinationController.text.isEmpty ||
                              _priceController.text.isEmpty
                          ? AppColors.buttonDisabled
                          : AppColors.primary,
                  onPressed: () async {
                    String destination = _destinationController.text;
                    String price = _priceController.text;

                    if (destination.isEmpty) {
                      showCustomSnackbar(
                        context,
                        "Please enter a destination",
                        ToastType.error,
                      );
                      return;
                    }

                    if (price.isEmpty) {
                      showCustomSnackbar(
                        context,
                        "Please enter your price",
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

                    setState(() {
                      _isRequestingRide = true;
                      _rideFound = false;
                    });

                    await Future.delayed(const Duration(seconds: 3));

                    BitmapDescriptor? taxiIcon;
                    try {
                      taxiIcon = await BitmapDescriptor.fromAssetImage(
                        const ImageConfiguration(size: Size(12, 12)),
                        'assets/images/taxi_medium.png',
                      );
                    } catch (e) {
                      log("Error loading taxi icon: $e");
                      taxiIcon = BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      );
                    }

                    setState(() {
                      _isRequestingRide = false;
                      if (_currentPosition != null) {
                        _taxiPosition = LatLng(
                          _currentPosition!.latitude +
                              0.003, // approx 333 meters North
                          _currentPosition!.longitude -
                              0.005, // approx 555 meters West
                        );
                        _estimatedArrivalTime = "5 min";

                        _markers.add(
                          Marker(
                            markerId: const MarkerId("taxiLocation"),
                            position: _taxiPosition!,
                            icon: taxiIcon!,
                            infoWindow: const InfoWindow(title: "Your Taxi"),
                          ),
                        );
                        _rideFound = true;
                        showCustomSnackbar(
                          context,
                          "Taxi found! Arriving in $_estimatedArrivalTime",
                          ToastType.success,
                        );

                        if (_isMapControllerInitialized) {
                          mapController.animateCamera(
                            CameraUpdate.newLatLngBounds(
                              LatLngBounds(
                                southwest: LatLng(
                                  _currentPosition!.latitude <
                                          _taxiPosition!.latitude
                                      ? _currentPosition!.latitude
                                      : _taxiPosition!.latitude,
                                  _currentPosition!.longitude <
                                          _taxiPosition!.longitude
                                      ? _currentPosition!.longitude
                                      : _taxiPosition!.longitude,
                                ),
                                northeast: LatLng(
                                  _currentPosition!.latitude >
                                          _taxiPosition!.latitude
                                      ? _currentPosition!.latitude
                                      : _taxiPosition!.latitude,
                                  _currentPosition!.longitude >
                                          _taxiPosition!.longitude
                                      ? _currentPosition!.longitude
                                      : _taxiPosition!.longitude,
                                ),
                              ),
                              100.0,
                            ),
                          );
                        }
                      } else {
                        showCustomSnackbar(
                          context,
                          "Could not find taxi. Location unavailable.",
                          ToastType.error,
                        );
                      }
                    });

                    log(
                      "Destination: $destination, Price: $price, Payment Option: $_selectedPaymentOption",
                    );
                    showCustomSnackbar(
                      context,
                      "Ride requested!",
                      ToastType.success,
                    );
                  },
                ),
              ],
            ),
          ),

          // My location button
          Positioned(
            left: 16,
            bottom: 250,
            child: FloatingActionButton(
              heroTag: "myLocationBtn",
              mini: true,
              backgroundColor: AppColors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                // Force a fresh fetch when the user taps "my location"
                _getCurrentLocation(forceFetch: true);
              },
            ),
          ),
          if (_isRequestingRide)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        "Looking for a ride...",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextEditingController? controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.black),
      ),
    );
  }
}
