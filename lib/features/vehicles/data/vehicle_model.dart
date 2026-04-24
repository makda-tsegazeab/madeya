import 'package:flutter/material.dart';

class Vehicle {
  final int id;
  final String plateNumber;
  final String category;
  final String label;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  double? remainingLiters;
  double? litersLimit;
  String? period;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.category,
    required this.label,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.remainingLiters,
    this.litersLimit,
    this.period,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plateNumber: json['plateNumber'],
      category: json['category'],
      label: json['label'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get vehicleTitle => label;

  String get statusText {
    if (remainingLiters == null) return 'Unknown';
    if (remainingLiters! <= 5) return 'Critical';
    if (remainingLiters! <= 10) return 'Low';
    return 'Active';
  }

  Color get statusColor {
    if (remainingLiters == null) return const Color(0xFF667085);
    if (remainingLiters! <= 5) return const Color(0xFFD92D20);
    if (remainingLiters! <= 10) return const Color(0xFFE67E22);
    return const Color(0xFF17B26A);
  }

  double get progressValue {
    if (remainingLiters == null || litersLimit == null || litersLimit == 0) {
      return 0.0;
    }
    return (remainingLiters! / litersLimit!).clamp(0.0, 1.0);
  }

  Color get progressColor {
    if (remainingLiters == null) return const Color(0xFF98A2B3);
    if (remainingLiters! <= 5) return const Color(0xFFD92D20);
    if (remainingLiters! <= 10) return const Color(0xFFE67E22);
    return const Color(0xFF0B4D8B);
  }

  String get fuelType {
    if (label.toLowerCase().contains('hilux') ||
        label.toLowerCase().contains('toyota')) {
      return 'Benzene';
    }
    if (label.toLowerCase().contains('isuzu') ||
        label.toLowerCase().contains('fsr')) {
      return 'Naphtha';
    }
    return 'Petrol';
  }
}

class QuotaResponse {
  final int vehicleId;
  final double remainingLiters;
  final double litersLimit;
  final List<QuotaPeriod> periods;

  QuotaResponse({
    required this.vehicleId,
    required this.remainingLiters,
    required this.litersLimit,
    required this.periods,
  });

  factory QuotaResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return QuotaResponse(
      vehicleId: data['vehicleId'],
      remainingLiters: double.parse(data['remainingLiters'].toString()),
      litersLimit: double.parse(data['litersLimit'].toString()),
      periods: (data['periods'] as List)
          .map((p) => QuotaPeriod.fromJson(p))
          .toList(),
    );
  }
}

class QuotaPeriod {
  final String period;
  final double remainingLiters;
  final double litersLimit;

  QuotaPeriod({
    required this.period,
    required this.remainingLiters,
    required this.litersLimit,
  });

  factory QuotaPeriod.fromJson(Map<String, dynamic> json) {
    return QuotaPeriod(
      period: json['period'],
      remainingLiters: double.parse(json['remainingLiters'].toString()),
      litersLimit: double.parse(json['litersLimit'].toString()),
    );
  }
}
