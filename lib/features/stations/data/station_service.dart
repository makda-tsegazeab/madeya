import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/location_service.dart';
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

  Future<List<Station>> getStationsSortedByDistance(String token) async {
  try {
    // Get user's current location
    final userPosition = await LocationService.getCurrentLocation();
    if (userPosition == null) {
      // If location is not available, return regular stations list
      return getStations(token);
    }

    // Get all stations
    final stations = await getStations(token);
    
    // Calculate distance for each station and sort
    final stationsWithDistance = <Station>[];
    
    for (final station in stations) {
      double? distance;
      
      if (station.hasValidCoordinates) {
        final stationLat = station.latitudeAsDouble;
        final stationLng = station.longitudeAsDouble;
        
        if (stationLat != null && stationLng != null) {
          distance = LocationService.calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            stationLat,
            stationLng,
          );
        }
      }
      
      stationsWithDistance.add(station.copyWith(distanceFromUser: distance));
    }
    
    // Sort stations by distance (null distances go to the end)
    stationsWithDistance.sort((a, b) {
      if (a.distanceFromUser == null && b.distanceFromUser == null) return 0;
      if (a.distanceFromUser == null) return 1;
      if (b.distanceFromUser == null) return -1;
      return a.distanceFromUser!.compareTo(b.distanceFromUser!);
    });
    
    return stationsWithDistance;
  } catch (e) {
    // If location fails, fall back to regular stations list
    return getStations(token);
  }
}

  bool _isRetriableStatus(int statusCode) =>
      statusCode == 429 || (statusCode >= 500 && statusCode < 600);
}
