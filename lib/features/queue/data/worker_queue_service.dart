import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class WorkerQueueService {
  WorkerQueueService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> verifyBooking({
    required String accessToken,
    required String verifyToken,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/queue/worker/verify'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'verifyToken': verifyToken}),
        )
        .timeout(AppConfig.requestTimeout);

    final payload = _tryDecodeJson(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractMessage(payload) ??
          'Failed to verify (${response.statusCode})';
      throw Exception(message);
    }

    if (payload is! Map<String, dynamic> || payload['success'] != true) {
      final message = _extractMessage(payload) ?? 'Failed to verify booking';
      throw Exception(message);
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid verify response');
  }

  Future<Map<String, dynamic>> completeBooking({
    required String accessToken,
    required String verifyToken,
    String? receiptRef,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/queue/worker/complete'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'verifyToken': verifyToken,
            if (receiptRef != null && receiptRef.trim().isNotEmpty)
              'receiptRef': receiptRef.trim(),
          }),
        )
        .timeout(AppConfig.requestTimeout);

    final payload = _tryDecodeJson(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractMessage(payload) ??
          'Failed to complete (${response.statusCode})';
      throw Exception(message);
    }

    if (payload is! Map<String, dynamic> || payload['success'] != true) {
      final message = _extractMessage(payload) ?? 'Failed to complete booking';
      throw Exception(message);
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid complete response');
  }
}

Object? _tryDecodeJson(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return null;
  }
}

String? _extractMessage(Object? payload) {
  if (payload is! Map<String, dynamic>) return null;
  final m = payload['message'];
  if (m is String && m.trim().isNotEmpty) return m;
  return null;
}

