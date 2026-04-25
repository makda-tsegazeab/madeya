import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'announcement_model.dart';

class AnnouncementService {
  AnnouncementService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Announcement>> getAnnouncements(String token) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/owner/announcements');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonBody['data'] as List<dynamic>?;
        
        if (data == null) return [];

        return data
            .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }
}
