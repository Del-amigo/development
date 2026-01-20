import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// This class handles tasks that run even when the app is closed.
/// It's like a security guard that never sleeps, watching your items.
class BackgroundService {
  // Key to save/load "Essential Lost" status from storage.
  static const String _lostEssentialKey = 'has_lost_essential';
  // Keys to save/load "Home" coordinates.
  static const String _homeLatKey = 'home_lat';
  static const String _homeLngKey = 'home_lng';
  // The safety radius around your home (in meters).
  static const double _geofenceRadius = 50.0;

  /// THIS IS THE MAIN SETUP FUNCTION.
  /// It prepares the background service to run.
  Future<void> initialize() async {
    // Create the service object.
    final service = FlutterBackgroundService();

    // Setup a notification channel for Android.
    // This is required to let the user know the app is running in the background.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'guardian_inventory_channel', // Internal ID
      'Guardian Inventory Service', // Name seen by user
      description: 'This channel is used for critical alerts.', // Description
      importance: Importance.high, // High importance = makes sound/pops up
    );

    // Get the tool to show notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Actually create the notification channel on the phone
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configure how the service behaves
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // The function to run when the service starts
        onStart: onStart,

        // Start automatically? Yes.
        autoStart: true,

        // Show in notification tray? Yes.
        isForegroundMode: true,

        // Use the channel we just created
        notificationChannelId: 'guardian_inventory_channel',
        initialNotificationTitle: 'Guardian Inventory',
        initialNotificationContent: 'Monitoring your items...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Kick off the service!
    service.startService();
  }

  /// This function runs when the app is in the background on iOS.
  /// Note: iOS restricts background tasks heavily.
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  /// THIS IS THE WORKHORSE FUNCTION.
  /// It runs when the service starts (on both Android and via workaround on iOS).
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Ensure Flutter engine is ready
    DartPluginRegistrant.ensureInitialized();

    // Create an audio player for our alarm sound
    final player = AudioPlayer();

    // Listen for commands (optional, but good practice)
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // START THE TIMER!
    // Every 15 seconds, run the code inside (timer) { ... }
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      // Update the notification on Android to show we are still alive
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Guardian Inventory",
            content: "Monitoring location for essential items...",
          );
        }
      }

      // Check where we are and if we need to sound the alarm!
      await _checkLocationAndTrigger(player);
    });
  }

  /// Helper function: Checks location and triggers alarm if needed.
  static Future<void> _checkLocationAndTrigger(AudioPlayer player) async {
    // Get access to the phone's storage (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();

    // STEP 1: Check if any "Essential" items are marked as LOST.
    // We read this value from storage (saved by the InventoryRepository).
    final hasLostEssential = prefs.getBool(_lostEssentialKey) ?? false;

    // If everything is safe (nothing lost), stop here. No need to check location.
    if (!hasLostEssential) {
      return;
    }

    // STEP 2: Check if the user has set a "Home" location.
    final homeLat = prefs.getDouble(_homeLatKey);
    final homeLng = prefs.getDouble(_homeLngKey);

    // If no home is set, we can't calculate distance. Stop here.
    if (homeLat == null || homeLng == null) {
      return;
    }

    // STEP 3: Get the user's CURRENT location from GPS.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // We want precise location
      );

      // STEP 4: Calculate distance between CURRENT location and HOME.
      // Result is in meters.
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        homeLat,
        homeLng,
      );

      // STEP 5: Are we too far from home?
      // If distance is greater than our safety radius (50 meters)...
      if (distance > _geofenceRadius) {
        // ... TRIGGER THE ALARM! You left home without your stuff!
        _triggerAlarm(player);
      }
    } catch (e) {
      // If GPS fails, just print the error and try again next time.
      print('Location error: $e');
    }
  }

  /// Helper function: Actually plays sound and shows notification.
  static Future<void> _triggerAlarm(AudioPlayer player) async {
    // Get the notification tool
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Define how the notification looks and sounds on Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'guardian_inventory_alarm', // must match channel ID
          'Critical Alarm',
          channelDescription: 'Alarm for lost essential items',
          importance: Importance.max, // Make it pop up
          priority: Priority.max, // Top priority
          playSound: true, // Play system notification sound
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Show the notification on the screen
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'ESSENTIAL ITEM LOST!', // Title
      'You have left home without an essential item!', // Body
      platformChannelSpecifics,
    );

    // OPTIONAL: Play a continuous alarm sound using AudioPlayer
    // We would need an asset file (like 'assets/alarm.mp3') to do this.
    // For now, the notification sound is simpler and safer to implement.
    // await player.play(AssetSource('sounds/alarm.mp3'));
  }
}
