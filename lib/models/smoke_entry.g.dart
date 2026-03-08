// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smoke_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmokeEntryAdapter extends TypeAdapter<SmokeEntry> {
  @override
  final int typeId = 0;

  @override
  SmokeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmokeEntry(
      id: fields[6] as String,
      createdAt: fields[0] as DateTime,
      amount: fields[1] as int,
      type: fields[2] as String,
      trigger: fields[3] as String?,
      note: fields[4] as String?,
      pricePerPack: fields[5] as double?,
      brand: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SmokeEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.createdAt)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.trigger)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.pricePerPack)
      ..writeByte(6)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.brand);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmokeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
