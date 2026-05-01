import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'vehicle_model.dart';

class VehicleService {
  VehicleService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Vehicle>> getVehicles(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/owner/vehicles'),
            headers: _authHeaders(token),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Log the error but don't throw - return empty list instead
        print('Failed to load vehicles (${response.statusCode}): ${response.body}');
        return [];
      }

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        print('Empty response from server');
        return [];
      }

      final body = json.decode(responseBody) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Log the error but don't throw - return empty list instead
      print('Error loading vehicles: $e');
      return [];
    }
  }

  Future<Vehicle> getVehicle(int vehicleId, String token) async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/owner/vehicles/$vehicleId'),
          headers: _authHeaders(token),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load vehicle (${response.statusCode})');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  Future<QuotaResponse> getVehicleQuota(int vehicleId, String token) async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/owner/vehicles/$vehicleId/quota'),
          headers: _authHeaders(token),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Quota lookup commonly returns 400 when no quota rule is configured;
      // the caller decides how to surface that.
      throw Exception('Failed to load quota (${response.statusCode})');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    return QuotaResponse.fromEnvelope(body);
  }

  Future<List<Vehicle>> getVehiclesWithQuota(String token) async {
    try {
      final vehicles = await getVehicles(token);

      final results = await Future.wait(
        vehicles.map((vehicle) async {
          try {
            final quota = await getVehicleQuota(vehicle.id, token);
            vehicle.remainingLiters = quota.remainingLiters;
            vehicle.litersLimit = quota.litersLimit;
            vehicle.period = quota.periods.isNotEmpty
                ? quota.periods.first.period
                : null;
          } catch (e) {
            // Vehicle is shown without quota info if the quota call fails
            // (e.g. no active quota rule yet).
            print('Error loading quota for vehicle ${vehicle.id}: $e');
            vehicle.remainingLiters = null;
            vehicle.litersLimit = null;
            vehicle.period = null;
          }
          return vehicle;
        }),
      );

      return results;
    } catch (e) {
      print('Error loading vehicles with quota: $e');
      return [];
    }
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
