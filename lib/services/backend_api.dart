import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MuseumDto {
  const MuseumDto({
    required this.id,
    required this.name,
    required this.operatingHours,
    required this.baseTicketPrice,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String operatingHours;
  final int baseTicketPrice;
  final double latitude;
  final double longitude;

  factory MuseumDto.fromJson(Map<String, dynamic> json) => MuseumDto(
    id: json['id'] as int,
    name: json['name'] as String,
    operatingHours: json['operating_hours'] as String,
    baseTicketPrice: json['base_ticket_price'] as int,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class AuthLoginResult {
  const AuthLoginResult({
    required this.userId,
    required this.fullName,
    required this.message,
  });

  final int userId;
  final String fullName;
  final String message;
}

class ArtifactDto {
  const ArtifactDto({
    required this.id,
    required this.artifactCode,
    required this.title,
    required this.year,
    required this.description,
    required this.is3dAvailable,
    required this.museumId,
    required this.unityPrefabName,
    this.audioAsset = '',
  });

  final int id;
  final String artifactCode;
  final String title;
  final String year;
  final String description;
  final bool is3dAvailable;
  final int museumId;
  final String unityPrefabName;
  final String audioAsset;

  factory ArtifactDto.fromJson(Map<String, dynamic> json) => ArtifactDto(
    id: json['id'] as int,
    artifactCode: json['artifact_code'] as String,
    title: json['title'] as String,
    year: json['year'] as String,
    description: json['description'] as String,
    is3dAvailable: json['is_3d_available'] as bool,
    museumId: json['museum_id'] as int,
    unityPrefabName: json['unity_prefab_name'] as String,
    audioAsset: json['audio_asset'] as String? ?? '',
  );
}

class ExhibitionDto {
  const ExhibitionDto({
    required this.id,
    required this.name,
    required this.location,
    required this.museumId,
  });

  final int id;
  final String name;
  final String location;
  final int museumId;

  factory ExhibitionDto.fromJson(Map<String, dynamic> json) => ExhibitionDto(
    id: json['id'] as int,
    name: json['name'] as String,
    location: json['location'] as String,
    museumId: json['museum_id'] as int,
  );
}

class RouteDto {
  const RouteDto({
    required this.id,
    required this.name,
    required this.estimatedTime,
    required this.stopsCount,
    required this.museumId,
  });

  final int id;
  final String name;
  final String estimatedTime;
  final int stopsCount;
  final int museumId;

  factory RouteDto.fromJson(Map<String, dynamic> json) => RouteDto(
    id: json['id'] as int,
    name: json['name'] as String,
    estimatedTime: json['estimated_time'] as String,
    stopsCount: json['stops_count'] as int,
    museumId: json['museum_id'] as int,
  );
}

class TicketDto {
  const TicketDto({
    required this.id,
    required this.ticketType,
    required this.purchaseDate,
    required this.qrCode,
    required this.userId,
    required this.museumId,
  });

  final int id;
  final String ticketType;
  final String purchaseDate;
  final String qrCode;
  final int userId;
  final int museumId;

  factory TicketDto.fromJson(Map<String, dynamic> json) => TicketDto(
    id: json['id'] as int,
    ticketType: json['ticket_type'] as String,
    purchaseDate: json['purchase_date'] as String,
    qrCode: json['qr_code'] as String,
    userId: json['user_id'] as int,
    museumId: json['museum_id'] as int,
  );
}

class BackendApi {
  BackendApi._();
  static final BackendApi instance = BackendApi._();

  // Override with: flutter run --dart-define=API_BASE_URL=http://your-ip:8000
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;

    // Use production backend URL
    return 'https://museamigo-backend.onrender.com';

    // Development URLs (commented out)
    // if (kIsWeb) return 'http://localhost:8000';
    // if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    // if (Platform.isIOS) return 'http://localhost:8000';
    // return 'http://localhost:8000';
  }

  Uri _uri(String path) {
    final url = '$baseUrl$path';
    print('Constructed URL: $url');
    return Uri.parse(url);
  }

  Future<Map<String, dynamic>> _readJson(http.Response response) async {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{
        'detail':
            'Unexpected API response format (status ${response.statusCode})',
      };
    } catch (_) {
      final preview = response.body.length > 180
          ? '${response.body.substring(0, 180)}...'
          : response.body;
      return <String, dynamic>{
        'detail':
            'Server returned non-JSON response (status ${response.statusCode}): $preview',
      };
    }
  }

  Never _throwForResponse(http.Response response, Map<String, dynamic> json) {
    final detail = json['detail'];
    final message = detail is String
        ? detail
        : 'Request failed (${response.statusCode})';
    throw ApiException(message);
  }

  Future<int> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );
      final json = await _readJson(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(response, json);
      }
      return json['id'] as int? ?? json['user_id'] as int? ?? 0;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to reach backend: $e');
    }
  }

  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(
          const Duration(
            seconds: 60,
          ), // Increased timeout to 60 seconds for Render spin-up
        );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return AuthLoginResult(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      message: json['message'] as String? ?? 'Login successful',
    );
  }

  Future<void> warmUp() async {
    try {
      await http.get(_uri('/museums')).timeout(const Duration(seconds: 12));
    } catch (_) {
      // Best-effort warm-up only; login flow handles real failures.
    }
  }

  Future<List<MuseumDto>> fetchMuseums() async {
    final response = await http.get(_uri('/museums'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected museum list format');
    }
    return decoded
        .map((e) => MuseumDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> askAi(String message) async {
    final response = await http.post(
      _uri('/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json['reply'] as String? ?? '';
  }

  Future<List<ExhibitionDto>> fetchExhibitions(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/exhibitions'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected exhibition list format');
    }
    return decoded
        .map((e) => ExhibitionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteDto>> fetchRoutes(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/routes'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected route list format');
    }
    return decoded
        .map((e) => RouteDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ArtifactDto> fetchArtifact(String artifactCode) async {
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(_uri('/artifacts/$artifactCode'))
            .timeout(const Duration(seconds: 20));
        final json = await _readJson(response);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _throwForResponse(response, json);
        }
        return ArtifactDto.fromJson(json);
      } on TimeoutException {
        if (attempt == maxRetries) {
          throw ApiException(
            'The server is taking too long to respond. '
            'This often happens when the backend wakes up after being idle. Please try again.',
          );
        }
        // Wait before retrying
        await Future.delayed(const Duration(seconds: 3));
      } on http.ClientException catch (e) {
        if (attempt == maxRetries) {
          throw ApiException(
            'Unable to connect to the server (${e.message}). '
            'Please check your internet connection and try again.',
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw ApiException('Failed to fetch artifact after multiple attempts.');
  }

  Future<void> addToCollection({
    required int userId,
    required int artifactId,
  }) async {
    final response = await http.post(
      _uri('/collections'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'artifact_id': artifactId}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
  }

  Future<TicketDto> purchaseTicket({
    required int userId,
    required int museumId,
    required String ticketType,
  }) async {
    final response = await http.post(
      _uri('/tickets/purchase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'museum_id': museumId,
        'ticket_type': ticketType,
      }),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return TicketDto.fromJson(json);
  }

  Future<List<dynamic>> fetchUserAchievements(int userId, int museumId) async {
    final raw = await fetchUserAchievementsRaw(userId, museumId);
    return raw['achievements'] as List<dynamic>? ?? [];
  }

  /// Returns the full API response: {user_id, museum_id, total_points, unlocked_count, achievements: [...]}
  Future<Map<String, dynamic>> fetchUserAchievementsRaw(
    int userId,
    int museumId,
  ) async {
    final response = await http.get(
      _uri('/users/$userId/achievements?museum_id=$museumId'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);

    // API returns {achievements: [...], total_points, unlocked_count, ...}
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // Fallback: direct array
    if (decoded is List) {
      return <String, dynamic>{
        'achievements': decoded,
        'total_points': 0,
        'unlocked_count': 0,
      };
    }

    throw ApiException('Unexpected achievements format');
  }

  Future<Map<String, dynamic>> updateAchievementProgress(
    int userId,
    int achievementId,
    int progress,
  ) async {
    final response = await http.patch(
      _uri('/users/$userId/achievements/$achievementId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'progress': progress}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      _uri('/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      _uri('/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
  }

  Future<Map<String, dynamic>> fetchUser(int userId) async {
    final response = await http.get(_uri('/users/$userId'));
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }

  Future<Map<String, dynamic>> updateUserProfile(
    int userId, {
    required String fullName,
  }) async {
    final response = await http.patch(
      _uri('/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': fullName}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }
}
