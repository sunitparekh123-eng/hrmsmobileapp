import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance.dart';
import '../models/geo_location.dart';
import '../services/api_service.dart';

/// Enum for the Google Maps loading lifecycle.
enum GoogleMapsState { uninitialised, fetchingKey, keyMissing, keyReady, error }

class AttendanceProvider extends ChangeNotifier {
  final ApiService _api;

  AttendanceProvider(this._api);

  // -- Today's punch state --
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  bool _isPunchInAllowed = true;
  bool _isPunchOutAllowed = true;
  String? _disabledReason;  // e.g. "Today is a public holiday: Republic Day" or "Today is Sunday — a weekend off"
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  final String _checkInLocation = '';
  double? _checkInLat;
  double? _checkInLon;
  double? _distanceFromOfficeIn;
  double? _distanceFromOfficeOut;
  bool _isLateToday = false;
  int _lateByMinutes = 0;
  int _totalHoursVal = 0;
  int _totalMinutesVal = 0;

  // -- Optional photo capture --
  String? _photoPathIn;
  String? _photoPathOut;

  // -- Punch history for today --
  final List<PunchRecord> _todayPunches = [];

  // -- Geo-location (DYNAMIC — populated from backend + real device GPS) --
  OfficeLocation? _selectedOffice;
  GeoFenceStatus _geoFenceStatus = GeoFenceStatus.unknown;
  double _currentDistance = 0.0;
  double? _currentLat;
  double? _currentLon;
  bool _isLoadingLocation = false;
  String? _locationError;

  // -- Monthly data --
  MonthlyAttendance? _currentMonth;
  bool _isLoadingMonthly = false;
  String? _monthlyError;

  // -- Loading --
  bool _isPunching = false;
  String? _punchResultMessage;
  bool _isPunchError = false;

  // -- Google Maps (lazy-loaded behind "View Map" button) --
  GoogleMapsState _mapsState = GoogleMapsState.uninitialised;
  String? _googleMapsApiKey;
  String? _mapsError;
  bool _showMap = false;

  // -- Live elapsed timer --
  Timer? _elapsedTimer;

  // -- Getters --
  bool get isCheckedIn => _isCheckedIn;
  bool get isCheckedOut => _isCheckedOut;
  DateTime? get checkInTime => _checkInTime;
  DateTime? get checkOutTime => _checkOutTime;
  String get checkInLocation => _checkInLocation;
  double? get checkInLat => _checkInLat;
  double? get checkInLon => _checkInLon;
  double? get distanceFromOfficeIn => _distanceFromOfficeIn;
  double? get distanceFromOfficeOut => _distanceFromOfficeOut;
  bool get isLateToday => _isLateToday;
  int get lateByMinutes => _lateByMinutes;
  int get totalHoursVal => _totalHoursVal;
  int get totalMinutesVal => _totalMinutesVal;
  String? get photoPathIn => _photoPathIn;
  String? get photoPathOut => _photoPathOut;
  List<PunchRecord> get todayPunches => List.unmodifiable(_todayPunches);
  OfficeLocation? get selectedOffice => _selectedOffice;
  GeoFenceStatus get geoFenceStatus => _geoFenceStatus;
  double get currentDistance => _currentDistance;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  MonthlyAttendance? get currentMonth => _currentMonth;
  bool get isLoadingMonthly => _isLoadingMonthly;
  String? get monthlyError => _monthlyError;
  bool get isPunching => _isPunching;
  String? get punchResultMessage => _punchResultMessage;
  bool get isPunchError => _isPunchError;

  // -- Google Maps getters (lazy-loaded) --
  GoogleMapsState get mapsState => _mapsState;
  String? get googleMapsApiKey => _googleMapsApiKey;
  String? get mapsError => _mapsError;
  bool get showMap => _showMap;
  bool get isPunchInAllowed => _isPunchInAllowed;
  bool get isPunchOutAllowed => _isPunchOutAllowed;
  String? get disabledReason => _disabledReason;
  bool get isDisabledDay => _disabledReason != null && _disabledReason!.isNotEmpty;

  String get formattedCheckIn => _checkInTime != null
      ? '${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}'
      : '--:--';

  String get formattedCheckOut => _checkOutTime != null
      ? '${_checkOutTime!.hour.toString().padLeft(2, '0')}:${_checkOutTime!.minute.toString().padLeft(2, '0')}'
      : '--:--';

  String get formattedDistanceIn =>
      _distanceFromOfficeIn != null
          ? GeoUtils.formatDistance(_distanceFromOfficeIn!)
          : '--';

