import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'queue_models.dart';

class PaymentException implements Exception {
  PaymentException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const List<Duration> _retryBackoff = [
    Duration(milliseconds: 300),
    Duration(milliseconds: 800),
  ];

  Future<List<FuelPrice>> listFuelPrices(String token) async {
    return _withTransientRetry<List<FuelPrice>>(() async {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/queue/fuel-prices'),
            headers: _authHeaders(token),
          )
          .timeout(AppConfig.requestTimeout);

      final body = _decodeOrThrow(response, 'Failed to load fuel prices');
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((p) => FuelPrice.fromJson(p as Map<String, dynamic>))
          .toList();
    }, fallbackMessage: 'Temporary network issue while loading fuel prices.');
  }

  Future<InitiatePaymentResult> initiatePayment({
    required String token,
    required int vehicleId,
    required int stationId,
    required String fuelType,
    required double litersRequested,
    required String phoneNumber,
  }) async {
    return _withTransientRetry<InitiatePaymentResult>(() async {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/queue/payments/initiate'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'vehicleId': vehicleId,
              'stationId': stationId,
              'fuelType': fuelType,
              'litersRequested': litersRequested,
              'phoneNumber': phoneNumber,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      final body = _decodeOrThrow(response, 'Failed to initiate payment');
      return InitiatePaymentResult.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }, fallbackMessage: 'Temporary network issue while initiating payment.');
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String token,
    required String txRef,
  }) async {
    return _withTransientRetry<Map<String, dynamic>>(() async {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/queue/payments/verify'),
            headers: _authHeaders(token),
            body: jsonEncode({'txRef': txRef}),
          )
          .timeout(AppConfig.requestTimeout);

      final body = _decodeOrThrow(response, 'Failed to verify payment');
      return body['data'] as Map<String, dynamic>;
    }, fallbackMessage: 'Temporary network issue while verifying payment.');
  }

  Future<JoinQueueResult> joinQueue({
    required String token,
    required int paymentId,
  }) async {
    return _withTransientRetry<JoinQueueResult>(() async {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/queue/join'),
            headers: _authHeaders(token),
            body: jsonEncode({'paymentId': paymentId}),
          )
          .timeout(AppConfig.requestTimeout);

      final body = _decodeOrThrow(response, 'Failed to join queue');
      return JoinQueueResult.fromJson(body['data'] as Map<String, dynamic>);
    }, fallbackMessage: 'Temporary network issue while joining queue.');
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeOrThrow(
    http.Response response,
    String fallbackMessage,
  ) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(body) ?? fallbackMessage;
      throw PaymentException(message, statusCode: response.statusCode);
    }

    if (body == null) {
      throw PaymentException(fallbackMessage, statusCode: response.statusCode);
    }
    return body;
  }

  String? _extractErrorMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    final message = body['message'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return null;
  }

  Future<T> _withTransientRetry<T>(
    Future<T> Function() request, {
    required String fallbackMessage,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await request();
      } on SocketException {
        if (attempt >= _retryBackoff.length) {
          throw PaymentException(fallbackMessage);
        }
      } on TimeoutException {
        if (attempt >= _retryBackoff.length) {
          throw PaymentException(fallbackMessage);
        }
      }
      await Future.delayed(_retryBackoff[attempt]);
    }
  }
}
