import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/features/home/controller/home_controller.dart';

class RequestRideScreenUI extends StatelessWidget {
  const RequestRideScreenUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (controller.destinationController.text.isNotEmpty &&
            !controller.isRequestingRide &&
            !controller.rideFound &&
            !controller.driverFoundPendingConfirmation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _requestRide(context, controller);
          });
        }
        return Scaffold(
          body: Stack(
            children: [
              // Google Map
              GoogleMap(
                onMapCreated: controller.onMapCreated,
                initialCameraPosition: CameraPosition(
                  target:
                      controller.currentPosition ??
                      const LatLng(3.8480, 11.5021),
                  zoom: 14,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: controller.markers,
                polylines: controller.polylines,
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    context.push(
                      '/main/home/location',
                      extra: controller.onLocationSelected,
                    );
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
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.destinationController.text.isEmpty
                                ? "Where to?"
                                : controller.destinationController.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color:
                                  controller.destinationController.text.isEmpty
                                      ? AppColors.textMuted
                                      : AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (controller.isRequestingRide)
                Positioned.fill(
                  child: Container(
                    color: AppColors.black.withAlpha((0.6 * 255).toInt()),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Looking for a ride...",
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please wait while we find a taxi for you.",
                            style: GoogleFonts.poppins(
                              color: AppColors.white.withAlpha(
                                (0.8 * 255).toInt(),
                              ),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (controller.rideFound && !controller.taxiArrived)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
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
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
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
                          "Taxi arriving in: ${controller.formattedRemainingTime}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (controller.driverFoundPendingConfirmation &&
                  !controller.rideFound)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).toInt()),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Driver found",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.driverName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${controller.plateNumber} • ${controller.badgeNumber}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (constraints.maxWidth < 400) {
                                          // Use Column for small screens
                                          return Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => controller
                                                          .confirmRide(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        AppColors.black,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Confirm Ride',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.arrow_forward,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => controller
                                                          .cancelPendingRide(
                                                            context,
                                                          ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.error,
                                                    foregroundColor:
                                                        AppColors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Cancel',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.cancel,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          // Use Row for larger screens
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => controller
                                                          .confirmRide(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        AppColors.black,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Confirm Ride',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.arrow_forward,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () => controller
                                                          .cancelPendingRide(
                                                            context,
                                                          ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.error,
                                                    foregroundColor:
                                                        AppColors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Cancel',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.cancel,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  controller.profilePicUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Original rideFound card (now only appears after confirmation)
              if (controller.rideFound &&
                  !controller.driverFoundPendingConfirmation)
                Positioned(
                  bottom: MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).toInt()),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your ride is confirmed!",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width:
                                    200, // Set a fixed width or adjust as needed
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.driverName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${controller.plateNumber} • ${controller.badgeNumber}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // You can add more details or actions for an ongoing ride here
                                    // e.g., "Call Driver", "Message Driver"
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  controller.profilePicUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (controller.taxiArrived)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
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
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Your taxi has arrived!",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestRide(
    BuildContext context,
    HomeController controller,
  ) async {
    // Start ride request
    await controller.requestRide(context);
  }
}
