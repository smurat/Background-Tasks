// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PositionDataAdapter extends TypeAdapter<PositionData> {
  @override
  final int typeId = 0;

  @override
  PositionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PositionData(
      longitude: fields[1] as double,
      latitude: fields[0] as double,
      timestamp: fields[2] as DateTime,
      accuracy: fields[4] as double,
      altitude: fields[3] as double,
      heading: fields[5] as double,
      floor: fields[6] as int,
      speed: fields[7] as double,
      speedAccuracy: fields[8] as double,
      isMocked: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PositionData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.altitude)
      ..writeByte(4)
      ..write(obj.accuracy)
      ..writeByte(5)
      ..write(obj.heading)
      ..writeByte(6)
      ..write(obj.floor)
      ..writeByte(7)
      ..write(obj.speed)
      ..writeByte(8)
      ..write(obj.speedAccuracy)
      ..writeByte(9)
      ..write(obj.isMocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
