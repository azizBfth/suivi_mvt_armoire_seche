import 'package:flutter/material.dart';
import '../models/stock_model.dart';

class StockListItem extends StatelessWidget {
  final StockMovement movement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StockListItem({
    Key? key,
    required this.movement,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(movement.productName),
      subtitle: Text('${movement.movementType} - ${movement.storageLocation}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }
}
