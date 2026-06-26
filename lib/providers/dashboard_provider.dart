import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/payroll.dart';
import '../models/performance.dart';
import '../models/loans.dart';
import '../models/employee.dart';
import '../models/document.dart';
import '../models/letter.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  /// Dummy employee used for model constructors.
  /// The dashboard screen never accesses the `.employee` field on any model,
  /// so a minimal placeholder satisfies the constructor requirement.
  static final _dummyEmployee = Employee(
    id: '',
    name: '',
    email: '',
    branch: '',
    department: '',
    designation: '',
    employeeId: '',
    joiningDate: DateTime.now(),
  );

  // ── Attendance ────────────────────────────────────────────────────
  Map<String, dynamic> _todayStatus = {
    'isCheckedIn': false,
    'status': 'Not Marked',
    'checkInTime': '--:--',
    'checkOutTime': '--:--',
    'totalHours': '--',
    'totalMinutes': '--',
  };
  List<AttendanceRecord> _recentAttendance = [];
  MonthlyAttendance _currentMonthAttendance = _defaultMonthlyAttendance();

  // ── Leave ─────────────────────────────────────────────────────────
  List<LeaveBalance> _leaveBalances = [];
  List<LeaveRequest> _pendingLeaveRequests = [];
  List<LeaveRequest> _leaveRequests = [];

  // ── Payroll ───────────────────────────────────────────────────────
  Payslip _latestPayslip = _defaultPayslip();
  List<Map<String, dynamic>> _salarySummary = [];
  List<Payslip> _payslipsHistory = [];

  // ── Performance ───────────────────────────────────────────────────
  PerformanceMetrics _performanceMetrics = _defaultPerformanceMetrics();
  List<PerformanceObjective> _objectives = [];

  // ── Loans ─────────────────────────────────────────────────────────
  List<Loan> _activeLoans = [];
  List<Loan> _myLoans = [];
  double _totalRemaining = 0;

  // ── Documents & Letters ───────────────────────────────────────────
  List<EmployeeDocument> _myDocuments = [];
  List<EmployeeLetter> _myLetters = [];

  DashboardProvider(this._api);

  // ── Getters ───────────────────────────────────────────────────────
  Map<String, dynamic> get todayStatus => _todayStatus;
  List<AttendanceRecord> get recentAttendance => _recentAttendance;
  MonthlyAttendance get currentMonthAttendance => _currentMonthAttendance;
  List<LeaveBalance> get leaveBalances => _leaveBalances;
  List<LeaveRequest> get pendingLeaveRequests => _pendingLeaveRequests;
  List<LeaveRequest> get leaveRequests => _leaveRequests;
  Payslip get latestPayslip => _latestPayslip;
  List<Map<String, dynamic>> get salarySummary => _salarySummary;
  List<Payslip> get payslipsHistory => _payslipsHistory;
  PerformanceMetrics get performanceMetrics => _performanceMetrics;
  List<PerformanceObjective> get objectives => _objectives;
  List<Loan> get activeLoans => _activeLoans;
  List<Loan> get myLoans => _myLoans;
  double get totalRemaining => _totalRemaining;
  List<EmployeeDocument> get myDocuments => _myDocuments;
  List<EmployeeLetter> get myLetters => _myLetters;

  // ── Public API ────────────────────────────────────────────────────

  /// Fetch dashboard data from the backend.
  /// Data is pre-populated with safe defaults so widgets never see null;
  /// this call replaces defaults with real values and notifies once.
  Future<void> loadDashboard() async {
    try {
      final results = await Future.wait([
        _api.getAuth('/dashboard/summary'),
        _api.getAuth('/dashboard/stats'),
        _api.getAuth('/leave/my-requests'),
        _api.getAuth('/payroll/payslips'),
        _api.getAuth('/loans/my'),
        _api.getAuth('/documents/my'),
        _api.getAuth('/letters/my'),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      // results[1] = /dashboard/stats — available for future use

      _parseTodayStatus(summary);
      _parseRecentAttendance(summary);
      _parseMonthlyAttendance(summary);
      _parseLeaveBalances(summary);
      _parsePendingLeaves(summary);
      _parseLatestPayslip(summary);
      _parseSalarySummary(summary);
      _parseActiveLoans(summary);
      _parseTotalRemaining(summary);
      _parsePerformance();
      _parseLeaveRequests(results[2]);
      _parsePayslipsHistory(results[3]);
      _parseMyLoans(results[4]);
      _parseMyDocuments(results[5]);
      _parseMyLetters(results[6]);
    } catch (e, stack) {
      debugPrint('loadDashboard error: $e');
      debugPrint('stack: $stack');
    }

    notifyListeners();
  }

  void _parseLeaveRequests(dynamic raw) {
    if (raw is! List) {
      _leaveRequests = [];
      return;
    }
    final List<LeaveRequest> list = [];
    for (final item in raw) {
      if (item is Map) {
        try {
          list.add(LeaveRequest.fromBackendJson(Map<String, dynamic>.from(item), _dummyEmployee));
        } catch (e) {
          debugPrint('Error parsing leave request: $e');
        }
      }
    }
    _leaveRequests = list;
  }

  Future<void> applyLeave({
    required DateTime date,
    required String reason,
    String? contact,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final body = {
      'leave_type': 'el',
      'from_date': dateStr,
      'to_date': dateStr,
      'duration': 1,
      'reason': reason,
      if (contact != null && contact.isNotEmpty) 'contact_during_leave': contact,
    };
    await _api.postAuth('/leave/apply', body);
    await loadDashboard(); // Reload data after successful submission
  }

  Future<void> refresh() async {
    await loadDashboard();
  }

  /// Clears all cached data. Must be called on logout so the next user
  /// cannot see stale data from a previous session.
  void reset() {
    _todayStatus = {
      'isCheckedIn': false,
      'status': 'Not Marked',
      'checkInTime': '--:--',
      'checkOutTime': '--:--',
      'totalHours': '--',
      'totalMinutes': '--',
    };
    _recentAttendance = [];
    _currentMonthAttendance = _defaultMonthlyAttendance();
    _leaveBalances = [];
    _pendingLeaveRequests = [];
    _leaveRequests = [];
    _latestPayslip = _defaultPayslip();
    _salarySummary = [];
    _payslipsHistory = [];
    _performanceMetrics = _defaultPerformanceMetrics();
    _objectives = [];
    _activeLoans = [];
    _myLoans = [];
    _totalRemaining = 0;
    _myDocuments = [];
    _myLetters = [];
    notifyListeners();
  }

  // ── Default factories ─────────────────────────────────────────────

  static MonthlyAttendance _defaultMonthlyAttendance() {
    final now = DateTime.now();
    return MonthlyAttendance(
      month: now.month,
      year: now.year,
      totalDays: 0,
      presentDays: 0,
      absentDays: 0,
      lateDays: 0,
      halfDays: 0,
      weekends: 0,
      holidays: 0,
      totalOvertime: Duration.zero,
      attendancePercentage: 0,
      records: const [],
    );
  }

  static Payslip _defaultPayslip() {
    return Payslip(
      id: '',
      employee: _dummyEmployee,
      month: '--',
      generatedOn: DateTime.now(),
      basic: 0,
      hra: 0,
      grossSalary: 0,
      pfEmployee: 0,
      totalDeductions: 0,
      netSalary: 0,
      workingDays: 0,
      paidDays: 0,
    );
  }

  static PerformanceMetrics _defaultPerformanceMetrics() {
    return PerformanceMetrics(
      recognitionPoints: 0,
      rating: 0,
      objectivesCompleted: 0,
      totalObjectives: 0,
      appraisalCycle: DateTime.now().year,
      projectVelocity: 'Medium',
      strategicAlignment: 0,
    );
  }

  // ── Parsers ───────────────────────────────────────────────────────

  void _parseTodayStatus(Map<String, dynamic> summary) {
    final today = summary['today_attendance'];
    if (today == null) {
      _todayStatus = {
        'isCheckedIn': false,
        'status': 'Not Marked',
        'checkInTime': '--:--',
        'checkOutTime': '--:--',
        'totalHours': '--',
        'totalMinutes': '--',
      };
      return;
    }
    final m = today as Map<String, dynamic>;
    final status = (m['status'] as String? ?? 'absent').toLowerCase();

    // Parse the date for fallback when times are MySQL TIME type (e.g. "03:35:00")
    final fallbackDate = m['date'] is String
        ? DateTime.tryParse(m['date'] as String)
        : null;
    final fbd = fallbackDate ?? DateTime.now();

    // Format check-in / check-out times — handles ISO datetime, MySQL TIME, and null
    String formatTime(dynamic raw) {
      if (raw == null) return '--:--';
      final dt = AttendanceRecord.parseDateTime(raw, fallbackDate: fbd);
      if (dt == null) return '--:--';
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    // Format hours/minutes from backend numeric fields defensively
    final h = m['total_hours'];
    final min = m['total_minutes'];

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final parsedMinutes = parseInt(min);
    final finalHours = parsedMinutes ~/ 60;
    final finalMinutes = parsedMinutes % 60;

    final hoursStr = h != null ? finalHours.toString() : '--';
    final minutesStr = min != null ? finalMinutes.toString() : '--';

    final parsedCheckIn = AttendanceRecord.parseDateTime(m['check_in_time'], fallbackDate: fbd);
    final parsedCheckOut = AttendanceRecord.parseDateTime(m['check_out_time'], fallbackDate: fbd);

    _todayStatus = {
      'isCheckedIn': parsedCheckIn != null,
      'isCheckedOut': parsedCheckOut != null,
      'status': _statusLabel(status),
      'checkInTime': formatTime(m['check_in_time']),
      'checkOutTime': formatTime(m['check_out_time']),
      'totalHours': hoursStr,
      'totalMinutes': minutesStr,
    };
  }

  void _parseRecentAttendance(Map<String, dynamic> summary) {
    // Use daily_attendance from backend for recent records (most recent 5)
    final dailyRaw = summary['daily_attendance'] as List<dynamic>?;
    if (dailyRaw != null && dailyRaw.isNotEmpty) {
      final List<AttendanceRecord> records = [];
      for (final item in dailyRaw) {
        if (item is Map) {
          try {
            records.add(AttendanceRecord.fromBackendJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('Error parsing daily attendance for recent: $e');
          }
        }
      }
      _recentAttendance = records
        ..sort((a, b) => b.date.compareTo(a.date)); // newest first
      // Keep last 5 for the "recent" view
      if (_recentAttendance.length > 5) {
        _recentAttendance = _recentAttendance.sublist(0, 5);
      }
      return;
    }

    // Fallback: use today_attendance if no daily records
    final today = summary['today_attendance'];
    if (today == null) {
      _recentAttendance = [];
      return;
    }
    final m = today as Map<String, dynamic>;
    final fallbackDate = today['date'] is String
        ? DateTime.tryParse(today['date'] as String)
        : null;
    final fbd = fallbackDate ?? DateTime.now();
    _recentAttendance = [
      AttendanceRecord(
        id: (m['id'] as num?)?.toString() ?? 'today',
        employee: _dummyEmployee,
        date: fbd,
        status: _parseAttendanceStatus(m['status'] as String?),
        checkIn: AttendanceRecord.parseDateTime(
          m['check_in_time'],
          fallbackDate: fbd,
        ),
        checkOut: AttendanceRecord.parseDateTime(
          m['check_out_time'],
          fallbackDate: fbd,
        ),
        checkInMethod: CheckInMethod.biometric,
        latitude: m['check_in_latitude'] != null ? double.tryParse(m['check_in_latitude'].toString()) : null,
        longitude: m['check_in_longitude'] != null ? double.tryParse(m['check_in_longitude'].toString()) : null,
        isLate: m['late_by_minutes'] != null &&
            (int.tryParse(m['late_by_minutes'].toString()) ?? 0) > 0,
        lateBy: m['late_by_minutes'] != null
            ? Duration(minutes: int.tryParse(m['late_by_minutes'].toString()) ?? 0)
            : null,
        totalHours: m['total_hours'] != null
            ? Duration(hours: (double.tryParse(m['total_hours'].toString()) ?? 0.0).toInt())
            : null,
      ),
    ];
  }

  void _parseMonthlyAttendance(Map<String, dynamic> summary) {
    final ma = summary['monthly_attendance'];
    final dailyRaw = summary['daily_attendance'] as List<dynamic>?;

    // Parse daily records for calendar display safely
    final List<AttendanceRecord> records = [];
    if (dailyRaw != null) {
      for (final item in dailyRaw) {
        if (item is Map) {
          try {
            records.add(AttendanceRecord.fromBackendJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('Error parsing daily attendance for monthly: $e');
          }
        }
      }
    }

    if (ma == null) {
      // If we have daily records but no monthly row, aggregate from dailies
      if (records.isNotEmpty) {
        int presentDays = 0;
        int absentDays = 0;
        int lateDays = 0;
        int halfDays = 0;
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
              presentDays++;
              break;
            case AttendanceStatus.halfDay:
              halfDays++;
              break;
            default:
              break;
          }
        }
        final totalWorking = presentDays + absentDays + lateDays + halfDays;
        final pct = totalWorking > 0
            ? ((presentDays + lateDays + (halfDays * 0.5)) / totalWorking * 100)
                .clamp(0.0, 100.0)
            : 0.0;
        _currentMonthAttendance = MonthlyAttendance(
          month: DateTime.now().month,
          year: DateTime.now().year,
          totalDays: totalWorking,
          presentDays: presentDays,
          absentDays: absentDays,
          lateDays: lateDays,
          halfDays: halfDays,
          weekends: 0,
          holidays: 0,
          totalOvertime: Duration.zero,
          attendancePercentage: pct,
          records: records,
        );
      } else {
        _currentMonthAttendance = _defaultMonthlyAttendance();
      }
      return;
    }

    final m = ma as Map<String, dynamic>;
    _currentMonthAttendance = MonthlyAttendance(
      month: _safeInt(m['month']),
      year: _safeInt(m['year']),
      totalDays: _safeInt(m['total_working_days']),
      presentDays: _safeInt(m['present_days']),
      absentDays: _safeInt(m['absent_days']),
      lateDays: _safeInt(m['late_days']),
      halfDays: _safeInt(m['half_days']),
      weekends: _safeInt(m['weekend_days']),
      holidays: _safeInt(m['holiday_days']),
      totalOvertime: Duration.zero,
      attendancePercentage: _safeDouble(m['attendance_percentage']),
      records: records,
    );
  }

  void _parseLeaveBalances(Map<String, dynamic> summary) {
    final balances = summary['leave_balances'] as List<dynamic>?;
    if (balances == null || balances.isEmpty) {
      _leaveBalances = [];
      return;
    }
    _leaveBalances = balances.map((b) {
      final m = b as Map<String, dynamic>;
      return LeaveBalance(
        available: m['available'] as int? ?? 0,
        used: m['used'] as int? ?? 0,
        adminGranted: m['admin_granted'] as int? ?? 0,
        lapsed: m['lapsed'] as int? ?? 0,
        lastAccrualMonth: m['last_accrual_month'] as String? ?? '',
        consecutiveNoUsageMonths:
            m['consecutive_no_usage_months'] as int? ?? 0,
      );
    }).toList();
  }

  void _parsePendingLeaves(Map<String, dynamic> summary) {
    final count = summary['pending_leaves'] as int? ?? 0;
    _pendingLeaveRequests = List.generate(
      count,
      (i) => LeaveRequest(
        id: 'pending_$i',
        employee: _dummyEmployee,
        type: LeaveType.el,
        appliedOn: DateTime.now(),
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
        duration: 1,
        reason: '',
        status: LeaveStatus.pending,
      ),
    );
  }

  void _parseLatestPayslip(Map<String, dynamic> summary) {
    final ps = summary['latest_payslip'];
    if (ps == null) {
      _latestPayslip = _defaultPayslip();
      return;
    }
    final m = ps as Map<String, dynamic>;
    final monthStr = m['month'] as String? ?? '';
    final year = m['year'] as int? ?? DateTime.now().year;

    final basic = _safeDouble(m['basic_salary']);
    final hra = _safeDouble(m['hra']);
    final conveyance = _safeDouble(m['conveyance']);
    final medical = _safeDouble(m['medical_allowance']);
    final specialAllowance = _safeDouble(m['special_allowance']);
    final otherAllowance = _safeDouble(m['other_allowance']);
    final pfEmployee = _safeDouble(m['pf_employee']);
    final esiEmployee = _safeDouble(m['esi_employee']);
    final professionalTax = _safeDouble(m['professional_tax']);

    _latestPayslip = Payslip(
      id: m['id']?.toString() ?? '',            // '' when live calculation
      employee: _dummyEmployee,
      month: '$monthStr $year',
      monthIndex: _safeInt(m['month_index']),
      generatedOn: DateTime.now(),
      basic: basic,
      hra: hra,
      conveyance: conveyance,
      medical: medical,
      specialAllowance: specialAllowance,
      otherAllowance: otherAllowance,
      grossSalary: _safeDouble(m['gross_salary']),
      pfEmployee: pfEmployee,
      esiEmployee: esiEmployee,
      professionalTax: professionalTax,
      totalDeductions: _safeDouble(m['total_deductions']),
      pfEmployer: _safeDouble(m['pf_employer']),
      esiEmployer: _safeDouble(m['esi_employer']),
      netSalary: _safeDouble(m['net_salary']),
      workingDays: _safeInt(m['working_days']),
      paidDays: _safeInt(m['paid_days']),
      lopDays: _safeDouble(m['lop_days']).toInt(),
      paymentStatus: m['status'] as String? ?? 'Processing',
      earnings: [
        SalaryComponent(name: 'Basic Salary', amount: basic),
        SalaryComponent(name: 'HRA', amount: hra),
        if (otherAllowance > 0) SalaryComponent(name: 'Other Allowance', amount: otherAllowance),
        if (conveyance > 0) SalaryComponent(name: 'Conveyance Allowance', amount: conveyance),
        if (medical > 0) SalaryComponent(name: 'Medical Allowance', amount: medical),
        if (specialAllowance > 0) SalaryComponent(name: 'Special Allowance', amount: specialAllowance),
      ],
      deductions: [
        if (pfEmployee > 0) SalaryComponent(name: 'PF (Employee)', amount: pfEmployee, isDeduction: true, description: '12% of Basic'),
        if (esiEmployee > 0) SalaryComponent(name: 'ESI (Employee)', amount: esiEmployee, isDeduction: true, description: '0.75% of Gross'),
        if (professionalTax > 0) SalaryComponent(name: 'Professional Tax', amount: professionalTax, isDeduction: true),
      ],
    );
  }

  void _parseSalarySummary(Map<String, dynamic> summary) {
    // Handled dynamically in _parsePayslipsHistory from actual payslip history and live calculations
  }

  void _parseActiveLoans(Map<String, dynamic> summary) {
    final loans = summary['active_loan_details'] as List<dynamic>?;
    if (loans == null || loans.isEmpty) {
      _activeLoans = [];
      return;
    }
    _activeLoans = loans.map((l) {
      final m = l as Map<String, dynamic>;
      final principal = _safeDouble(m['principal_amount']);
      final paidPct = _safeDouble(m['paid_percentage']);
      final totalPaid = principal * paidPct / 100;
      return Loan(
        id: m['id']?.toString() ?? '',
        employee: _dummyEmployee,
        type: _parseLoanType(m['type'] as String?),
        principal: principal,
        interestRate: _safeDouble(m['interest_rate']),
        tenureMonths: _safeInt(m['tenure_months']),
        emi: _safeDouble(m['emi_amount']),
        totalPaid: totalPaid,
        remainingAmount: _safeDouble(m['total_remaining']),
        status: _parseLoanStatus(m['status'] as String?),
        appliedOn: DateTime.now(),
        disbursedOn: m['disbursed_on'] != null
            ? DateTime.tryParse(m['disbursed_on'] as String)
            : null,
      );
    }).toList();
  }

  void _parseMyLoans(dynamic raw) {
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else {
      _myLoans = [];
      return;
    }
    
    _myLoans = items.map((item) {
      if (item is! Map) return null;
      final m = item as Map;
      final principal = _safeDouble(m['principal_amount']);
      final paidPct = _safeDouble(m['paid_percentage']);
      final totalPaid = principal * paidPct / 100;
      return Loan(
        id: m['id']?.toString() ?? '',
        employee: _dummyEmployee,
        type: _parseLoanType(m['type'] as String?),
        principal: principal,
        interestRate: _safeDouble(m['interest_rate']),
        tenureMonths: _safeInt(m['tenure_months']),
        emi: _safeDouble(m['emi_amount']),
        totalPaid: totalPaid,
        remainingAmount: _safeDouble(m['total_remaining']),
        status: _parseLoanStatus(m['status'] as String?),
        appliedOn: m['createdAt'] != null
            ? (DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now())
            : DateTime.now(),
        disbursedOn: m['disbursed_on'] != null
            ? DateTime.tryParse(m['disbursed_on'] as String)
            : null,
      );
    }).whereType<Loan>().toList();
  }

  void _parseTotalRemaining(Map<String, dynamic> summary) {
    _totalRemaining = _safeDouble(summary['total_loan_remaining']);
  }

  void _parsePerformance() {
    // Performance data is not yet available from the dashboard backend
    // endpoints. The performance screen will fetch its own data when
    // opened, so these defaults are sufficient for the dashboard view.
    _performanceMetrics = _defaultPerformanceMetrics();
    _objectives = [];
  }

  // ── Enum helpers ──────────────────────────────────────────────────

  static String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'half_day':
        return 'Half Day';
      case 'weekend':
        return 'Weekend';
      case 'holiday':
        return 'Holiday';
      default:
        return 'Absent';
    }
  }

  static AttendanceStatus _parseAttendanceStatus(String? status) {
    switch (status?.toLowerCase()) {
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
      default:
        return AttendanceStatus.absent;
    }
  }

  static LoanType _parseLoanType(String? type) {
    switch (type?.toLowerCase()) {
      case 'personal':
        return LoanType.personal;
      case 'vehicle':
        return LoanType.vehicle;
      case 'home':
      case 'housing':
        return LoanType.home;
      case 'medical':
      case 'emergency':
        return LoanType.medical;
      case 'education':
        return LoanType.education;
      default:
        return LoanType.personal;
    }
  }

  static LoanStatus _parseLoanStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return LoanStatus.active;
      case 'pending':
        return LoanStatus.pending;
      case 'closed':
        return LoanStatus.closed;
      case 'rejected':
        return LoanStatus.rejected;
      default:
        return LoanStatus.active;
    }
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _parsePayslipsHistory(dynamic raw) {
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else {
      _payslipsHistory = [];
      _salarySummary = [];
      return;
    }
    final List<Payslip> list = [];
    for (final item in items) {
      if (item is Map) {
        try {
          list.add(_parsePayslipFromBackend(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Error parsing payslip history: $e');
        }
      }
    }
    _payslipsHistory = list;

    // Dynamically construct _salarySummary (Salary Trend) from history + latest dynamic payslip
    final Map<String, Map<String, dynamic>> summaryMap = {};
    
    // Add historical payslips
    for (final p in _payslipsHistory) {
      final monthName = p.month.split(' ').first;
      final monthAbbr = monthName.length > 3 ? monthName.substring(0, 3) : monthName;
      final key = '${p.monthIndex}_${p.month}';
      summaryMap[key] = {
        'month': monthAbbr,
        'netSalary': p.netSalary,
      };
    }
    
    // Add latest dynamic/live payslip if it exists and has non-zero net salary
    if (_latestPayslip.month != '--' && _latestPayslip.netSalary > 0) {
      final monthName = _latestPayslip.month.split(' ').first;
      final monthAbbr = monthName.length > 3 ? monthName.substring(0, 3) : monthName;
      final key = '${_latestPayslip.monthIndex}_${_latestPayslip.month}';
      summaryMap[key] = {
        'month': monthAbbr,
        'netSalary': _latestPayslip.netSalary,
      };
    }
    
    // Sort keys by monthIndex (chronological order)
    final sortedKeys = summaryMap.keys.toList()
      ..sort((a, b) {
        final aIdx = int.tryParse(a.split('_').first) ?? 0;
        final bIdx = int.tryParse(b.split('_').first) ?? 0;
        return aIdx.compareTo(bIdx);
      });
      
    _salarySummary = sortedKeys.map((k) => summaryMap[k]!).toList();
  }

  Payslip _parsePayslipFromBackend(Map<String, dynamic> m) {
    final monthStr = m['month'] as String? ?? '';
    final year = m['year'] as int? ?? DateTime.now().year;
    final basic = _safeDouble(m['basic_salary']);
    final hra = _safeDouble(m['hra']);
    final conveyance = _safeDouble(m['conveyance']);
    final medical = _safeDouble(m['medical_allowance']);
    final specialAllowance = _safeDouble(m['special_allowance']);
    final otherAllowance = _safeDouble(m['other_allowance']);
    final pfEmployee = _safeDouble(m['pf_employee']);
    final esiEmployee = _safeDouble(m['esi_employee']);
    final professionalTax = _safeDouble(m['professional_tax']);
    final totalDeductions = _safeDouble(m['total_deductions']);
    final pfEmployer = _safeDouble(m['pf_employer']);
    final esiEmployer = _safeDouble(m['esi_employer']);
    final grossSalary = _safeDouble(m['gross_salary']);

    return Payslip(
      id: m['id']?.toString() ?? '',
      employee: _dummyEmployee,
      month: '$monthStr $year',
      monthIndex: _safeInt(m['month_index']),
      generatedOn: m['createdAt'] != null
          ? (DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      basic: basic,
      hra: hra,
      conveyance: conveyance,
      medical: medical,
      specialAllowance: specialAllowance,
      otherAllowance: otherAllowance,
      grossSalary: grossSalary,
      pfEmployee: pfEmployee,
      esiEmployee: esiEmployee,
      professionalTax: professionalTax,
      totalDeductions: totalDeductions,
      pfEmployer: pfEmployer,
      esiEmployer: esiEmployer,
      netSalary: _safeDouble(m['net_salary']),
      workingDays: _safeInt(m['working_days']),
      paidDays: _safeInt(m['paid_days']),
      lopDays: _safeInt(m['lop_days']),
      paymentStatus: m['status'] as String? ?? 'Paid',
      earnings: [
        SalaryComponent(name: 'Basic Salary', amount: basic),
        SalaryComponent(name: 'HRA', amount: hra),
        if (conveyance > 0) SalaryComponent(name: 'Conveyance Allowance', amount: conveyance),
        if (medical > 0) SalaryComponent(name: 'Medical Allowance', amount: medical),
        if (specialAllowance > 0) SalaryComponent(name: 'Special Allowance', amount: specialAllowance),
        if (otherAllowance > 0) SalaryComponent(name: 'Other Allowance', amount: otherAllowance),
      ],
      deductions: [
        if (pfEmployee > 0) SalaryComponent(name: 'PF (Employee)', amount: pfEmployee, isDeduction: true),
        if (esiEmployee > 0) SalaryComponent(name: 'ESI (Employee)', amount: esiEmployee, isDeduction: true),
        if (professionalTax > 0) SalaryComponent(name: 'Professional Tax', amount: professionalTax, isDeduction: true),
      ],
    );
  }

  void _parseMyDocuments(dynamic raw) {
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else {
      _myDocuments = [];
      return;
    }
    final List<EmployeeDocument> list = [];
    for (final item in items) {
      if (item is Map) {
        try {
          list.add(EmployeeDocument.fromBackendJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Error parsing document: $e');
        }
      }
    }
    _myDocuments = list;
  }

  void _parseMyLetters(dynamic raw) {
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else {
      _myLetters = [];
      return;
    }
    final List<EmployeeLetter> list = [];
    for (final item in items) {
      if (item is Map) {
        try {
          list.add(EmployeeLetter.fromBackendJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('Error parsing letter: $e');
        }
      }
    }
    _myLetters = list;
  }
}