class Station {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? phone;
  final bool isActive;
  final bool queueIntakePaused;
  final String fuelStatus;
  final int activeQueueLength;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    required this.isActive,
    required this.queueIntakePaused,
    required this.fuelStatus,
    required this.activeQueueLength,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'],
      isActive: json['isActive'] ?? false,
      queueIntakePaused: json['queueIntakePaused'] ?? false,
      fuelStatus: json['fuelStatus'] ?? 'UNKNOWN',
      activeQueueLength: json['activeQueueLength'] ?? 0,
    );
  }
}
