import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Dùng để xử lý mảng byte của file audio trả về

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
    required this.description,
    required this.operatingHours,
    required this.baseTicketPrice,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  /// Optional museum blurb from `/museums`; empty when the backend omits it.
  final String description;
  final String operatingHours;
  final int baseTicketPrice;
  final double latitude;
  final double longitude;

  factory MuseumDto.fromJson(Map<String, dynamic> json) => MuseumDto(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
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
    this.theme = 'light',
    this.language = 'English',
    this.fontSize = 'Medium',
    this.scheme = '0xFFCC353A',
  });

  final int userId;
  final String fullName;
  final String message;
  final String theme;
  final String language;
  final String fontSize;
  final String scheme;
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
    this.mapX,
    this.mapY,
    this.floorId,
    this.floorLabel,
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
  /// Normalized 0–1 horizontal position on the museum indoor map image.
  final double? mapX;
  /// Normalized 0–1 vertical position on the museum indoor map image.
  final double? mapY;
  /// FK to `museum_floors.id`; coordinates are relative to that floor's map image.
  final int? floorId;
  /// Display label from backend (joined floor row).
  final String? floorLabel;

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
    mapX: (json['map_x'] as num?)?.toDouble(),
    mapY: (json['map_y'] as num?)?.toDouble(),
    floorId: (json['floor_id'] as num?)?.toInt(),
    floorLabel: json['floor_label'] as String? ?? json['map_floor'] as String?,
  );
}

class IndoorMapDto {
  const IndoorMapDto({
    required this.museumId,
    this.map2dPath,
    this.map3dPath,
  });

  final int museumId;
  /// Server path such as `/static/maps/floor1.png` or absolute URL.
  final String? map2dPath;
  final String? map3dPath;

  factory IndoorMapDto.fromJson(Map<String, dynamic> json) => IndoorMapDto(
    museumId: json['museum_id'] as int,
    map2dPath: json['map_2d_path'] as String?,
    map3dPath: json['map_3d_path'] as String?,
  );
}

class MuseumFloorDto {
  const MuseumFloorDto({
    required this.id,
    required this.museumId,
    required this.label,
    required this.sortOrder,
    this.indoorMap2dPath,
    this.indoorMap3dPath,
  });

  final int id;
  final int museumId;
  final String label;
  final int sortOrder;
  /// Per-floor 2D map asset path (same host rules as museum indoor map).
  final String? indoorMap2dPath;
  final String? indoorMap3dPath;

  factory MuseumFloorDto.fromJson(Map<String, dynamic> json) => MuseumFloorDto(
    id: json['id'] as int,
    museumId: json['museum_id'] as int,
    label: json['label'] as String,
    sortOrder: json['sort_order'] as int,
    indoorMap2dPath: json['indoor_map_2d_path'] as String?,
    indoorMap3dPath: json['indoor_map_3d_path'] as String?,
  );
}

/// Editable POIs on the indoor map (WC, café, stairs, …) from the dashboard API.
class MapDestinationDto {
  const MapDestinationDto({
    required this.id,
    required this.museumId,
    required this.title,
    required this.category,
    required this.markerColor,
    required this.mapX,
    required this.mapY,
    required this.floorId,
    required this.floorLabel,
  });

  final int id;
  final int museumId;
  final String title;
  final String category;
  final String markerColor;
  final double mapX;
  final double mapY;
  final int floorId;
  final String floorLabel;

  factory MapDestinationDto.fromJson(Map<String, dynamic> json) =>
      MapDestinationDto(
        id: json['id'] as int,
        museumId: json['museum_id'] as int,
        title: json['title'] as String,
        category: json['category'] as String? ?? 'other',
        markerColor: json['marker_color'] as String? ?? '#6366F1',
        mapX: (json['map_x'] as num).toDouble(),
        mapY: (json['map_y'] as num).toDouble(),
        floorId: json['floor_id'] as int,
        floorLabel: json['floor_label'] as String? ?? '',
      );
}

class ExhibitionDto {
  const ExhibitionDto({
    required this.id,
    required this.name,
    required this.location,
    required this.museumId,
    this.artifactCodes = const [],
    this.mapX,
    this.mapY,
    this.floorId,
    this.floorLabel,
  });

  final int id;
  final String name;
  final String location;
  final int museumId;
  final List<String> artifactCodes;
  final double? mapX;
  final double? mapY;
  final int? floorId;
  final String? floorLabel;

  factory ExhibitionDto.fromJson(Map<String, dynamic> json) {
    List<String> codes = const [];
    final raw = json['artifacts'];
    if (raw is List) {
      codes = raw.map((e) => e.toString()).toList();
    }
    return ExhibitionDto(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      museumId: json['museum_id'] as int,
      artifactCodes: codes,
      mapX: (json['map_x'] as num?)?.toDouble(),
      mapY: (json['map_y'] as num?)?.toDouble(),
      floorId: (json['floor_id'] as num?)?.toInt(),
      floorLabel: json['floor_label'] as String? ?? json['map_floor'] as String?,
    );
  }
}

class RouteDto {
  const RouteDto({
    required this.id,
    required this.name,
    required this.estimatedTime,
    required this.stopsCount,
    this.stopsJson = const [],
    required this.museumId,
  });

