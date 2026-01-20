import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/datasources/location_service.dart';

/// Use this page to select your "Home" location on a map.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Helper to get location data
  final LocationService _locationService = LocationService();

  // Controls the visible map area
  GoogleMapController? _mapController;

  // The Red Pin on the map
  Marker? _homeMarker;

  // Where the map starts looking (default: Google HQ)
  LatLng _initialPosition = const LatLng(37.42796133580664, -122.085749655962);

  // Are we currently fetching data?
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load existing home location when page opens
    _loadHomeLocation();
  }

  /// Logic to find where to center the map.
  Future<void> _loadHomeLocation() async {
    // 1. Try to get saved home location from storage
    final homePos = await _locationService.getHomeLocation();
    LatLng? target;

    if (homePos != null) {
      // Use saved home
      target = LatLng(homePos.latitude, homePos.longitude);
      _setMarker(target);
    } else {
      // 2. If no saved home, try to get current GPS location
      final hasPermission = await _locationService.requestPermission();
      if (hasPermission) {
        try {
          final currentPos = await _locationService.getCurrentPosition();
          target = LatLng(currentPos.latitude, currentPos.longitude);
        } catch (e) {
          // If error, just stay on default
        }
      }
    }

    // Update the UI
    if (target != null) {
      setState(() {
        _initialPosition = target!;
        _isLoading = false; // Done loading
      });
    } else {
      setState(() {
        _isLoading = false; // Done loading (using default)
      });
    }
  }

  /// Places the red pin on the map at [position].
  void _setMarker(LatLng position) {
    setState(() {
      _homeMarker = Marker(
        markerId: const MarkerId('home'),
        position: position,
        infoWindow: const InfoWindow(title: 'Home Location'),
      );
    });
  }

  /// Saves the pin's location to the phone storage.
  Future<void> _saveHomeLocation() async {
    if (_homeMarker != null) {
      await _locationService.setHomeLocation(
        _homeMarker!.position.latitude,
        _homeMarker!.position.longitude,
      );

      // Check if the page is still open before showing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home location saved!'),
          ), // Popup message
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location'),
        actions: [
          // Save Button (Disk Icon)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHomeLocation,
          ),
        ],
      ),
      // Show loading spinner OR the Map
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14.4746, // How zoomed in?
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              // When user taps map...
              onTap: (LatLng position) {
                // Move the pin there
                _setMarker(position);
              },
              // Draw the pin
              markers: _homeMarker != null ? {_homeMarker!} : {},
              // Show blue dot for current location
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
