import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/inventory_item.dart';
import '../domain/repositories/inventory_repository.dart';
import 'datasources/ble_scanner_service.dart';

/// This class acts as the "Brain" for our inventory data.
/// It keeps the list of items, updates their status, and saves important info.
class InventoryRepositoryImpl implements InventoryRepository {
  // A "StreamController" is like a radio station.
  // We broadcast the list of items through it so the UI (HomePage) can listen and update.
  final _controller = StreamController<List<InventoryItem>>.broadcast();

  // Our helper service that actually talks to the Bluetooth hardware.
  final _bleScanner = BleScannerService();

  // Key used to save "Essential Lost" status to phone storage.
  static const String _lostEssentialKey = 'has_lost_essential';

  // --- MOCK DATA (Fake items for testing) ---
  List<InventoryItem> _items = const [
    InventoryItem(
      id: '1', // ID we look for in Bluetooth signal
      name: 'Keys',
      iconAssetPath: 'assets/icons/keys.png',
      status: ItemStatus.unknown, // Initially unknown
      lastKnownDistance: null,
      isEssential: true, // Usually essential!
    ),
    InventoryItem(
      id: '2',
      name: 'Wallet',
      iconAssetPath: 'assets/icons/wallet.png',
      status: ItemStatus.unknown,
      lastKnownDistance: null,
      isEssential: true,
    ),
    InventoryItem(
      id: '3',
      name: 'Passport',
      iconAssetPath: 'assets/icons/passport.png',
      status: ItemStatus.unknown,
      isEssential: false, // Maybe not essential for daily trip?
    ),
  ];

  // Constructor: Runs when this class is created.
  InventoryRepositoryImpl() {
    _initialize();
  }

  /// Setup function.
  Future<void> _initialize() async {
    // 1. Send the initial list of items to the UI immediately.
    _controller.add(_items);

    // 2. Check and save status (in case we restarted app).
    _checkAndPersistEssentialStatus();

    // 3. Turn on the Bluetooth scanner.
    await _bleScanner.initialize();

    // 4. Start listening!
    // "visibleIds" is a list of device IDs currently seen by the phone.
    _bleScanner.visibleDevicesStream.listen((visibleIds) {
      // Whenever the scanner sees new things, run this update logic.
      _updateItemsFromScan(visibleIds);
    });

    // 5. Begin the actual scanning process.
    await _bleScanner.startScan([]);
  }

  /// Updates our item list based on what the Scanner sees.
  void _updateItemsFromScan(List<String> visibleIds) {
    bool changed = false;
    // Create a copy of our list so we can modify it safely.
    final newItems = List<InventoryItem>.from(_items);

    // Loop through every item in our inventory...
    for (int i = 0; i < newItems.length; i++) {
      final item = newItems[i];

      // IS THIS ITEM IN THE VISIBLE LIST?
      if (visibleIds.contains(item.id)) {
        // YES! It's nearby.
        if (item.status != ItemStatus.inRange) {
          // If it wasn't marked "In Range" before, update it now.
          newItems[i] = item.copyWith(
            status: ItemStatus.inRange,
            lastKnownDistance: 1.0, // We pretend it's 1.0m away (Mock)
          );
          changed = true; // Mark that we made a change
        }
      } else {
        // NO. It's not visible right now.
        // If it WAS "In Range" before, we might mark it "Lost" now.
        // Note: The BleScannerService handles the timeout logic (waiting 15s)
        // before removing it from visibleIds.
        if (item.status == ItemStatus.inRange) {
          newItems[i] = item.copyWith(status: ItemStatus.lost);
          changed = true;
        }
      }
    }

    // If we changed anything, create a new broadcast.
    if (changed) {
      _items = newItems; // Update master list
      _controller.add(_items); // Tell UI to redraw

      // Save status to storage (for Background Service)
      _checkAndPersistEssentialStatus();
    }
  }

  /// Checks if any ESSENTIAL item is currently LOST.
  /// Saves "true" or "false" to phone storage so the Background Service can read it.
  Future<void> _checkAndPersistEssentialStatus() async {
    // Check if any item in our list is (Essential AND Lost)
    final strictlyLostEssential = _items.any(
      (item) => item.isEssential && item.status == ItemStatus.lost,
    );

    // Get storage access
    final prefs = await SharedPreferences.getInstance();
    // Save the result
    await prefs.setBool(_lostEssentialKey, strictlyLostEssential);
  }

  /// Get the list of items (used for initial load).
  @override
  Future<List<InventoryItem>> getWatchedItems() async {
    // Fake a small delay to simulate loading from database/internet
    await Future.delayed(const Duration(milliseconds: 500));
    return _items;
  }

  /// The live feed of item updates.
  @override
  Stream<List<InventoryItem>> get itemsStream => _controller.stream;

  /// Update an item manually (e.g. from UI).
  @override
  Future<void> updateItemStatus(
    String id,
    ItemStatus status, {
    double? distance,
  }) async {
    // Find the item by ID
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      // Create updated copy
      final updatedItem = _items[index].copyWith(
        status: status,
        lastKnownDistance: distance,
      );

      // Save it back to list
      final newItems = List<InventoryItem>.from(_items);
      newItems[index] = updatedItem;
      _items = newItems;

      // Broadcast update
      _controller.add(_items);
      _checkAndPersistEssentialStatus();
    }
  }

  /// Toggles whether an item is "Essential" (Star icon).
  @override
  Future<void> toggleEssentialStatus(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      // Flip the boolean value (true -> false, false -> true)
      final updatedItem = item.copyWith(isEssential: !item.isEssential);

      final newItems = List<InventoryItem>.from(_items);
      newItems[index] = updatedItem;
      _items = newItems;

      _controller.add(_items);
      _checkAndPersistEssentialStatus();
    }
  }
}
