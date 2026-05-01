import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'transaction_model.dart';

class TransactionService {
  TransactionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<OwnerTransaction>> listTransactions(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/owner/transactions',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await _client
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load transactions (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((t) => OwnerTransaction.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerTransaction> getTransaction(String token, int id) async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/owner/transactions/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load transaction (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return OwnerTransaction.fromJson(body['data'] as Map<String, dynamic>);
  }
}
