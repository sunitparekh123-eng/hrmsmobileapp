import 'employee.dart';

enum AttendanceStatus { present, absent, late, halfDay, weekend, holiday, tour }

enum CheckInMethod { biometric, gps, manual, qrCode, web }

class AttendanceRecord {
  final String id;
  final Employee? employee; // nullable — backend records don't embed Employee
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final CheckInMethod checkInMethod;
  final String? checkInLocation;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final Duration? totalHours;
  final Duration? overtime;
  final bool isLate;
  final Duration? lateBy;
  final int? lateByMinutes;
  final int? earlyExitMinutes;
  final double? checkInDistance;
  final double? checkOutDistance;

  const AttendanceRecord({
    required this.id,
    this.employee,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.checkInMethod = CheckInMethod.biometric,
    this.checkInLocation,
    this.latitude,
    this.longitude,
    this.notes,
    this.totalHours,
    this.overtime,
    this.isLate = false,
    this.lateBy,
    this.lateByMinutes,
    this.earlyExitMinutes,
    this.checkInDistance,
    this.checkOutDistance,
  });

  /// Parse a datetime value from the backend that may be:
  /// - Full ISO datetime (e.g., "2025-01-15T09:30:00.000Z")
  /// - Plain date (e.g., "2025-01-15")
  /// - Time only (e.g., "03:35:00") — MySQL TIME type, needs [fallbackDate]
  /// - Date object
  static DateTime? parseDateTime(dynamic raw, {DateTime? fallbackDate}) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // Try full ISO parse first
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {}

    // Try time-only format (HH:MM:SS) — MySQL TIME type
    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2}):?(\d{2})?$').firstMatch(s);
    if (timeMatch != null && fallbackDate != null) {
      final h = int.parse(timeMatch.group(1)!);
      final m = int.parse(timeMatch.group(2)!);
      final sec = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
      var utcDateTime = DateTime.utc(
        fallbackDate.year, fallbackDate.month, fallbackDate.day,
        h, m, sec,
      );
      var localDateTime = utcDateTime.toLocal();
      if (localDateTime.day != fallbackDate.day) {
        final diffDays = localDateTime.day - fallbackDate.day;
        utcDateTime = utcDateTime.subtract(Duration(days: diffDays));
        localDateTime = utcDateTime.toLocal();
      }
      return localDateTime;
    }

    // Try date-only format (YYYY-MM-DD)
    try {
      return DateTime.parse('${s}T00:00:00.000');
    } catch (_) {}

    return null;
  }

  /// Parse a record from the backend JSON shape (snake_case).
  factory AttendanceRecord.fromBackendJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'absent';
    final status = _parseStatus(statusStr);

    final dateRaw = json['date'];
    final date = dateRaw != null
        ? (dateRaw is String ? DateTime.parse(dateRaw) : DateTime.now())
        : DateTime.now();

    final checkIn = parseDateTime(json['check_in_time'], fallbackDate: date);
    final checkOut = parseDateTime(json['check_out_time'], fallbackDate: date);

    final totalHoursVal = json['total_hours'];
    final totalMinutesVal = json['total_minutes'];
    Duration? totalHours;
    if (totalHoursVal != null && totalMinutesVal != null) {
      totalHours = Duration(
        hours: _safeInt(totalHoursVal),
        minutes: _safeInt(totalMinutesVal),
      );
    } else if (checkIn != null && checkOut != null) {
      totalHours = checkOut.difference(checkIn);
    }

    final overtimeMins = json['overtime_minutes'];
    final overtime = overtimeMins != null
        ? Duration(minutes: _safeInt(overtimeMins))
        : null;

    final lateMins = json['late_by_minutes'];
    final lateBy = lateMins != null
        ? Duration(minutes: _safeInt(lateMins))
        : null;

    final methodStr = json['check_in_method'] as String? ?? 'web';
    final method = _parseMethod(methodStr);

    return AttendanceRecord(
      id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      date: date,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
      checkInMethod: method,
      checkInLocation: json['check_in_location'] as String?,
      latitude: _safeDouble(json['check_in_latitude']),
      longitude: _safeDouble(json['check_in_longitude']),
      totalHours: totalHours,
      overtime: overtime,
      isLate: status == AttendanceStatus.late,
      lateBy: lateBy,
      lateByMinutes: _safeIntOrNull(json['late_by_minutes']),
      earlyExitMinutes: _safeIntOrNull(json['early_exit_minutes']),
      checkInDistance: _safeDouble(json['check_in_distance']),
      checkOutDistance: _safeDouble(json['check_out_distance']),
    );
  }

  static AttendanceStatus _parseStatus(String s) {
    switch (s) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'half_day':
        return AttendanceStatus.halfDay;
      case 'weekend':
        return AttendanceStatus.weekend;
      case 'holiday':
        return AttendanceStatus.holiday;
      case 'tour':
        return AttendanceStatus.tour;
      default:
        return AttendanceStatus.absent;
    }
  }

  static CheckInMethod _parseMethod(String s) {
    switch (s) {
      case 'biometric':
        return CheckInMethod.biometric;
      case 'gps':
        return CheckInMethod.gps;
      case 'manual':
        return CheckInMethod.manual;
      case 'qr_code':
        return CheckInMethod.qrCode;
      case 'web':
        return CheckInMethod.web;
      default:
        return CheckInMethod.biometric;
    }
  }

  // -- Safe numeric parsers (handle String | num | null from backend) --

  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _safeIntOrNull(dynamic value) {
    if (value == null) return null;
    return _safeInt(value);
  }

  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.weekend:
        return 'Weekend';
      case AttendanceStatus.holiday:
        return 'Holiday';
      case AttendanceStatus.tour:
        return 'Tour';
    }
  }

  /// Short letter code for calendar display
  String get statusLetter {
    switch (status) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.halfDay:
        return 'HD';
      case AttendanceStatus.weekend:
        return 'W';
      case AttendanceStatus.holiday:
        return 'H';
      case AttendanceStatus.tour:
        return 'T';
    }
  }

  String get formattedCheckIn =>
      checkIn != null
          ? '${checkIn!.hour.toString().padLeft(2, '0')}:${checkIn!.minute.toString().padLeft(2, '0')}'
          : '--:--';
  String get formattedCheckOut =>
      checkOut != null
          ? '${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}'
          : '--:--';
}

