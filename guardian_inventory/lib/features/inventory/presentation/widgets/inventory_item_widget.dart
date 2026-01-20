import 'package:flutter/material.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryItemWidget extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleEssential;

  const InventoryItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleEssential,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (item.status) {
      case ItemStatus.inRange:
        statusColor = Colors.green;
        statusText = 'In Range';
        if (item.lastKnownDistance != null) {
          statusText += ' (${item.lastKnownDistance!.toStringAsFixed(1)}m)';
        }
        break;
      case ItemStatus.lost:
        statusColor = Colors.red;
        statusText = 'Lost';
        break;
      case ItemStatus.unknown:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          radius: 24,
          child: Icon(Icons.backpack, color: Theme.of(context).primaryColor),
        ),
        title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleEssential != null)
              IconButton(
                icon: Icon(
                  item.isEssential ? Icons.star : Icons.star_border,
                  color: item.isEssential ? Colors.amber : Colors.grey,
                ),
                onPressed: onToggleEssential,
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
