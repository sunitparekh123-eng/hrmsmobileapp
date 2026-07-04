import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service for communicating with the real backend.
///
/// - Handles JWT token storage (SharedPreferences)
/// - Automatically attaches Bearer token to authenticated requests
/// - Unwraps the { success, message, data } envelope from backend
class ApiService {
  /// Backend API URL.
  /// Local backend running on the host machine (same WiFi network).
  /// Use the host machine's LAN IP so a physical phone can reach it.
  static String get baseUrl => 'https://api.apaarpulse.com/api/v1';

  String? _token;
  String? _refreshToken;

  /// Holds the in-flight refresh operation so concurrent 401s all
  /// await the SAME refresh instead of racing / failing immediately.
  Future<bool>? _refreshFuture;

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

  // ── Token Refresh ──────────────────────────────────────────────

  /// Attempt to refresh the access token using the stored refresh
  /// token.  Returns `true` on success (new tokens saved), `false`
  /// on failure (refresh token missing / invalid / expired).
  ///
  /// This is called automatically when an authenticated request
  /// receives a 401 response, so the user stays logged in for the
  /// full 60-day lifetime of the refresh token without needing to
  /// re-enter credentials.
  ///
  /// If a refresh is already in flight (e.g. several API calls hit
  /// 401 at the same time), concurrent callers await the SAME
  /// refresh Future instead of failing immediately. This prevents
  /// spurious logouts when multiple requests expire together.
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    // If a refresh is already running, wait for it instead of racing.
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  /// Performs the actual HTTP refresh-token call.
  Future<bool> _doRefresh() async {
    try {
      final url = Uri.parse('$baseUrl/auth/refresh-token');
      final response = await http.post(
        url,
        headers: _headers(auth: false),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body.containsKey('data') ? body['data'] : body;
        final newToken = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newToken != null) {
          await saveTokens(
            accessToken: newToken,
            refreshToken: newRefresh ?? _refreshToken!,
          );
          return true;
        }
      }
      // Refresh failed — refresh token is invalid or expired.
      return false;
    } catch (_) {
      return false;
    }
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
  ///
  /// If the access token has expired (HTTP 401), the service
  /// automatically attempts a single token-refresh and retries the
  /// request so the user stays logged in for the full 60-day lifetime
  /// of the refresh token.
  Future<dynamic> getAuth(String path) async {
    final url = Uri.parse('$baseUrl$path');
    var response = await http.get(url, headers: _headers(auth: true));

    if (response.statusCode == 401 && _refreshToken != null) {
      if (await _refreshAccessToken()) {
        response = await http.get(url, headers: _headers(auth: true));
      }
    }
    return _unwrap(response);
  }

  /// POST with auth header.
  ///
  /// Automatically refreshes the access token on HTTP 401 and retries.
  Future<dynamic> postAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final encoded = jsonEncode(body);
    var response = await http.post(
      url,
      headers: _headers(auth: true),
      body: encoded,
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      if (await _refreshAccessToken()) {
        response = await http.post(
          url,
          headers: _headers(auth: true),
          body: encoded,
        );
      }
    }
    return _unwrap(response);
  }

  /// PATCH with auth header.
  ///
  /// Automatically refreshes the access token on HTTP 401 and retries.
  Future<dynamic> patchAuth(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final encoded = jsonEncode(body);
    var response = await http.patch(
      url,
      headers: _headers(auth: true),
      body: encoded,
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      if (await _refreshAccessToken()) {
        response = await http.patch(
          url,
          headers: _headers(auth: true),
          body: encoded,
        );
      }
    }
    return _unwrap(response);
  }

  /// Download raw bytes (e.g. PDF) with auth header.
  /// Returns the raw [Uint8List] response body.
  ///
  /// Automatically refreshes the access token on HTTP 401 and retries.
  Future<List<int>> downloadBytes(String path) async {
    final url = Uri.parse('$baseUrl$path');
    var response = await http.get(url, headers: _headers(auth: true));

    if (response.statusCode == 401 && _refreshToken != null) {
      if (await _refreshAccessToken()) {
        response = await http.get(url, headers: _headers(auth: true));
      }
    }

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