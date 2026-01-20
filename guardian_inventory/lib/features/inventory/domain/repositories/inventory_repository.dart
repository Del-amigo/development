import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getWatchedItems();
  Stream<List<InventoryItem>> get itemsStream;
  Future<void> updateItemStatus(
    String id,
    ItemStatus status, {
    double? distance,
  });

  Future<void> toggleEssentialStatus(String id);
}
