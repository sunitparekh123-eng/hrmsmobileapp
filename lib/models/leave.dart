import 'employee.dart';

enum LeaveType { el }

enum LeaveStatus { pending, approved, rejected, cancelled }

class LeaveBalance {
  final int available;
  final int used;
  final int adminGranted;
  final int lapsed;
  final String lastAccrualMonth;
  final int consecutiveNoUsageMonths;

  const LeaveBalance({
    required this.available,
    required this.used,
    this.adminGranted = 0,
    this.lapsed = 0,
    this.lastAccrualMonth = '',
    this.consecutiveNoUsageMonths = 0,
  });

  String get label => 'Earned Leave';

  String get code => 'EL';

  /// Total leaves ever accrued (available + used + lapsed)
  int get totalAccrued => available + used + lapsed;

  /// Usage ratio against total accrued (for progress bar)
  double get usagePercentage =>
      totalAccrued > 0 ? (used / totalAccrued) * 100 : 0;
}

class LeaveRequest {
  final String id;
  final Employee employee;
  final LeaveType type;
  final DateTime appliedOn;
  final DateTime fromDate;
  final DateTime toDate;
  final int duration;
  final String reason;
  final LeaveStatus status;
  final String? actionBy;
  final String? remarks;
  final String? contactDuringLeave;

  const LeaveRequest({
    required this.id,
    required this.employee,
    required this.type,
    required this.appliedOn,
    required this.fromDate,
    required this.toDate,
    required this.duration,
    required this.reason,
    required this.status,
    this.actionBy,
    this.remarks,
    this.contactDuringLeave,
  });

  factory LeaveRequest.fromBackendJson(Map<String, dynamic> json, Employee dummyEmployee) {
    LeaveStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'approved':
          return LeaveStatus.approved;
        case 'rejected':
          return LeaveStatus.rejected;
        case 'cancelled':
          return LeaveStatus.cancelled;
        case 'pending':
        default:
          return LeaveStatus.pending;
      }
    }

    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 1;
      return 1;
    }

    return LeaveRequest(
      id: (json['id'] ?? '').toString(),
      employee: dummyEmployee,
      type: LeaveType.el,
      appliedOn: json['created_at'] != null ? parseDate(json['created_at']).toLocal() : DateTime.now(),
      fromDate: parseDate(json['from_date']),
      toDate: parseDate(json['to_date']),
      duration: parseInt(json['duration']),
      reason: json['reason'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      actionBy: json['approved_by']?.toString(),
      remarks: json['remarks'] as String?,
      contactDuringLeave: json['contact_during_leave'] as String?,
    );
  }

  String get dateRange =>
      '${_formatDate(fromDate)} - ${_formatDate(toDate)}';

  String get statusLabel {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get typeLabel => 'EL';

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}