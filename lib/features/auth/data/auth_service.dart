import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'token_storage.dart';

class AuthUserProfile {
  const AuthUserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.stationId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? stationId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUserProfile user;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password.');
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException()
    : super('Unable to reach server. Check your connection and try again.');
}

class ServerAuthException extends AuthException {
  const ServerAuthException()
    : super('Something went wrong on the server. Please try again.');
}

abstract class AuthService {
  Future<AuthSession> login({required String email, required String password});

  Future<void> forgetPassword(String email);
  Future<bool> verifyResetCode(String email, String code);
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> logout();
}

class AuthServiceImpl implements AuthService {
  AuthServiceImpl({required TokenStorage tokenStorage, http.Client? client})
    : _tokenStorage = tokenStorage,
      _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const NetworkAuthException();
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      json = null;
    }

    if (response.statusCode == 401) {
      throw const InvalidCredentialsException();
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json == null) {
      throw const ServerAuthException();
    }

    final data = json['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    final accessToken = data?['accessToken'] as String?;

    if (data == null || user == null || accessToken == null) {
      throw const ServerAuthException();
    }

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
      throw const ServerAuthException();
    }

    final profile = AuthUserProfile(
      id: id,
      email: emailValue,
      firstName: firstName,
      lastName: lastName,
      role: role,
      stationId: user['stationId']?.toString(),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await _tokenStorage.saveAccessToken(accessToken);
    return AuthSession(accessToken: accessToken, user: profile);
  }

  @override
  Future<void> forgetPassword(String email) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/forgot-password');
    http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const NetworkAuthException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final jsonBody = jsonDecode(response.body);
        final message = jsonBody['message'];
        if (message is String) throw AuthException(message);
        if (message is List && message.isNotEmpty)
          throw AuthException(message.first.toString());
      } catch (e) {
        if (e is AuthException) rethrow;
      }
      throw const ServerAuthException();
    }
  }

  @override
  Future<bool> verifyResetCode(String email, String code) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/verify-reset-code');
    http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.trim()}),
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const NetworkAuthException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final jsonBody = jsonDecode(response.body);
        final message = jsonBody['message'];
        if (message is String) throw AuthException(message);
        if (message is List && message.isNotEmpty)
          throw AuthException(message.first.toString());
      } catch (e) {
        if (e is AuthException) rethrow;
      }
      throw const ServerAuthException();
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      json = null;
    }

    final data = json?['data'] as Map<String, dynamic>?;
    return data?['valid'] == true;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/reset-password');
    http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.trim(), 'password': newPassword}),
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const NetworkAuthException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final jsonBody = jsonDecode(response.body);
        final message = jsonBody['message'];
        if (message is String) throw AuthException(message);
        if (message is List && message.isNotEmpty)
          throw AuthException(message.first.toString());
      } catch (e) {
        if (e is AuthException) rethrow;
      }
      throw const ServerAuthException();
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      throw const AuthException('Session expired. Please login again.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/change-password');
    http.Response response;

    try {
      response = await _client
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(AppConfig.requestTimeout);
    } on Exception {
      throw const NetworkAuthException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final jsonBody = jsonDecode(response.body);
        final message = jsonBody['message'];
        if (message is String) throw AuthException(message);
        if (message is List && message.isNotEmpty)
          throw AuthException(message.first.toString());
      } catch (e) {
        if (e is AuthException) rethrow;
      }
      throw const ServerAuthException();
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearAccessToken();
  }
}
