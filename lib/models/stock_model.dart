import 'package:hive/hive.dart';

part 'stock_model.g.dart';

@HiveType(typeId: 0)
class StockMovement {
  @HiveField(0)
  final int id; // Primary Key

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String movementType; // 'entrée' ou 'sortie'

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final String storageLocation; // 'armoire 01', 'armoire 02', etc.

  @HiveField(5)
  final int quantity;

  @HiveField(6)
  final String operatorName;

  StockMovement({
    required this.id,
    required this.productName,
    required this.movementType,
    required this.dateTime,
    required this.storageLocation,
    required this.quantity,
    required this.operatorName,
  });
}
