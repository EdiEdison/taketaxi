import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taketaxi/core/utils/helpers.dart';
import 'package:taketaxi/features/activity/model/activity_model.dart';

class ActivityController extends ChangeNotifier {
  final List<Activity> _activities = [];
  List<Activity> get activities => List.unmodifiable(_activities);
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  bool _isLoadingActivities = false; // New loading state
  bool get isLoadingActivities => _isLoadingActivities;

  void addActivity(Activity activity) {
    _activities.insert(0, activity);
    notifyListeners();
  }

  Future<void> loadActivities() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      log("User not logged in. Cannot load activities.");
      clearActivities();
      return;
    }

    _isLoadingActivities = true;
    notifyListeners(); // Notify UI that loading has started

    try {
      _activities.clear(); // Clear existing activities before loading new ones

      final List<Map<String, dynamic>> response = await _supabaseClient
          .from('rides')
          .select('''
            id,
            pickup_location,
            destination_location,
            price,
            payment_method,
            status,
            created_at,
            completed_at,
            driver_id,
            users!rides_driver_id_fkey(full_name, car_model, license_plate)
          ''')
          .eq('passenger_id', currentUser.id)
          .inFilter('status', ['completed', 'cancelled'])
          .order('created_at', ascending: false);

      log("Fetched activities from Supabase: $response");

      for (var rideData in response) {
        Map<String, dynamic>? driverInfo =
            (rideData['users'] is List && rideData['users'].isNotEmpty)
                ? rideData['users'][0]
                : (rideData['users'] is Map ? rideData['users'] : null);

        // --- Extract and convert pickup and destination locations ---
        String? pickupPoint = rideData['pickup_location'];
        String? destinationPoint = rideData['destination_location'];

        String humanReadableDestination = 'Unknown Destination';
        DateTime activityTimestamp = DateTime.parse(
          rideData['created_at'],
        ); // Default to created_at

        // Parse destination location and convert to address
        if (destinationPoint != null &&
            destinationPoint.startsWith('POINT(') &&
            destinationPoint.endsWith(')')) {
          try {
            String coords = destinationPoint.substring(
              6,
              destinationPoint.length - 1,
            );
            List<String> parts = coords.split(' ');
            if (parts.length == 2) {
              double lng = double.parse(parts[0]);
              double lat = double.parse(parts[1]);
              Placemark? placemark = await Helpers.coordinatesToAddress(
                lat,
                lng,
              );
              if (placemark != null) {
                humanReadableDestination =
                    "${placemark.street}, ${placemark.locality ?? placemark.subLocality ?? ''}";
                if (humanReadableDestination.isEmpty ||
                    humanReadableDestination == ', ') {
                  humanReadableDestination =
                      placemark.name ?? 'Unknown Destination';
                }
              }
            }
          } catch (e) {
            log("Error parsing destination_location for address: $e");
          }
        }

        // Use completed_at if available, otherwise created_at for the activity timestamp
        if (rideData['completed_at'] != null) {
          activityTimestamp = DateTime.parse(rideData['completed_at']);
        }

        _activities.add(
          Activity(
            id: rideData['id'],
            destination: humanReadableDestination,
            timestamp: activityTimestamp,
            driverName: driverInfo?['full_name'] ?? 'No Driver Assigned',
            carModel: driverInfo?['car_model'] ?? 'N/A',
            licensePlate: driverInfo?['license_plate'] ?? 'N/A',
            estimatedFare: (rideData['price'] as num?)?.toDouble() ?? 0.0,
            paymentMethodDetails: rideData['payment_method'] ?? 'N/A',
          ),
        );
      }
    } on PostgrestException catch (e) {
      log("Error loading activities from Supabase: ${e.message}");
      // Show snackbar or toast
    } catch (e) {
      log("An unexpected error occurred while loading activities: $e");
    } finally {
      _isLoadingActivities = false;
      notifyListeners(); // Notify UI that loading has finished
    }
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }
}
