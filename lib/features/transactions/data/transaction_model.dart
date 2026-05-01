class TransactionStation {
  const TransactionStation({required this.id, required this.name, this.phone});

  final int id;
  final String name;
  final String? phone;

  factory TransactionStation.fromJson(Map<String, dynamic> json) {
    return TransactionStation(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class TransactionVehicle {
  const TransactionVehicle({
    required this.id,
    required this.plateNumber,
    this.label,
  });

  final int id;
  final String plateNumber;
  final String? label;

  factory TransactionVehicle.fromJson(Map<String, dynamic> json) {
    return TransactionVehicle(
      id: json['id'] as int,
      plateNumber: json['plateNumber']?.toString() ?? '',
      label: json['label']?.toString(),
    );
  }
}

class TransactionPayment {
  const TransactionPayment({
    required this.id,
    required this.fuelType,
    required this.litersRequested,
    required this.pricePerLiter,
    required this.amount,
    required this.currency,
    this.paidAt,
    this.txRef,
  });

  final int id;
  final String fuelType;
  final String litersRequested;
  final String pricePerLiter;
  final String amount;
  final String currency;
  final String? paidAt;
  final String? txRef;

  factory TransactionPayment.fromJson(Map<String, dynamic> json) {
    return TransactionPayment(
      id: json['id'] as int,
      fuelType: json['fuelType']?.toString() ?? '',
      litersRequested: json['litersRequested']?.toString() ?? '0',
      pricePerLiter: json['pricePerLiter']?.toString() ?? '0',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'ETB',
      paidAt: json['paidAt']?.toString(),
      txRef: json['txRef']?.toString(),
    );
  }
}

class OwnerTransaction {
  const OwnerTransaction({
    required this.transactionId,
    required this.queueBookingId,
    required this.servedAt,
    required this.litersDispensed,
    this.receiptRef,
    this.station,
    this.vehicle,
    this.payment,
  });

  final int transactionId;
  final int queueBookingId;
  final DateTime servedAt;
  final String litersDispensed;
  final String? receiptRef;
  final TransactionStation? station;
  final TransactionVehicle? vehicle;
  final TransactionPayment? payment;

  factory OwnerTransaction.fromJson(Map<String, dynamic> json) {
    return OwnerTransaction(
      transactionId: json['transactionId'] as int,
      queueBookingId: json['queueBookingId'] as int,
      servedAt: DateTime.parse(json['servedAt'] as String),
      litersDispensed: json['litersDispensed']?.toString() ?? '0',
      receiptRef: json['receiptRef']?.toString(),
      station: json['station'] is Map<String, dynamic>
          ? TransactionStation.fromJson(json['station'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? TransactionVehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      payment: json['payment'] is Map<String, dynamic>
          ? TransactionPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}
