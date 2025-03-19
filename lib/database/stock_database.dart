import 'package:hive/hive.dart';
import '../models/stock_model.dart';

class StockDatabase {
  static late Box<StockMovement> _stockBox;

  /// Initialize the Hive box
  static Future<void> init() async {
    Hive.registerAdapter(StockMovementAdapter());
    _stockBox = await Hive.openBox<StockMovement>('stockMovements');
  }

  /// Add a new movement
  static Future<void> addMovement(StockMovement movement) async {
    await _stockBox.put(movement.id, movement); // Use `id` as the key
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
    if (_stockBox.containsKey(id)) {
      await _stockBox.put(id, updatedMovement);
    }
  }

  /// Delete a movement by ID
  static Future<void> deleteMovement(int id) async {
    await _stockBox.delete(id);
  }
}
