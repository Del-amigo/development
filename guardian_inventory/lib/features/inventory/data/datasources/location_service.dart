import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This class is responsible for anything related to GPS and Locations.
class LocationService {
  // Keys to save/load address from storage
  static const String _homeLatKey = 'home_lat';
  static const String _homeLngKey = 'home_lng';

  /// SAVES the current location as "Home" in the phone's storage.
  Future<void> setHomeLocation(double latitude, double longitude) async {
    // Get storage access
    final prefs = await SharedPreferences.getInstance();
    // Save numbers
    await prefs.setDouble(_homeLatKey, latitude);
    await prefs.setDouble(_homeLngKey, longitude);
  }

  /// LOADS the "Home" location from storage.
  /// Returns a 'Position' object if found, or 'null' if not set.
  Future<Position?> getHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_homeLatKey);
    final lng = prefs.getDouble(_homeLngKey);

    // If both latitude and longitude were saved...
    if (lat != null && lng != null) {
      // ... Create a Position object to return.
      // (We fill in 0s for data we don't have stored, like speed/altitude)
      return Position(
        longitude: lng,
        latitude: lat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    // Storage was empty
    return null;
  }

  /// MATH: Helper to calculate distance (in meters) between two points.
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // Uses the Geolocator library to do the complex math.
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// ASKS user for permission to use GPS.
  /// Returns true if granted, false if denied.
  Future<bool> requestPermission() async {
    // Check current status
    LocationPermission permission = await Geolocator.checkPermission();

    // If denied, Ask the user nicely.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // Still denied? Return false.
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // If they said "Never ask again", we can't do anything.
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Success!
    return true;
  }

  /// Gets the phone's current GPS position right now.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high, // Try to be as precise as possible
    );
  }
}