  String get formattedDistanceOut =>
      _distanceFromOfficeOut != null
          ? GeoUtils.formatDistance(_distanceFromOfficeOut!)
          : '--';

  Duration? get totalHoursToday {
    if (_checkInTime == null || _checkOutTime == null) return null;
    return _checkOutTime!.difference(_checkInTime!);
  }

  Duration get elapsed {
    if (_isCheckedIn && !_isCheckedOut && _checkInTime != null) {
      return DateTime.now().difference(_checkInTime!);
    }
    if (_isCheckedIn && _isCheckedOut &&
        _checkInTime != null && _checkOutTime != null) {
      return _checkOutTime!.difference(_checkInTime!);
    }
    return Duration.zero;
  }

  String get formattedElapsed {
    final d = elapsed;
    final cleanD = d.isNegative ? Duration.zero : d;
    final h = cleanD.inHours.toString().padLeft(2, '0');
    final m = cleanD.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = cleanD.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedTotalHours {
    final d = totalHoursToday;
    if (d == null) return '--';
    final cleanD = d.isNegative ? Duration.zero : d;
    return '${cleanD.inHours}h ${cleanD.inMinutes.remainder(60)}m';
  }

  // -- Initialization --
  /// Fetches office data from backend, computes today's punch status and monthly data.
  Future<void> initialize() async {
    await _fetchOfficeFromBackend();
    await _fetchTodayStatus();
    await _fetchMonthlyAttendance();
  }

  // -- Fetch office coordinates from backend /auth/me --
  Future<void> _fetchOfficeFromBackend() async {
    try {
      final data = await _api.getAuth('/auth/me');
      if (data == null) return;

      final officeRaw = data['office'] as Map<String, dynamic>?;
      if (officeRaw != null) {
        final lat = _safeDouble(officeRaw['latitude']);
        final lon = _safeDouble(officeRaw['longitude']);
        final radius = _safeDouble(officeRaw['radius_meters']) ?? 200.0;

        if (lat != null && lon != null) {
          _selectedOffice = OfficeLocation(
            id: officeRaw['id']?.toString() ?? 'OFFICE',
            name: officeRaw['name'] as String? ?? 'Office',
            address: officeRaw['name'] as String? ?? '',
            latitude: lat,
            longitude: lon,
            radiusMeters: radius,
          );
        }
      }
    } catch (e) {
      debugPrint('_fetchOfficeFromBackend error: $e');
    }
  }

  // -- Acquire real device GPS position --
  Future<void> _acquireDeviceLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled. Please enable GPS.';
        _geoFenceStatus = GeoFenceStatus.unknown;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied.';
          _geoFenceStatus = GeoFenceStatus.unknown;
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError =
            'Location permission permanently denied. Enable in Settings.';
        _geoFenceStatus = GeoFenceStatus.unknown;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentLat = position.latitude;
      _currentLon = position.longitude;

      // Calculate distance to office
      _recalculateGeoFence();
    } catch (e) {
      _locationError = 'Failed to get GPS location: $e';
      _geoFenceStatus = GeoFenceStatus.unknown;
      debugPrint('_acquireDeviceLocation error: $e');
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  /// Re-run the geo-fence check with current position against the office.
  void _recalculateGeoFence() {
    if (_currentLat == null || _currentLon == null || _selectedOffice == null) {
      _geoFenceStatus = GeoFenceStatus.unknown;
      _currentDistance = 0.0;
      return;
    }

    _currentDistance = GeoUtils.calculateDistance(
      _currentLat!,
      _currentLon!,
      _selectedOffice!.latitude,
      _selectedOffice!.longitude,
    );
    _geoFenceStatus = _currentDistance <= _selectedOffice!.radiusMeters
        ? GeoFenceStatus.withinRange
        : GeoFenceStatus.outOfRange;
  }

  // -- Fetch today's status from backend --
  Future<void> _fetchTodayStatus() async {
    try {
      final raw = await _api.getAuth('/attendance/today');
      if (raw == null) {
        _isCheckedIn = false;
        _isCheckedOut = false;
        _checkInTime = null;
        _checkOutTime = null;
        _isPunchInAllowed = true;
        _isPunchOutAllowed = true;
        notifyListeners();
        return;
      }

      _isPunchInAllowed = raw['isPunchInAllowed'] ?? true;
      _isPunchOutAllowed = raw['isPunchOutAllowed'] ?? true;
      _disabledReason = raw['disabledReason'] as String?;

      final record = raw['record'] as Map<String, dynamic>?;

      if (record != null) {
        // Parse date from record to use as fallback for time-only values
        final today = record['date'] is String
            ? DateTime.tryParse(record['date'] as String)
            : null;
        final fallbackDate = today ?? DateTime.now();

        // Use shared helper that handles both ISO datetimes AND time-only strings (MySQL TIME)
        _checkInTime = AttendanceRecord.parseDateTime(
          record['check_in_time'],
          fallbackDate: fallbackDate,
        );
        _checkOutTime = AttendanceRecord.parseDateTime(
          record['check_out_time'],
          fallbackDate: fallbackDate,
        );

        _isCheckedIn = _checkInTime != null;
        _isCheckedOut = _checkOutTime != null;

        _totalHoursVal = _safeInt(record['total_hours']);
        _totalMinutesVal = _safeInt(record['total_minutes']);

        _lateByMinutes = _safeInt(record['late_by_minutes']);
        _isLateToday = _lateByMinutes > 0;

        _checkInLat = _safeDoubleOrNull(record['check_in_latitude']);
        _checkInLon = _safeDoubleOrNull(record['check_in_longitude']);
        _distanceFromOfficeIn = _safeDoubleOrNull(record['check_in_distance']);
        _distanceFromOfficeOut = _safeDoubleOrNull(record['check_out_distance']);

        // Start elapsed timer if still working
        if (_isCheckedIn && !_isCheckedOut) {
          _startElapsedTimer();
        }
      } else {
        // No record for today -- fresh state
        _isCheckedIn = false;
        _isCheckedOut = false;
        _checkInTime = null;
        _checkOutTime = null;
      }
    } catch (e) {
      debugPrint('_fetchTodayStatus error: $e');
      // Reset to safe defaults on unexpected error
      _isCheckedIn = false;
      _isCheckedOut = false;
      _checkInTime = null;
      _checkOutTime = null;
      _isPunchInAllowed = true;
      _isPunchOutAllowed = true;
      _disabledReason = null;
    } finally {
      notifyListeners();
    }
  }

  // -- Fetch monthly attendance from backend --
  Future<void> _fetchMonthlyAttendance() async {
    _isLoadingMonthly = true;
    _monthlyError = null;
    notifyListeners();

    try {
      final raw = await _api.getAuth('/attendance/monthly');
      if (raw == null) {
        _monthlyError = 'No data received';
        _isLoadingMonthly = false;
        notifyListeners();
        return;
      }

      // Backend returns { monthly: {...}, daily: [...] }
      final monthlyRaw = raw['monthly'] as Map<String, dynamic>?;
      final dailyRaw = raw['daily'] as List?;

      final List<AttendanceRecord> records = (dailyRaw ?? [])
          .map((r) =>
              AttendanceRecord.fromBackendJson(r as Map<String, dynamic>))
          .toList();

      // Determine defect-day counts from daily records (fallback if monthly row absent)
      int presentDays = 0;
      int absentDays = 0;
      int lateDays = 0;
      int halfDays = 0;
      int weekends = 0;
      int holidays = 0;
      double attendancePct = 0.0;
      int totalWorkingDays = 0;

      if (monthlyRaw != null && monthlyRaw.isNotEmpty) {
        // Use the pre-aggregated monthly row
        _currentMonth = MonthlyAttendance.fromBackendJson(
          monthlyRaw,
          records: records,
        );
      } else if (records.isNotEmpty) {
        // Aggregate from daily records
        for (final r in records) {
          switch (r.status) {
            case AttendanceStatus.present:
              presentDays++;
              break;
            case AttendanceStatus.absent:
              absentDays++;
              break;
            case AttendanceStatus.late:
              lateDays++;
              presentDays++; // late still counts as present
              break;
            case AttendanceStatus.halfDay:
              halfDays++;
              break;
            case AttendanceStatus.weekend:
              weekends++;
              break;
            case AttendanceStatus.holiday:
              holidays++;
              break;
          }
        }
        totalWorkingDays = presentDays + absentDays + lateDays + halfDays;
        if (totalWorkingDays > 0) {
          attendancePct = ((presentDays + lateDays + (halfDays * 0.5)) /
                  totalWorkingDays *
                  100)
              .clamp(0.0, 100.0)
              .toDouble();
        }

        _currentMonth = MonthlyAttendance(
          month: DateTime.now().month,
          year: DateTime.now().year,
          totalDays: totalWorkingDays + weekends + holidays,
          presentDays: presentDays,
          absentDays: absentDays,
          lateDays: lateDays,
          halfDays: halfDays,
          weekends: weekends,
          holidays: holidays,
          totalOvertime: Duration.zero,
          attendancePercentage: attendancePct,
          records: records,
        );
      }

      _isLoadingMonthly = false;
      notifyListeners();
    } catch (e) {
      _monthlyError = e.toString();
      _isLoadingMonthly = false;
      notifyListeners();
      debugPrint('_fetchMonthlyAttendance error: $e');
    }
  }

  // -- Geo-fence check --
  /// Called by the screen when it wants to refresh location.
  Future<void> refreshLocation() async {
    await _acquireDeviceLocation();
  }

  void updateLocation(double lat, double lon) {
    _currentLat = lat;
    _currentLon = lon;
    _recalculateGeoFence();
    notifyListeners();
  }

  // -- Google Maps API key (lazy-loaded) --

  /// Fetch the Google Maps API key from the backend, matching the web app's
  /// `/config/maps-key` endpoint. Only called when the user taps "View Map".
  Future<void> fetchGoogleMapsKey() async {
    if (_currentLat == null || _currentLon == null) {
      await _acquireDeviceLocation();
    }

    if (_mapsState == GoogleMapsState.keyReady) {
      // Already fetched — just show the map
      _showMap = true;
      notifyListeners();
      return;
    }

    _mapsState = GoogleMapsState.fetchingKey;
    _mapsError = null;
    notifyListeners();

    try {
      final data = await _api.getAuth('/config/maps-key');
      if (data != null && data['googleMapsApiKey'] != null &&
          (data['googleMapsApiKey'] as String).isNotEmpty) {
        _googleMapsApiKey = data['googleMapsApiKey'] as String;
        _mapsState = GoogleMapsState.keyReady;
        _showMap = true;
      } else {
        _googleMapsApiKey = null;
        _mapsState = GoogleMapsState.keyMissing;
        _mapsError =
            'Google Maps API key not configured. Contact your administrator.';
      }
    } catch (e) {
      _googleMapsApiKey = null;
      _mapsState = GoogleMapsState.error;
      _mapsError = 'Failed to load map key: $e';
      debugPrint('fetchGoogleMapsKey error: $e');
    }

    notifyListeners();
  }

  /// Hide the map (user collapsed it or scrolled away).
  void hideMap() {
    _showMap = false;
    notifyListeners();
  }

  // -- Punch In --
  /// Sends the real device GPS coordinates to the backend so server-side
  /// geo-fence validation works correctly against the employee's office.
  Future<void> punchIn({String? photoPath}) async {
    if (_isCheckedIn && !_isCheckedOut) {
      _punchResultMessage = 'Already checked in today!';
      _isPunchError = true;
      notifyListeners();
      return;
    }

    _isPunching = true;
    _punchResultMessage = null;
    _isPunchError = false;
    notifyListeners();

    // Acquire device location on demand right before punching
    await _acquireDeviceLocation();
    if (_locationError != null) {
      _punchResultMessage = _locationError;
      _isPunchError = true;
      _isPunching = false;
      notifyListeners();
      return;
    }

    try {
      final lat = _currentLat;
      final lon = _currentLon;

      final result = await _api.postAuth('/attendance/punch-in', {
        'latitude': lat,
        'longitude': lon,
      });

      if (result != null) {
        final checkInRaw = result['check_in_time'];
        final now = AttendanceRecord.parseDateTime(
              checkInRaw,
              fallbackDate: DateTime.now(),
            ) ??
            DateTime.now();

        _isCheckedIn = true;
        _isCheckedOut = false;
        _checkInTime = now;
        _checkOutTime = null;
        _checkInLat = lat;
        _checkInLon = lon;

        final lateMins = _safeInt(result['late_by_minutes']);
        _isLateToday = lateMins > 0;
        _lateByMinutes = lateMins;
        _distanceFromOfficeIn = _currentDistance;
        if (photoPath != null) _photoPathIn = photoPath;

        final cin = formattedCheckIn;
        _punchResultMessage = _isLateToday
            ? 'Punched in at $cin (Late by $lateMins min)'
            : 'Punched in successfully at $cin';
        _isPunchError = false;

        _todayPunches.add(PunchRecord(
          type: PunchType.punchIn,
          timestamp: now,
          latitude: lat ?? 0,
          longitude: lon ?? 0,
          locationName: _checkInLocation,
          distanceFromOffice: _currentDistance,
          geoFenceStatus: _geoFenceStatus,
          isLate: _isLateToday,
          lateByMinutes: _isLateToday ? _lateByMinutes : null,
          photoPath: _photoPathIn,
        ));

        // Start live elapsed timer
        _startElapsedTimer();
      }
    } on ApiException catch (e) {
      _punchResultMessage = e.message;
      _isPunchError = true;
    } catch (e) {
      _punchResultMessage = 'Punch in failed: $e';
      _isPunchError = true;
    }

    _isPunching = false;
    notifyListeners();
  }

  // -- Punch Out --
  /// Sends the real device GPS coordinates to the backend so server-side
  /// geo-fence validation works correctly against the employee's office.
  Future<void> punchOut({String? photoPath}) async {
    if (!_isCheckedIn) {
      _punchResultMessage = 'You must punch in first!';
      _isPunchError = true;
      notifyListeners();
      return;
    }

    if (_isCheckedOut) {
      _punchResultMessage = 'Already checked out today!';
      _isPunchError = true;
      notifyListeners();
      return;
    }

    _isPunching = true;
    _punchResultMessage = null;
    _isPunchError = false;
    notifyListeners();

    // Acquire device location on demand right before punching
    await _acquireDeviceLocation();
    if (_locationError != null) {
      _punchResultMessage = _locationError;
      _isPunchError = true;
      _isPunching = false;
      notifyListeners();
      return;
    }

    try {
      final lat = _currentLat;
      final lon = _currentLon;

      final result = await _api.postAuth('/attendance/punch-out', {
        'latitude': lat,
        'longitude': lon,
      });

      if (result != null) {
        final checkOutRaw = result['check_out_time'];
        final now = AttendanceRecord.parseDateTime(
              checkOutRaw,
              fallbackDate: DateTime.now(),
            ) ??
            DateTime.now();

        _isCheckedOut = true;
        _checkOutTime = now;
        _distanceFromOfficeOut = _currentDistance;
        _totalHoursVal = _safeInt(result['total_hours']);
        _totalMinutesVal = _safeInt(result['total_minutes']);
        if (photoPath != null) _photoPathOut = photoPath;

        final cout = formattedCheckOut;
        final th = formattedTotalHours;
        _punchResultMessage =
            'Punched out successfully at $cout. Total: $th';
        _isPunchError = false;

        _todayPunches.add(PunchRecord(
          type: PunchType.punchOut,
          timestamp: now,
          latitude: lat ?? 0,
          longitude: lon ?? 0,
          locationName: _checkInLocation,
          distanceFromOffice: _currentDistance,
          geoFenceStatus: _geoFenceStatus,
          photoPath: _photoPathOut,
        ));

        // Stop live elapsed timer
        _elapsedTimer?.cancel();

        // Refresh monthly data after punch-out
        _fetchMonthlyAttendance();
      }
    } on ApiException catch (e) {
      _punchResultMessage = e.message;
      _isPunchError = true;
    } catch (e) {
      _punchResultMessage = 'Punch out failed: $e';
      _isPunchError = true;
    }

    _isPunching = false;
    notifyListeners();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  /// Refresh monthly data (e.g., after punch-out).
  Future<void> refreshMonthly() async {
    await _fetchMonthlyAttendance();
  }

  /// Dismiss punch result snackbar message
  void clearPunchMessage() {
    _punchResultMessage = null;
    _isPunchError = false;
    notifyListeners();
  }

  // -- Safe numeric parsers (defensive against backend string values) --

  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  static double? _safeDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  /// Clears all punch and monthly data. Must be called on logout so the
  /// next user does not see previous session's attendance records.
  void reset() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _isCheckedIn = false;
    _isCheckedOut = false;
    _isPunchInAllowed = true;
    _isPunchOutAllowed = true;
    _checkInTime = null;
    _checkOutTime = null;
    _checkInLat = null;
    _checkInLon = null;
    _distanceFromOfficeIn = null;
    _distanceFromOfficeOut = null;
    _isLateToday = false;
    _lateByMinutes = 0;
    _totalHoursVal = 0;
    _totalMinutesVal = 0;
    _photoPathIn = null;
    _photoPathOut = null;
    _todayPunches.clear();
    _selectedOffice = null;
    _geoFenceStatus = GeoFenceStatus.unknown;
    _currentDistance = 0.0;
    _currentLat = null;
    _currentLon = null;
    _isLoadingLocation = false;
    _locationError = null;
    _currentMonth = null;
    _isLoadingMonthly = false;
    _monthlyError = null;
    _isPunching = false;
    _punchResultMessage = null;
    _isPunchError = false;
    _mapsState = GoogleMapsState.uninitialised;
    _googleMapsApiKey = null;
    _mapsError = null;
    _showMap = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }
}