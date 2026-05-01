class FuelPrice {
  const FuelPrice({
    required this.id,
    required this.fuelType,
    required this.pricePerLiter,
    required this.isActive,
  });

  final int id;
  final String fuelType;
  final double pricePerLiter;
  final bool isActive;

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      id: json['id'] as int,
      fuelType: json['fuelType']?.toString() ?? '',
      pricePerLiter:
          double.tryParse(json['pricePerLiter']?.toString() ?? '') ?? 0.0,
      isActive: json['isActive'] == true,
    );
  }
}

class InitiatePaymentResult {
  const InitiatePaymentResult({
    required this.paymentId,
    required this.txRef,
    required this.amount,
    required this.currency,
    required this.fuelType,
    required this.litersRequested,
    required this.pricePerLiter,
    required this.checkoutUrl,
    this.grossAmount,
    this.subsidyAmount,
    this.fuelSubsidyPercentage,
  });

  final int paymentId;
  final String txRef;
  final String amount;
  final String currency;
  final String fuelType;
  final String litersRequested;
  final String pricePerLiter;
  final String checkoutUrl;
  final String? grossAmount;
  final String? subsidyAmount;
  final String? fuelSubsidyPercentage;

  factory InitiatePaymentResult.fromJson(Map<String, dynamic> json) {
    return InitiatePaymentResult(
      paymentId: json['paymentId'] as int,
      txRef: json['txRef']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'ETB',
      fuelType: json['fuelType']?.toString() ?? '',
      litersRequested: json['litersRequested']?.toString() ?? '0',
      pricePerLiter: json['pricePerLiter']?.toString() ?? '0',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      grossAmount: json['grossAmount']?.toString(),
      subsidyAmount: json['subsidyAmount']?.toString(),
      fuelSubsidyPercentage: json['fuelSubsidyPercentage']?.toString(),
    );
  }
}

class JoinQueueResult {
  const JoinQueueResult({
    required this.bookingId,
    required this.stationId,
    required this.vehicleId,
    required this.stationSequence,
    required this.positionAhead,
    required this.verifyToken,
    required this.bookedAt,
  });

  final int bookingId;
  final int stationId;
  final int vehicleId;
  final int stationSequence;
  final int positionAhead;
  final String verifyToken;
  final String bookedAt;

  factory JoinQueueResult.fromJson(Map<String, dynamic> json) {
    return JoinQueueResult(
      bookingId: json['bookingId'] as int,
      stationId: json['stationId'] as int,
      vehicleId: json['vehicleId'] as int,
      stationSequence: (json['stationSequence'] as num).toInt(),
      positionAhead: (json['positionAhead'] as num).toInt(),
      verifyToken: json['verifyToken']?.toString() ?? '',
      bookedAt: json['bookedAt']?.toString() ?? '',
    );
  }
}

class ActiveBookingStation {
  const ActiveBookingStation({
    required this.id,
    required this.name,
    this.phone,
    this.queueIntakePaused = false,
  });

  final int id;
  final String name;
  final String? phone;
  final bool queueIntakePaused;

  factory ActiveBookingStation.fromJson(Map<String, dynamic> json) {
    return ActiveBookingStation(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      queueIntakePaused: json['queueIntakePaused'] == true,
    );
  }
}

class ActiveBookingVehicle {
  const ActiveBookingVehicle({
    required this.id,
    required this.plateNumber,
    this.label,
  });

  final int id;
  final String plateNumber;
  final String? label;

  factory ActiveBookingVehicle.fromJson(Map<String, dynamic> json) {
    return ActiveBookingVehicle(
      id: json['id'] as int,
      plateNumber: json['plateNumber']?.toString() ?? '',
      label: json['label']?.toString(),
    );
  }
}

class ActiveBookingPayment {
  const ActiveBookingPayment({
    required this.id,
    required this.fuelType,
    required this.litersRequested,
    required this.amount,
    required this.currency,
    this.paidAt,
  });

  final int id;
  final String fuelType;
  final String litersRequested;
  final String amount;
  final String currency;
  final String? paidAt;

  factory ActiveBookingPayment.fromJson(Map<String, dynamic> json) {
    return ActiveBookingPayment(
      id: json['id'] as int,
      fuelType: json['fuelType']?.toString() ?? '',
      litersRequested: json['litersRequested']?.toString() ?? '0',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'ETB',
      paidAt: json['paidAt']?.toString(),
    );
  }
}

class ActiveBooking {
  const ActiveBooking({
    required this.bookingId,
    required this.stationId,
    required this.status,
    required this.stationSequence,
    required this.queuePosition,
    required this.positionAhead,
    required this.bookedAt,
    required this.verifyToken,
    this.station,
    this.vehicle,
    this.payment,
  });

  final int bookingId;
  final int stationId;
  final String status;
  final int stationSequence;
  final int queuePosition;
  final int positionAhead;
  final String bookedAt;
  final String verifyToken;
  final ActiveBookingStation? station;
  final ActiveBookingVehicle? vehicle;
  final ActiveBookingPayment? payment;

  factory ActiveBooking.fromJson(Map<String, dynamic> json) {
    return ActiveBooking(
      bookingId: json['bookingId'] as int,
      stationId: json['stationId'] as int,
      status: json['status']?.toString() ?? 'ACTIVE',
      stationSequence: (json['stationSequence'] as num).toInt(),
      queuePosition: (json['queuePosition'] as num).toInt(),
      positionAhead: (json['positionAhead'] as num).toInt(),
      bookedAt: json['bookedAt']?.toString() ?? '',
      verifyToken: json['verifyToken']?.toString() ?? '',
      station: json['station'] is Map<String, dynamic>
          ? ActiveBookingStation.fromJson(
              json['station'] as Map<String, dynamic>,
            )
          : null,
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? ActiveBookingVehicle.fromJson(
              json['vehicle'] as Map<String, dynamic>,
            )
          : null,
      payment: json['payment'] is Map<String, dynamic>
          ? ActiveBookingPayment.fromJson(
              json['payment'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
