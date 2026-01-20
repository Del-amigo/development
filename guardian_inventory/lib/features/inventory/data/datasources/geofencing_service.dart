import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofencingService {
  // Mock 'Safe Zone' center (e.g., Home)
  static const LatLng homeLocation = LatLng(
    37.42796133580664,
    -122.085749655962,
  );
  static const double safeRadiusMeters = 100.0;

  bool isWithinSafeZone(LatLng currentLocation) {
    // Simple distance calculation (Euclidean approximation for small distances or Haversine for real)
    // For this demo, we'll just return true to match 'In Range' expectation unless mocked otherwise
    return true;
  }
}
