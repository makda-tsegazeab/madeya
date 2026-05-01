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
    this.remainingFuel,
  });

  final int id;
  final String name;
  final bool isActive;
  final bool queueIntakePaused;
  final int activeQueueLength;
  final String? latitude;
  final String? longitude;
  final String? phone;
  final String? remainingFuel;

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
      remainingFuel: json['remainingFuel']?.toString(),
    );
  }

  bool get acceptsQueueJoins => isActive && !queueIntakePaused;

  String get fuelStatusLabel {
    final raw = remainingFuel;
    if (raw == null || raw.isEmpty) return 'Unknown';
    final value = double.tryParse(raw);
    if (value == null) return 'Unknown';
    if (value <= 0) return 'Out of stock';
    if (value < 200) return 'Low';
    return 'Available';
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
