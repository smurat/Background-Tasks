import 'dart:convert';
import 'package:hive/hive.dart';
part 'position_model.g.dart';

PositionData positionDataFromJson(String str) =>
    PositionData.fromMap(json.decode(str));

String positionDataToJson(PositionData data) => json.encode(data.toJson());

@HiveType(typeId: 0)
class PositionData {
  @HiveField(0)
  final double latitude;
  @HiveField(1)
  final double longitude;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final double altitude;
  @HiveField(4)
  final double accuracy;
  @HiveField(5)
  final double heading;
  @HiveField(6)
  final int floor;
  @HiveField(7)
  final double speed;
  @HiveField(8)
  final double speedAccuracy;
  @HiveField(9)
  final bool isMocked;

  PositionData({
    this.longitude,
    this.latitude,
    this.timestamp,
    this.accuracy,
    this.altitude,
    this.heading,
    this.floor,
    this.speed,
    this.speedAccuracy,
    this.isMocked,
  });

  @override
  bool operator ==(dynamic o) {
    var areEqual = o is PositionData &&
        o.accuracy == accuracy &&
        o.altitude == altitude &&
        o.heading == heading &&
        o.latitude == latitude &&
        o.longitude == longitude &&
        o.floor == o.floor &&
        o.speed == speed &&
        o.speedAccuracy == speedAccuracy &&
        o.timestamp == timestamp &&
        o.isMocked == isMocked;

    return areEqual;
  }

  @override
  int get hashCode =>
      accuracy.hashCode ^
      altitude.hashCode ^
      heading.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      floor.hashCode ^
      speed.hashCode ^
      speedAccuracy.hashCode ^
      timestamp.hashCode ^
      isMocked.hashCode;

  static PositionData fromMap(dynamic message) {
    if (message == null) {
      return null;
    }

    final Map<dynamic, dynamic> positionMap = message;

    if (!positionMap.containsKey('latitude')) {
      throw ArgumentError.value(positionMap, 'positionMap',
          'The supplied map doesn\'t contain the mandatory key `latitude`.');
    }

    if (!positionMap.containsKey('longitude')) {
      throw ArgumentError.value(positionMap, 'positionMap',
          'The supplied map doesn\'t contain the mandatory key `longitude`.');
    }

    final timestamp = positionMap['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(positionMap['timestamp'].toInt(),
            isUtc: true)
        : null;

    return PositionData(
      latitude: positionMap['latitude'],
      longitude: positionMap['longitude'],
      timestamp: timestamp,
      altitude: positionMap['altitude'] ?? 0.0,
      accuracy: positionMap['accuracy'] ?? 0.0,
      heading: positionMap['heading'] ?? 0.0,
      floor: positionMap['floor'],
      speed: positionMap['speed'] ?? 0.0,
      speedAccuracy: positionMap['speed_accuracy'] ?? 0.0,
      isMocked: positionMap['is_mocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
        'timestamp': timestamp?.millisecondsSinceEpoch,
        'accuracy': accuracy,
        'altitude': altitude,
        'floor': floor,
        'heading': heading,
        'speed': speed,
        'speed_accuracy': speedAccuracy,
        'is_mocked': isMocked,
      };
}
