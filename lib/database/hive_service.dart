import 'package:hive/hive.dart';
import '../models/movement_model.dart';

class HiveService {
  static const String boxName = "movements";

  static Future<void> addMovement(Movement movement) async {
    var box = await Hive.openBox<Movement>(boxName);
    await box.add(movement);
  }

  static Future<List<Movement>> getMovements() async {
    var box = await Hive.openBox<Movement>(boxName);
    return box.values.toList();
  }

  static Future<void> deleteMovement(int index) async {
    var box = await Hive.openBox<Movement>(boxName);
    await box.deleteAt(index);
  }

  static Future<void> updateMovement(int index, Movement movement) async {
    var box = await Hive.openBox<Movement>(boxName);
    await box.putAt(index, movement);
  }
}