import 'package:hive/hive.dart';
import '../models/stock_model.dart';

class StockDatabase {
  static late Box<StockMovement> _stockBox;

  /// Initialize the Hive box
  static Future<void> init() async {
    Hive.registerAdapter(StockMovementAdapter());
    _stockBox = await Hive.openBox<StockMovement>('stockMovements');
  }

  /// Get the next available ID (assuming auto-increment)
  static Future<int> getNextMovementId() async {
    int highestId = 0;
    for (var key in _stockBox.keys) {
      if (key is int && key > highestId) {
        highestId = key;
      }
    }
    return highestId + 1;
  }

  /// Add a new movement
  static Future<void> addMovement(StockMovement movement) async {
    try {
      await _stockBox.put(movement.id, movement); // Use `id` as the key
    } catch (e) {
      print("Error adding movement: $e");
    }
  }

  /// Retrieve all movements
  static List<StockMovement> getMovements() {
    return _stockBox.values.toList();
  }

  /// Get a movement by ID
  static StockMovement? getMovementById(int id) {
    return _stockBox.get(id);
  }

  /// Update a movement by ID
  static Future<void> editMovement(int id, StockMovement updatedMovement) async {
    try {
      if (_stockBox.containsKey(id)) {
        await _stockBox.put(id, updatedMovement);
      }
    } catch (e) {
      print("Error editing movement: $e");
    }
  }

  /// Delete a movement by ID
  static Future<void> deleteMovement(int id) async {
    try {
      await _stockBox.delete(id);
    } catch (e) {
      print("Error deleting movement: $e");
    }
  }
}
