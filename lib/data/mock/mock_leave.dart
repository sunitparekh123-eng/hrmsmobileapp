import '../../models/leave.dart';
import '../../models/employee.dart';
import 'mock_auth.dart';

class MockLeaveData {
  static Employee get employee => MockAuth.currentEmployee;

  static List<LeaveBalance> getBalances() => [
        const LeaveBalance(
          available: 2,
          used: 4,
          adminGranted: 1,
          lapsed: 5,
          lastAccrualMonth: '2026-06',
          consecutiveNoUsageMonths: 0,
        ),
      ];

  static List<LeaveRequest> getRequests() => [
        LeaveRequest(
          id: 'LR001',
          employee: employee,
          type: LeaveType.el,
          appliedOn: DateTime(2026, 5, 14),
          fromDate: DateTime(2026, 5, 10),
          toDate: DateTime(2026, 5, 10),
          duration: 1,
          reason: 'Family Function - Sister\'s wedding',
          status: LeaveStatus.approved,
          actionBy: 'Admin HQ',
          remarks: 'Approved for family event.',
          contactDuringLeave: '+91-9876543210',
        ),
        LeaveRequest(
          id: 'LR002',
          employee: employee,
          type: LeaveType.el,
          appliedOn: DateTime(2026, 4, 20),
          fromDate: DateTime(2026, 4, 22),
          toDate: DateTime(2026, 4, 22),
          duration: 1,
          reason: 'Personal work - bank documentation',
          status: LeaveStatus.approved,
          actionBy: 'Admin HQ',
          remarks: 'Verified.',
        ),
        LeaveRequest(
          id: 'LR003',
          employee: employee,
          type: LeaveType.el,
          appliedOn: DateTime(2026, 3, 10),
          fromDate: DateTime(2026, 3, 15),
          toDate: DateTime(2026, 3, 15),
          duration: 1,
          reason: 'Family vacation',
          status: LeaveStatus.rejected,
          actionBy: 'Admin HQ',
          remarks: 'Critical sprint delivery - reschedule after April.',
        ),
        LeaveRequest(
          id: 'LR004',
          employee: employee,
          type: LeaveType.el,
          appliedOn: DateTime(2026, 2, 1),
          fromDate: DateTime(2026, 2, 5),
          toDate: DateTime(2026, 2, 5),
          duration: 1,
          reason: 'Personal errand',
          status: LeaveStatus.approved,
          actionBy: 'Admin HQ',
          remarks: 'Approved.',
        ),
      ];

  static List<LeaveRequest> getPendingRequests() =>
      getRequests().where((r) => r.status == LeaveStatus.pending).toList();

  static List<LeaveRequest> getApprovedRequests() =>
      getRequests().where((r) => r.status == LeaveStatus.approved).toList();

  static int get totalLeavesTaken => getRequests()
      .where((r) => r.status == LeaveStatus.approved)
      .fold(0, (sum, r) => sum + r.duration);
}