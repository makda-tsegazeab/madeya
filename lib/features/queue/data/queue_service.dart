import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'queue_models.dart';

class QueueService {
  QueueService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ActiveBooking>> getActiveBookings(String token) async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/owner/queue/active'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load queue (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((b) => ActiveBooking.fromJson(b as Map<String, dynamic>))
        .toList();
  }
}
