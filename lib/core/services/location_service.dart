import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const double _earthRadiusKm = 6371.0;
  static Position? _cachedPosition;
  static DateTime? _lastLocationTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if we have a cached location that's still valid
      if (_cachedPosition != null && 
          _lastLocationTime != null && 
          DateTime.now().difference(_lastLocationTime!) < _cacheTimeout) {
        return _cachedPosition;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _cachedPosition; // Return cached if available
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _cachedPosition; // Return cached if available
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _cachedPosition; // Return cached if available
      }

      // Try to get position with multiple accuracy levels
      Position? position;
      
      // First try high accuracy (GPS)
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        // Fallback to medium accuracy (network + GPS)
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e2) {
          // Final fallback to low accuracy (network only)
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 8),
            );
          } catch (e3) {
            return _cachedPosition; // Return cached if available
          }
        }
      }

      // Cache the successful location
      if (position != null) {
        _cachedPosition = position;
        _lastLocationTime = DateTime.now();
      }

      return position;
    } catch (e) {
      return _cachedPosition; // Return cached if available
    }
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m away';
    } else if (distanceKm < 10.0) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.round()} km away';
    }
  }

  static void clearCache() {
    _cachedPosition = null;
    _lastLocationTime = null;
  }
}
