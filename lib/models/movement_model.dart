import 'package:hive/hive.dart';

part 'movement_model.g.dart';

@HiveType(typeId: 0)
class Movement {
  @HiveField(0)
  int id; // Primary key

  @HiveField(1)
  String productName;

  @HiveField(2)
  String movementType; // 'entrée' ou 'sortie'

  @HiveField(3)
  DateTime movementDate;

  @HiveField(4)
  String storageLocation; // Armoire 01, Armoire 02...

  @HiveField(5)
  int quantity;

  @HiveField(6)
  String operatorName;

  Movement({
    required this.id,
    required this.productName,
    required this.movementType,
    required this.movementDate,
    required this.storageLocation,
    required this.quantity,
    required this.operatorName,
  });
}
