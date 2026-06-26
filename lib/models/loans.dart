import 'employee.dart';

enum LoanType { personal, vehicle, home, medical, education }

enum LoanStatus { active, pending, closed, rejected }

class Loan {
  final String id;
  final Employee employee;
  final LoanType type;
  final double principal;
  final double interestRate;
  final int tenureMonths;
  final double emi;
  final double totalPaid;
  final double remainingAmount;
  final LoanStatus status;
  final DateTime appliedOn;
  final DateTime? disbursedOn;
  final DateTime? nextEmiDate;
  final String? branch;

  const Loan({
    required this.id,
    required this.employee,
    required this.type,
    required this.principal,
    required this.interestRate,
    required this.tenureMonths,
    required this.emi,
    required this.totalPaid,
    required this.remainingAmount,
    required this.status,
    required this.appliedOn,
    this.disbursedOn,
    this.nextEmiDate,
    this.branch,
  });

  String get typeLabel {
    switch (type) {
      case LoanType.personal:
        return 'Personal Loan';
      case LoanType.vehicle:
        return 'Vehicle Loan';
      case LoanType.home:
        return 'Home Advance';
      case LoanType.medical:
        return 'Medical Emergency';
      case LoanType.education:
        return 'Education Loan';
    }
  }

  String get statusLabel {
    switch (status) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.pending:
        return 'Pending';
      case LoanStatus.closed:
        return 'Closed';
      case LoanStatus.rejected:
        return 'Rejected';
    }
  }

  String get formattedPrincipal => '₹${_formatCurrency(principal)}';
  String get formattedEmi => '₹${_formatCurrency(emi)}';
  String get formattedTotalPaid => '₹${_formatCurrency(totalPaid)}';
  String get formattedRemaining => '₹${_formatCurrency(remainingAmount)}';

  double get paidPercentage =>
      principal > 0 ? (totalPaid / principal) * 100 : 0;

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(0).split('.');
    final chars = parts[0].split('').reversed.toList();
    final formatted = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 2 == 0 && i != chars.length - 1) {
        formatted.add(',');
      }
      formatted.add(chars[i]);
    }
    return formatted.reversed.join();
  }
}