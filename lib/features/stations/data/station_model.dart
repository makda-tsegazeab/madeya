import 'dart:math';
import '../../../core/services/location_service.dart';

class Station {
  const Station({
    required this.id,
    required this.name,
    required this.isActive,
    required this.queueIntakePaused,
    required this.activeQueueLength,
    this.latitude,
    this.longitude,
    this.phone,
    this.distanceFromUser,
  });

  final int id;
  final String name;
  final bool isActive;
  final bool queueIntakePaused;
  final int activeQueueLength;
  final String? latitude;
  final String? longitude;
  final String? phone;
  final double? distanceFromUser;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
      queueIntakePaused: json['queueIntakePaused'] == true,
      activeQueueLength: (json['activeQueueLength'] as num?)?.toInt() ?? 0,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Station copyWith({
    int? id,
    String? name,
    bool? isActive,
    bool? queueIntakePaused,
    int? activeQueueLength,
    String? latitude,
    String? longitude,
    String? phone,
    double? distanceFromUser,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      queueIntakePaused: queueIntakePaused ?? this.queueIntakePaused,
      activeQueueLength: activeQueueLength ?? this.activeQueueLength,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }

  bool get acceptsQueueJoins => isActive && !queueIntakePaused;

  /// Station fuel is tracked per type on the server; owners see queue intake status here.
  String get fuelStatusLabel {
    if (!acceptsQueueJoins) return 'Queue closed';
    return 'Open';
  }

  String get locationSummary {
    final lat = latitude;
    final lng = longitude;
    if (lat != null && lng != null && lat.isNotEmpty && lng.isNotEmpty) {
      return '$lat, $lng';
    }
    return phone ?? 'No location info';
  }

  String get distanceText {
    if (distanceFromUser == null) return '';
    return LocationService.formatDistance(distanceFromUser!);
  }

  bool get hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;
    return lat != null && lng != null && lat.isNotEmpty && lng.isNotEmpty;
  }

  double? get latitudeAsDouble {
    if (latitude == null || latitude!.isEmpty) return null;
    return double.tryParse(latitude!);
  }

  double? get longitudeAsDouble {
    if (longitude == null || longitude!.isEmpty) return null;
    return double.tryParse(longitude!);
  }
}
