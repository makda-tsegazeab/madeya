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
  });

  final int id;
  final String name;
  final bool isActive;
  final bool queueIntakePaused;
  final int activeQueueLength;
  final String? latitude;
  final String? longitude;
  final String? phone;

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
}