  final int id;
  final String name;
  final String estimatedTime;
  final int stopsCount;
  final List<RouteStopDto> stopsJson;
  final int museumId;

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops_json'];
    final parsedStops = <RouteStopDto>[];
    if (rawStops is List) {
      for (final e in rawStops) {
        if (e is Map<String, dynamic>) {
          parsedStops.add(RouteStopDto.fromJson(e));
        } else if (e is Map) {
          parsedStops.add(
            RouteStopDto.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }
    return RouteDto(
      id: json['id'] as int,
      name: json['name'] as String,
      estimatedTime: json['estimated_time'] as String,
      stopsCount: json['stops_count'] as int,
      stopsJson: parsedStops,
      museumId: json['museum_id'] as int,
    );
  }
}

class RouteStopDto {
  const RouteStopDto({
    required this.itemType,
    this.itemId,
    required this.label,
  });

  final String itemType;
  final int? itemId;
  final String label;

  factory RouteStopDto.fromJson(Map<String, dynamic> json) => RouteStopDto(
    itemType: (json['item_type'] as String? ?? 'custom').trim().toLowerCase(),
    itemId: (json['item_id'] as num?)?.toInt(),
    label: (json['label'] as String? ?? '').trim(),
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

class AiChatResult {
  const AiChatResult({required this.reply, this.action});

  final String reply;
  final String? action;
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

  /// Turn a path from the API (e.g. `/static/maps/x.png`) into a full URL for [Image.network].
  String? resolveApiAssetUrl(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
    final t = pathOrUrl.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = t.startsWith('/') ? t : '/$t';
    return '$base$p';
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
      theme: json['theme'] as String? ?? 'light',
      language: json['language'] as String? ?? 'English',
      fontSize: json['font_size'] as String? ?? 'Medium',
      scheme: json['scheme'] as String? ?? '0xFFCC353A',
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

  Future<AiChatResult> askAiWithAction(String message) async {
    final response = await http.post(
      _uri('/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    final reply = json['reply'] as String? ?? '';
    final rawAction = json['action'];
    final normalizedAction = rawAction == null
        ? null
        : rawAction.toString().trim().toUpperCase();

    return AiChatResult(reply: reply, action: normalizedAction);
  }

  Future<String> askAi(String message) async {
    final result = await askAiWithAction(message);
    return result.reply;
  }

  Future<Uint8List> askAiAudio(String filePath) async {
    try {
      // Dùng MultipartRequest để gửi file qua form-data
      final request = http.MultipartRequest('POST', _uri('/ai/chat/audio'));

      // Đính kèm file audio vào field tên là 'file' (phải khớp với backend)
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print('Đang gửi audio lên server...');

      // Gửi request lên server
      final streamedResponse = await request.send();

      // Chuyển streamedResponse thành Response bình thường để dễ đọc body
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Thành công: Backend trả về trực tiếp file âm thanh
        print(
          'Nhận audio thành công. Kích thước: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        // Thất bại: Backend trả về JSON chứa thông báo lỗi (HTTP 500, 400, v.v.)
        final json = await _readJson(response);
        _throwForResponse(response, json);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến server: $e');
    }
  }

  Future<IndoorMapDto> fetchIndoorMap(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/indoor-map'));
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return IndoorMapDto.fromJson(json);
  }

  Future<List<ArtifactDto>> fetchArtifacts(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/artifacts'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected artifact list format');
    }
    return decoded
        .map((e) => ArtifactDto.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// Museum-defined floor labels and order (for chips and tying destinations to floors).
  Future<List<MuseumFloorDto>> fetchMuseumFloors(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/floors'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected museum floors list format');
    }
    return decoded
        .map((e) => MuseumFloorDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Map destinations (amenities, stairs, etc.) with title, color, and coordinates.
  Future<List<MapDestinationDto>> fetchMapDestinations(int museumId) async {
    final response = await http.get(_uri('/museums/$museumId/map-destinations'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected map destinations list format');
    }
    return decoded
        .map((e) => MapDestinationDto.fromJson(e as Map<String, dynamic>))
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

  Future<List<Map<String, dynamic>>> fetchUserTickets(int userId) async {
    final response = await http.get(_uri('/users/$userId/tickets'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = await _readJson(response);
      _throwForResponse(response, json);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Unexpected ticket list format');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Persists **I'm in** / entrance check-in so `is_used` is updated server-side.
  Future<void> markTicketUsed({
    required int userId,
    required String qrCode,
  }) async {
    final response = await http.post(
      _uri('/users/$userId/tickets/mark-used'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qr_code': qrCode}),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
  }

  /// Links an existing unused ticket (friend's QR / code) to [userId].
  Future<Map<String, dynamic>> redeemTicket({
    required int userId,
    required String ticketCode,
  }) async {
    final response = await http.post(
      _uri('/tickets/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'ticket_code': ticketCode,
      }),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }

  Future<void> updateUserSettings(
    int userId, {
    required String theme,
    required String language,
    required String fontSize,
    required String scheme,
  }) async {
    final response = await http.put(
      _uri('/users/$userId/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'theme': theme,
        'language': language,
        'font_size': fontSize,
        'scheme': scheme,
      }),
    );
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
  }

  Future<Map<String, dynamic>> createPayment({
    required int userId,
    required int museumId,
    required String ticketType,
  }) async {
    final response = await http.post(
      _uri('/payments/create'),
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
    return json;
  }

  Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    final response = await http.get(_uri('/payments/$orderId/status'));
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
    return json;
  }

  Future<void> simulatePaymentWebhook(int orderId) async {
    final response = await http.post(_uri('/payments/$orderId/webhook'));
    final json = await _readJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response, json);
    }
  }
}
