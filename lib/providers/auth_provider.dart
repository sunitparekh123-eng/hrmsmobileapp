import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AuthProvider(this._api);

  Employee? _currentEmployee;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // ── Login ───────────────────────────────────────────────────────

  /// Authenticate against the real backend.
  /// Only employees (role == 'employee') are allowed on the mobile app.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.postNoAuth('/auth/login', {
        'email': email,
        'password': password,
      });

      final empData = (data as Map<String, dynamic>)['employee']
          as Map<String, dynamic>;
      final role = empData['role'] as String?;

      // Mobile app is for employees only — block admin / hr
      if (role != null && role != 'employee') {
        _error = 'This app is for employees only. Please use the web portal.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final employee = Employee.fromBackendJson(empData);

      // Persist tokens
      await _api.saveTokens(
        accessToken: data['token'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      _currentEmployee = employee;
      _isAuthenticated = true;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Auto-login (called from Splash) ─────────────────────────────

  /// Try to restore session from stored token via GET /auth/me.
  Future<bool> tryAutoLogin() async {
    await _api.loadTokens();

    if (_api.token == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getAuth('/auth/me');

      if (data == null) {
        await _api.clearTokens();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final empData = data as Map<String, dynamic>;
      final role = empData['role'] as String?;

      if (role != null && role != 'employee') {
        await _api.clearTokens();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentEmployee = Employee.fromBackendJson(empData);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException {
      await _api.clearTokens();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      await _api.clearTokens();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_api.token != null) {
        await _api.postAuth('/auth/logout', {});
      }
    } catch (_) {
      // Best-effort: clear tokens even if the server call fails
    }

    await _api.clearTokens();
    _currentEmployee = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  // ── Forgot Password ──────────────────────────────────────────────

  /// Request a password reset link for the given email.
  /// Returns true even if the email isn't found (security best-practice).
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.postNoAuth('/auth/forgot-password', {'email': email});
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      // Backend returns 200/404 with generic message either way,
      // so we treat any response as success for security.
      if (e.statusCode == 404) {
        _isLoading = false;
        notifyListeners();
        return true; // don't reveal account existence
      }
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password using the token from the email link.
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.postNoAuth('/auth/reset-password', {
        'token': token,
        'new_password': newPassword,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final data = await _api.getAuth('/auth/me');
      if (data != null) {
        _currentEmployee = Employee.fromBackendJson(data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}