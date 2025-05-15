import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taketaxi/core/constants/colors.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isDenied) {
          showCustomSnackbar(
            context,
            "Location permission is required",
            ToastType.error,
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLatLng = LatLng(position.latitude, position.longitude);
      log("Initial position: $currentLatLng");

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
          ),
        );
        _isLoading = false;
      });

      // Animate camera to the initial location if the controller is initialized
      if (_isMapControllerInitialized) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 16.5),
        );
      }
    } catch (e) {
      log("Error getting location: $e");
      showCustomSnackbar(context, "Error getting location", ToastType.error);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(3.8480, 11.5021),
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

          // Bottom UI Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  "Where are you going?",
                  controller: _destinationController,
                  prefixIcon: Icons.search,
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
                    Container(
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
                        children: const [
                          Text("in", style: TextStyle(color: Colors.black87)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
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
                  onPressed: () {
                    // Handle request submission
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
                        "Please enter a price",
                        ToastType.error,
                      );
                      return;
                    }

                    // Process the request
                    // Add your implementation here
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
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                if (_currentPosition != null && _isMapControllerInitialized) {
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 16.5),
                  );
                } else {
                  _getCurrentLocation();
                }
              },
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }
}
