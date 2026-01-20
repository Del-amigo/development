import 'package:equatable/equatable.dart';

enum ItemStatus { inRange, lost, unknown }

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String iconAssetPath; // Or IconData for simplicity in this demo
  final ItemStatus status;
  final double? lastKnownDistance; // In meters
  final bool isEssential;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.iconAssetPath,
    this.status = ItemStatus.unknown,
    this.lastKnownDistance,
    this.isEssential = false,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? iconAssetPath,
    ItemStatus? status,
    double? lastKnownDistance,
    bool? isEssential,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconAssetPath: iconAssetPath ?? this.iconAssetPath,
      status: status ?? this.status,
      lastKnownDistance: lastKnownDistance ?? this.lastKnownDistance,
      isEssential: isEssential ?? this.isEssential,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconAssetPath,
    status,
    lastKnownDistance,
    isEssential,
  ];
}
