import 'package:flutter/material.dart';

class VehicleCategory {
  const VehicleCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.fuelSubsidyPercentage,
    this.description,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final double fuelSubsidyPercentage;
  final String? description;
  final bool isActive;

  factory VehicleCategory.fromJson(Map<String, dynamic> json) {
    return VehicleCategory(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fuelSubsidyPercentage:
          double.tryParse(json['fuelSubsidyPercentage']?.toString() ?? '') ??
          0.0,
      description: json['description']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}

class Vehicle {
  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.categoryId,
    required this.label,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.remainingLiters,
    this.litersLimit,
    this.period,
  });

  final int id;
  final String plateNumber;
  final int categoryId;
  final String? label;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VehicleCategory? category;

  // Filled in by `getVehiclesWithQuota`.
  double? remainingLiters;
  double? litersLimit;
  String? period;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return Vehicle(
      id: json['id'] as int,
      plateNumber: json['plateNumber']?.toString() ?? '',
      categoryId: json['categoryId'] as int,
      label: json['label']?.toString(),
      isActive: json['isActive'] == true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: categoryJson is Map<String, dynamic>
          ? VehicleCategory.fromJson(categoryJson)
          : null,
    );
  }

  String get displayTitle {
    final lbl = label?.trim();
    if (lbl != null && lbl.isNotEmpty) return lbl;
    return category?.name ?? 'Vehicle';
  }

  String get categoryDisplayName => category?.name ?? 'Unknown category';

  String get statusText {
    if (!isActive) return 'Inactive';
    final remaining = remainingLiters;
    if (remaining == null) return 'Unknown';
    if (remaining <= 0) return 'Depleted';
    if (remaining <= 5) return 'Critical';
    if (remaining <= 10) return 'Low';
    return 'Active';
  }

  Color get statusColor {
    if (!isActive) return const Color(0xFF98A2B3);
    final remaining = remainingLiters;
    if (remaining == null) return const Color(0xFF667085);
    if (remaining <= 0) return const Color(0xFF98A2B3);
    if (remaining <= 5) return const Color(0xFFD92D20);
    if (remaining <= 10) return const Color(0xFFE67E22);
    return const Color(0xFF17B26A);
  }

  double get progressValue {
    final remaining = remainingLiters;
    final limit = litersLimit;
    if (remaining == null || limit == null || limit <= 0) return 0.0;
    return (remaining / limit).clamp(0.0, 1.0);
  }

  Color get progressColor {
    final remaining = remainingLiters;
    if (remaining == null) return const Color(0xFF98A2B3);
    if (remaining <= 5) return const Color(0xFFD92D20);
    if (remaining <= 10) return const Color(0xFFE67E22);
    return const Color(0xFF0B4D8B);
  }
}

class QuotaPeriod {
  const QuotaPeriod({
    required this.period,
    required this.remainingLiters,
    required this.litersLimit,
  });

  final String period;
  final double remainingLiters;
  final double litersLimit;

  factory QuotaPeriod.fromJson(Map<String, dynamic> json) {
    return QuotaPeriod(
      period: json['period']?.toString() ?? 'UNKNOWN',
      remainingLiters:
          double.tryParse(json['remainingLiters']?.toString() ?? '') ?? 0.0,
      litersLimit:
          double.tryParse(json['litersLimit']?.toString() ?? '') ?? 0.0,
    );
  }
}

class QuotaResponse {
  const QuotaResponse({
    required this.vehicleId,
    required this.remainingLiters,
    required this.litersLimit,
    required this.periods,
  });

  final int vehicleId;
  final double remainingLiters;
  final double litersLimit;
  final List<QuotaPeriod> periods;

  factory QuotaResponse.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] as Map<String, dynamic>;
    return QuotaResponse(
      vehicleId: data['vehicleId'] as int,
      remainingLiters:
          double.tryParse(data['remainingLiters']?.toString() ?? '') ?? 0.0,
      litersLimit:
          double.tryParse(data['litersLimit']?.toString() ?? '') ?? 0.0,
      periods: (data['periods'] as List<dynamic>? ?? [])
          .map((p) => QuotaPeriod.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
