import '../../models/attendance.dart';
import '../../models/employee.dart';
import 'mock_auth.dart';
import 'dart:math';

/// Indian holidays for 2026 (fixed + variable dates)
class _IndianHolidays {
  static const _holidays2026 = [
    '2026-01-26',
    '2026-03-04',
    '2026-03-20',
    '2026-04-14',
    '2026-05-01',
    '2026-08-15',
    '2026-09-07',
    '2026-10-02',
    '2026-10-19',
    '2026-11-08',
    '2026-12-25',
  ];

  static bool isHoliday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays2026.contains(key);
  }
}

class MockAttendanceData {
  static final _random = Random();

  static Employee get employee => MockAuth.currentEmployee;

  static List<MonthlyAttendance> getMonthlyAttendance() {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => _generateMonthlyAttendance(
        DateTime(now.year, now.month - i, 1),
      ),
    );
    return months;
  }

  static MonthlyAttendance getCurrentMonthAttendance() {
    final now = DateTime.now();
    return _generateMonthlyAttendance(DateTime(now.year, now.month, 1));
  }

  static MonthlyAttendance _generateMonthlyAttendance(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final records = <AttendanceRecord>[];

    int present = 0;
    int absent = 0;
    int late = 0;
    int halfDay = 0;
    int weekends = 0;
    int holidays = 0;

    for (var day = 1; day <= min(day, daysInMonth); day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);

      // Skip future dates
      if (date.isAfter(DateTime.now())) break;

      // Check for holidays first
      if (_IndianHolidays.isHoliday(date)) {
        holidays++;
        records.add(AttendanceRecord(
          id: 'ATT-${monthDate.month}-$day',
          employee: employee,
          date: date,
          status: AttendanceStatus.holiday,
        ));
        continue;
      }

      final isWeekend = date.weekday == 6 || date.weekday == 7;

      if (isWeekend) {
        weekends++;
        records.add(AttendanceRecord(
          id: 'ATT-${monthDate.month}-$day',
          employee: employee,
          date: date,
          status: AttendanceStatus.weekend,
        ));
        continue;
      }

      // Simulate attendance pattern (90% present, 5% late, 5% absent)
      final rand = _random.nextDouble();
      AttendanceStatus status;
      DateTime? checkIn;
      DateTime? checkOut;
      bool isLate = false;
      Duration? lateBy;

      if (rand < 0.85) {
        status = AttendanceStatus.present;
        checkIn = DateTime(date.year, date.month, date.day, 9, _random.nextInt(30));
        checkOut = DateTime(date.year, date.month, date.day, 17, 30 + _random.nextInt(60));
        present++;
      } else if (rand < 0.92) {
        status = AttendanceStatus.late;
        final lateMinutes = 15 + _random.nextInt(120);
        checkIn = DateTime(date.year, date.month, date.day, 9 + lateMinutes ~/ 60, lateMinutes % 60);
        checkOut = DateTime(date.year, date.month, date.day, 17, 30 + _random.nextInt(60));
        isLate = true;
        lateBy = Duration(minutes: lateMinutes);
        late++;
      } else if (rand < 0.96) {
        status = AttendanceStatus.halfDay;
        checkIn = DateTime(date.year, date.month, date.day, 9, _random.nextInt(30));
        checkOut = DateTime(date.year, date.month, date.day, 13, _random.nextInt(60));
        halfDay++;
      } else {
        status = AttendanceStatus.absent;
        absent++;
      }

      final totalHours = checkIn != null && checkOut != null
          ? checkOut.difference(checkIn)
          : null;

      records.add(AttendanceRecord(
        id: 'ATT-${monthDate.month}-$day',
        employee: employee,
        date: date,
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
        checkInMethod: CheckInMethod.biometric,
        checkInLocation: 'Indore Hub - Main Gate',
        latitude: 22.7196,
        longitude: 75.8577,
        totalHours: totalHours,
        isLate: isLate,
        lateBy: lateBy,
      ));
    }

    final totalDays = records.length;
    final attendedCount = present + late;
    final percentage = totalDays > 0 ? ((attendedCount + halfDay * 0.5) / (totalDays - weekends) * 100).clamp(0.0, 100.0).toDouble() : 0.0;

    return MonthlyAttendance(
      month: monthDate.month,
      year: monthDate.year,
      totalDays: totalDays,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      halfDays: halfDay,
      weekends: weekends,
      holidays: holidays,
      tourDays: 0,
      totalOvertime: const Duration(hours: 4, minutes: 30),
      attendancePercentage: percentage,
      records: records,
    );
  }

  static List<AttendanceRecord> getRecentRecords({int count = 10}) {
    final month = getCurrentMonthAttendance();
    return month.records.reversed.take(count).toList();
  }

  static Map<String, dynamic> getTodayStatus() {
    final month = getCurrentMonthAttendance();
    final today = DateTime.now();
    final todayRecord = month.records.where((r) {
      return r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day;
    }).firstOrNull;

    return {
      'isCheckedIn': todayRecord?.checkIn != null,
      'isCheckedOut': todayRecord?.checkOut != null,
      'checkInTime': todayRecord?.formattedCheckIn ?? '--:--',
      'checkOutTime': todayRecord?.formattedCheckOut ?? '--:--',
      'status': todayRecord?.statusLabel ?? 'Not Marked',
      'totalHours': todayRecord?.totalHours?.inHours.toString() ?? '0',
      'totalMinutes': todayRecord?.totalHours?.inMinutes.remainder(60).toString() ?? '0',
    };
  }

}