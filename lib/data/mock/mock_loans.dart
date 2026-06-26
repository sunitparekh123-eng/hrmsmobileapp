import '../../models/loans.dart';
import '../../models/employee.dart';
import 'mock_auth.dart';

class MockLoanData {
  static Employee get employee => MockAuth.currentEmployee;

  static List<Loan> getLoans() => [
        Loan(
          id: 'LN001',
          employee: employee,
          type: LoanType.personal,
          principal: 250000,
          interestRate: 8.5,
          tenureMonths: 24,
          emi: 11364,
          totalPaid: 136368,
          remainingAmount: 113632,
          status: LoanStatus.active,
          appliedOn: DateTime(2025, 1, 10),
          disbursedOn: DateTime(2025, 1, 15),
          nextEmiDate: DateTime(2026, 6, 1),
          branch: 'Indore Hub',
        ),
        Loan(
          id: 'LN002',
          employee: employee,
          type: LoanType.medical,
          principal: 50000,
          interestRate: 0,
          tenureMonths: 10,
          emi: 5000,
          totalPaid: 5000,
          remainingAmount: 45000,
          status: LoanStatus.pending,
          appliedOn: DateTime(2026, 5, 20),
          branch: 'Indore Hub',
        ),
        Loan(
          id: 'LN003',
          employee: employee,
          type: LoanType.vehicle,
          principal: 400000,
          interestRate: 9.0,
          tenureMonths: 36,
          emi: 13891,
          totalPaid: 555640,
          remainingAmount: 0,
          status: LoanStatus.closed,
          appliedOn: DateTime(2023, 3, 12),
          disbursedOn: DateTime(2023, 3, 15),
          branch: 'Indore Hub',
        ),
      ];

  static List<Loan> getActiveLoans() =>
      getLoans().where((l) => l.status == LoanStatus.active).toList();

  static double get totalActiveBorrowed =>
      getActiveLoans().fold(0, (sum, l) => sum + l.principal);

  static double get totalRemaining =>
      getActiveLoans().fold(0, (sum, l) => sum + l.remainingAmount);

  static List<Map<String, dynamic>> getLoanPolicies() => [
        {
          'title': 'Personal Loan',
          'maxAmount': '₹5,00,000',
          'maxTenure': '36 months',
          'interestRate': '8.5% - 12%',
          'eligibility': '1 year completed',
          'description':
              'General purpose loan for personal needs like home renovation, marriage, travel, etc.',
        },
        {
          'title': 'Vehicle Loan',
          'maxAmount': '₹8,00,000',
          'maxTenure': '60 months',
          'interestRate': '9% - 10.5%',
          'eligibility': '2 years completed',
          'description':
              'Loan for purchasing two-wheeler or four-wheeler vehicles.',
        },
        {
          'title': 'Medical Emergency',
          'maxAmount': '₹2,00,000',
          'maxTenure': '12 months',
          'interestRate': '0% (Interest Free)',
          'eligibility': 'Confirmed employees only',
          'description':
              'Emergency medical loan for employee or immediate family members.',
        },
        {
          'title': 'Home Advance',
          'maxAmount': '₹2,00,000',
          'maxTenure': '36 months',
          'interestRate': '5%',
          'eligibility': '3 years completed',
          'description':
              'Advance for home purchase, construction, or major renovation.',
        },
        {
          'title': 'Education Loan',
          'maxAmount': '₹1,00,000',
          'maxTenure': '24 months',
          'interestRate': '5%',
          'eligibility': '1 year completed',
          'description':
              'Loan for higher education of employee or their children.',
        },
      ];
}