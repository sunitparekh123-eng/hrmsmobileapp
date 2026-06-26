import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service for communicating with the real backend.
///
/// - Handles JWT token storage (SharedPreferences)
/// - Automatically attaches Bearer token to authenticated requests
/// - Unwraps the { success, message, data } envelope from backend
class ApiService {
  /// Production backend URL (deployed on VPS).
  static String get baseUrl => 'https://187.127.187.27.nip.io/api/v1';

  String? _token;
  String? _refreshToken;

  // ── Token Management ────────────────────────────────────────────

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  /// Persist both tokens after login.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Load tokens from local storage (called on app start).
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  /// Wipe stored tokens (logout).
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  // ── HTTP Helpers ─────────────────────────────────────────────────

  Map<String, String> _headers({required bool auth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Parse backend envelope: { success, message, data } → return `data`.
  dynamic _unwrap(http.Response response) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Invalid server response',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If the backend used the success() helper, unwrap `data`.
      if (body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    // Error response
    final message = body['message'] as String? ?? 'Request failed';
    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      errors: body['errors'],
    );
  }

  // ── Public Methods ───────────────────────────────────────────────

  /// POST without auth header (login).
  Future<dynamic> postNoAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: _headers(auth: false),
      body: jsonEncode(body),
    );
    return _unwrap(response);
  }

  /// GET with auth header.
  Future<dynamic> getAuth(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: _headers(auth: true));
    return _unwrap(response);
  }

  /// POST with auth header.
  Future<dynamic> postAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(body),
    );
    return _unwrap(response);
  }

  /// PATCH with auth header.
  Future<dynamic> patchAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(body),
    );
    return _unwrap(response);
  }

  /// Download raw bytes (e.g. PDF) with auth header.
  /// Returns the raw [Uint8List] response body.
  Future<List<int>> downloadBytes(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: _headers(auth: true));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    // Try to parse error message
    String message = 'Download failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? message;
    } catch (_) {}
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

/// Typed exception to distinguish API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}