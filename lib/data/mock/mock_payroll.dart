import '../../models/payroll.dart';
import '../../models/employee.dart';
import 'mock_auth.dart';

class MockPayrollData {
  static Employee get employee => MockAuth.currentEmployee;

  static List<Payslip> getPayslips() {
    return [
      Payslip(
        id: 'PS-2026-05',
        employee: employee,
        month: 'May 2026',
        monthIndex: 5,
        generatedOn: DateTime(2026, 5, 31),
        basic: 5088,
        hra: 2035,
        conveyance: 0,
        medical: 0,
        specialAllowance: 0,
        otherAllowance: 5597,
        grossSalary: 12720,
        pfEmployee: 611,
        esiEmployee: 96,
        tds: 0,
        professionalTax: 0,
        otherDeductions: 0,
        totalDeductions: 707,
        pfEmployer: 611,
        esiEmployer: 414,
        netSalary: 12013,
        workingDays: 26,
        paidDays: 26,
        lopDays: 0,
        bankName: 'HDFC Bank',
        accountNumber: '****4301',
        paymentStatus: 'Paid',
        earnings: const [
          SalaryComponent(name: 'Basic', amount: 5088),
          SalaryComponent(name: 'HRA', amount: 2035),
          SalaryComponent(name: 'Other Allowance', amount: 5597),
        ],
        deductions: const [
          SalaryComponent(name: 'PF (Employee)', amount: 611, isDeduction: true),
          SalaryComponent(name: 'ESIC (Employee)', amount: 96, isDeduction: true),
          SalaryComponent(name: 'Professional Tax', amount: 0, isDeduction: true),
          SalaryComponent(name: 'PF (Employer)', amount: 611, isDeduction: true,
              description: 'Employer contribution to CTC'),
          SalaryComponent(name: 'ESIC (Employer)', amount: 414, isDeduction: true,
              description: 'Employer contribution to CTC'),
        ],
      ),
      Payslip(
        id: 'PS-2026-04',
        employee: employee,
        month: 'Apr 2026',
        monthIndex: 4,
        generatedOn: DateTime(2026, 4, 30),
        basic: 5088,
        hra: 2035,
        conveyance: 0,
        medical: 0,
        specialAllowance: 0,
        otherAllowance: 5597,
        grossSalary: 12720,
        pfEmployee: 611,
        esiEmployee: 96,
        tds: 0,
        professionalTax: 0,
        otherDeductions: 0,
        totalDeductions: 707,
        pfEmployer: 611,
        esiEmployer: 414,
        netSalary: 12013,
        workingDays: 25,
        paidDays: 24,
        lopDays: 1,
        bankName: 'HDFC Bank',
        accountNumber: '****4301',
        paymentStatus: 'Paid',
        earnings: const [
          SalaryComponent(name: 'Basic', amount: 5088),
          SalaryComponent(name: 'HRA', amount: 2035),
          SalaryComponent(name: 'Other Allowance', amount: 5597),
        ],
        deductions: const [
          SalaryComponent(name: 'PF (Employee)', amount: 611, isDeduction: true),
          SalaryComponent(name: 'ESIC (Employee)', amount: 96, isDeduction: true),
          SalaryComponent(name: 'Professional Tax', amount: 0, isDeduction: true),
          SalaryComponent(name: 'PF (Employer)', amount: 611, isDeduction: true,
              description: 'Employer contribution to CTC'),
          SalaryComponent(name: 'ESIC (Employer)', amount: 414, isDeduction: true,
              description: 'Employer contribution to CTC'),
        ],
      ),
      Payslip(
        id: 'PS-2026-03',
        employee: employee,
        month: 'Mar 2026',
        monthIndex: 3,
        generatedOn: DateTime(2026, 3, 31),
        basic: 5088,
        hra: 2035,
        conveyance: 0,
        medical: 0,
        specialAllowance: 0,
        otherAllowance: 5597,
        grossSalary: 12720,
        pfEmployee: 611,
        esiEmployee: 96,
        tds: 0,
        professionalTax: 0,
        otherDeductions: 0,
        totalDeductions: 707,
        pfEmployer: 611,
        esiEmployer: 414,
        netSalary: 12013,
        workingDays: 27,
        paidDays: 27,
        lopDays: 0,
        bankName: 'HDFC Bank',
        accountNumber: '****4301',
        paymentStatus: 'Paid',
        earnings: const [
          SalaryComponent(name: 'Basic', amount: 5088),
          SalaryComponent(name: 'HRA', amount: 2035),
          SalaryComponent(name: 'Other Allowance', amount: 5597),
        ],
        deductions: const [
          SalaryComponent(name: 'PF (Employee)', amount: 611, isDeduction: true),
          SalaryComponent(name: 'ESIC (Employee)', amount: 96, isDeduction: true),
          SalaryComponent(name: 'Professional Tax', amount: 0, isDeduction: true),
          SalaryComponent(name: 'PF (Employer)', amount: 611, isDeduction: true,
              description: 'Employer contribution to CTC'),
          SalaryComponent(name: 'ESIC (Employer)', amount: 414, isDeduction: true,
              description: 'Employer contribution to CTC'),
        ],
      ),
    ];
  }

  static Payslip getLatestPayslip() => getPayslips().first;

  static List<Map<String, dynamic>> getMonthlySummary({int months = 6}) {
    final payslips = getPayslips();
    final now = DateTime.now();
    final summary = <Map<String, dynamic>>[];

    for (var i = months - 1; i >= 0; i--) {
      final targetMonth = now.month - i;
      final targetYear = targetMonth <= 0 ? now.year - 1 : now.year;
      final adjustedMonth = targetMonth <= 0 ? targetMonth + 12 : targetMonth;

      final match = payslips.where((p) {
        final parts = p.month.split(' ');
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames.indexOf(parts[0]) + 1 == adjustedMonth &&
            int.tryParse(parts[1]) == targetYear;
      }).firstOrNull;

      summary.add({
        'month': '${_monthAbbr(adjustedMonth)} $targetYear',
        'netSalary': match?.netSalary ?? 0,
        'workingDays': match?.workingDays ?? 0,
        'paidDays': match?.paidDays ?? 0,
      });
    }

    return summary;
  }

  static String _monthAbbr(int month) {
    const abbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return abbr[month - 1];
  }
}