class MonthlyAttendance {
  final int month;
  final int year;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final int weekends;
  final int holidays;
  final int tourDays;
  final Duration totalOvertime;
  final double attendancePercentage;
  final List<AttendanceRecord> records;

  const MonthlyAttendance({
    required this.month,
    required this.year,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.weekends,
    required this.holidays,
    required this.tourDays,
    required this.totalOvertime,
    required this.attendancePercentage,
    required this.records,
  });

  /// Parse from backend monthly record JSON (snake_case).
  factory MonthlyAttendance.fromBackendJson(
    Map<String, dynamic> json, {
    List<AttendanceRecord> records = const [],
  }) {
    return MonthlyAttendance(
      month: _safeIntOr(json['month'], DateTime.now().month),
      year: _safeIntOr(json['year'], DateTime.now().year),
      totalDays: _safeIntOr(json['total_working_days'], 0),
      presentDays: _safeIntOr(json['present_days'], 0),
      absentDays: _safeIntOr(json['absent_days'], 0),
      lateDays: _safeIntOr(json['late_days'], 0),
      halfDays: _safeIntOr(json['half_days'], 0),
      weekends: _safeIntOr(json['weekend_days'], 0),
      holidays: _safeIntOr(json['holiday_days'], 0),
      tourDays: _safeIntOr(json['tour_days'], 0),
      totalOvertime: Duration.zero,
      attendancePercentage:
          _safeDoubleOr(json['attendance_percentage'], 0.0),
      records: records,
    );
  }

  // -- Safe numeric parsers (handle String | num | null from backend) --

  /// Parse an int from a value that may be String or num.
  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse an int or return [fallback] if null.
  static int _safeIntOr(dynamic value, int fallback) {
    if (value == null) return fallback;
    return _safeInt(value);
  }

  /// Parse a double from a value that may be String or num.
  static double _safeDoubleOr(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}