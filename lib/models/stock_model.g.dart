// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  final int typeId = 0;

  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMovement(
      id: fields[0] as int,
      productName: fields[1] as String,
      movementType: fields[2] as String,
      dateTime: fields[3] as DateTime,
      storageLocation: fields[4] as String,
      quantity: fields[5] as int,
      operatorName: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.movementType)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.storageLocation)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.operatorName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
