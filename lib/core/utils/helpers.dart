import 'dart:developer';

import 'package:geocoding/geocoding.dart';

class Helpers {
  static Future<Location?> addressToCoordinates(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      log('Error in addressToCoordinates: $e');
      return null;
    }
  }

  /// Converts latitude and longitude to a human-readable address
  static Future<Placemark?> coordinatesToAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      return placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e) {
      print('Error in coordinatesToAddress: $e');
      return null;
    }
  }
}
