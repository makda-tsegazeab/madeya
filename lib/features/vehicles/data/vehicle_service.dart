import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'vehicle_model.dart';

class VehicleService {
  Future<List<Vehicle>> getVehicles(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/owner/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> vehiclesJson = jsonData['data'];
        return vehiclesJson.map((v) => Vehicle.fromJson(v)).toList();
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  Future<QuotaResponse> getVehicleQuota(int vehicleId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/owner/vehicles/$vehicleId/quota'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return QuotaResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load quota: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching quota: $e');
    }
  }

  Future<List<Vehicle>> getVehiclesWithQuota(String token) async {
    final vehicles = await getVehicles(token);

    final quotaFutures = vehicles.map((vehicle) async {
      try {
        final quota = await getVehicleQuota(vehicle.id, token);
        vehicle.remainingLiters = quota.remainingLiters;
        vehicle.litersLimit = quota.litersLimit;
        vehicle.period = quota.periods.first.period;
      } catch (e) {
        vehicle.remainingLiters = 0;
        vehicle.litersLimit = 0;
        vehicle.period = 'UNKNOWN';
      }
      return vehicle;
    });

    return Future.wait(quotaFutures);
  }
}
