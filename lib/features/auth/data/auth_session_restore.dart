import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'auth_models.dart';
import 'token_storage.dart';

AuthUserProfile? profileFromUserJson(Map<String, dynamic>? user) {
  if (user == null) return null;
  final id = user['id']?.toString();
  final role = user['role']?.toString();
  final emailValue = user['email']?.toString();
  final firstName = user['firstName']?.toString();
  final lastName = user['lastName']?.toString();
  final isActive = user['isActive'] == true;
  final createdAt = user['createdAt']?.toString();
  final updatedAt = user['updatedAt']?.toString();

  if (id == null ||
      role == null ||
      emailValue == null ||
      firstName == null ||
      lastName == null ||
      createdAt == null ||
      updatedAt == null) {
    return null;
  }

  return AuthUserProfile(
    id: id,
    email: emailValue,
    firstName: firstName,
    lastName: lastName,
    role: role,
    stationId: user['stationId']?.toString(),
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    phoneNumber: user['phoneNumber']?.toString(),
  );
}

/// Loads stored access token and validates it with [GET /auth/profile].
Future<AuthSession?> restoreAuthSession(
  TokenStorage tokenStorage, {
  http.Client? client,
}) async {
  final accessToken = await tokenStorage.readAccessToken();
  if (accessToken == null || accessToken.isEmpty) {
    return null;
  }

  final httpClient = client ?? http.Client();
  final ownsClient = client == null;

  try {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/profile');
    http.Response response;

    try {
      response = await httpClient
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      return null;
    }

    if (response.statusCode == 401) {
      await tokenStorage.clearAccessToken();
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      json = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json == null) {
      return null;
    }

    final data = json['data'] as Map<String, dynamic>?;
    final profile = profileFromUserJson(data);
    if (profile == null) {
      return null;
    }

    return AuthSession(accessToken: accessToken, user: profile);
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}
