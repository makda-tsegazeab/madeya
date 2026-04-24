import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'station_model.dart';

class StationService {
  Future<List<Station>> getStations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/queue/stations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        return data.map((json) => Station.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stations: $e');
    }
  }
}
