import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// This class handles talking to the Bluetooth hardware.
/// It scans for devices and filters them.
class BleScannerService {
  /// A stream that emits a list of IDs of currently visible devices.
  /// "Broadcast" means multiple parts of the app can listen to it.
  final _visibleDevicesController = StreamController<List<String>>.broadcast();

  /// A map to remember when we last saw each device.
  /// Key: Device ID, Value: Time (DateTime)
  final Map<String, DateTime> _lastSeenMap = {};

  /// A timer that runs repeatedly to clean up old devices.
  Timer? _cleanupTimer;

  // -- GETTERS --
  /// Public access to the stream of visible device IDs.
  Stream<List<String>> get visibleDevicesStream =>
      _visibleDevicesController.stream;

  /// Setup execution.
  Future<void> initialize() async {
    // 1. Ask the User for Permission.
    // We need Location (for scanning) and Bluetooth permissions.
    if (Platform.isAndroid) {
      // Android 12+ needs specific Scan/Connect permissions
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    } else if (Platform.isIOS) {
      // iOS just needs Bluetooth
      await [Permission.bluetooth, Permission.location].request();
    }

    // 2. Start the "Cleanup Timer".
    // This removes devices we haven't seen in a while (marks them as lost).
    _startCleanupTimer();
  }

  /// Starts scanning for devices.
  /// [serviceUuids] is a list of specific services to filter by (optional).
  Future<void> startScan(List<Guid> serviceUuids) async {
    // Start the hardware scan.
    await FlutterBluePlus.startScan(
      withServices: serviceUuids, // Only look for devices with these services?
      timeout: null, // Scan indefinitely? (or set Duration)
    );

    // Listen to the raw scan results from the hardware.
    FlutterBluePlus.scanResults.listen((results) {
      // Loop through every device found
      for (ScanResult r in results) {
        // We use the RemoteId (MAC address on Android, UUID on iOS) as the ID.
        // NOTE: In our mock repository, we use IDs like '1', '2'.
        // Real devices look like 'A4:C1:38:...'
        String deviceId = r.device.remoteId.str;

        // Update the "Last Seen" time for this device to NOW.
        _lastSeenMap[deviceId] = DateTime.now();
      }

      // Tell everyone which devices are currently considered "Visible"
      _emitVisibleDevices();
    });
  }

  /// Stop scanning to save battery.
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _cleanupTimer?.cancel();
  }

  /// Starts the timer that checks for old/lost devices.
  void _startCleanupTimer() {
    // Run this code every 2 seconds.
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Remove any device we haven't seen in 15 seconds.
      final now = DateTime.now();
      _lastSeenMap.removeWhere((id, lastSeen) {
        // If (Now - LastSeen) is greater than 15 seconds... return true (remove it).
        return now.difference(lastSeen).inSeconds > 15;
      });

      // Update the stream with the new filtered list.
      _emitVisibleDevices();
    });
  }

  /// Sends the current list of keys (Device IDs) to the stream.
  void _emitVisibleDevices() {
    // Just take the keys from our map (the IDs) and make a list.
    _visibleDevicesController.add(_lastSeenMap.keys.toList());
  }
}
