import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'station_model.dart';

class StationService {
  static const int _maxRetryAttempts = 3;

  Future<List<Station>> getStations(String token) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/queue/stations');
    final client = http.Client();

    try {
      for (var attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
        try {
          final response = await client
              .get(
                uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(AppConfig.requestTimeout);

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            final List<dynamic> data = jsonData['data'];
            return data.map((json) => Station.fromJson(json)).toList();
          }

          if (_isRetriableStatus(response.statusCode) &&
              attempt < _maxRetryAttempts) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }

          throw Exception('Failed to load stations: ${response.statusCode}');
        } on SocketException catch (_) {
          if (attempt == _maxRetryAttempts) rethrow;
          await Future.delayed(Duration(seconds: attempt));
        } on TimeoutException catch (_) {
          if (attempt == _maxRetryAttempts) rethrow;
          await Future.delayed(Duration(seconds: attempt));
        } on http.ClientException catch (_) {
          if (attempt == _maxRetryAttempts) rethrow;
          await Future.delayed(Duration(seconds: attempt));
        }
      }
      throw Exception('Failed to load stations after retries');
    } catch (e) {
      throw Exception('Error fetching stations: $e');
    } finally {
      client.close();
    }
  }

  bool _isRetriableStatus(int statusCode) =>
      statusCode == 429 || (statusCode >= 500 && statusCode < 600);
}
