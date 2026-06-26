import 'employee.dart';

class SalaryComponent {
  final String name;
  final double amount;
  final bool isDeduction;
  final String? description;

  const SalaryComponent({
    required this.name,
    required this.amount,
    this.isDeduction = false,
    this.description,
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> json) => SalaryComponent(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isDeduction: json['isDeduction'] as bool? ?? false,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'isDeduction': isDeduction,
        'description': description,
      };
}

class Payslip {
  final String id;
  final Employee employee;
  final String month; // e.g., "May 2026"
  final int monthIndex; // 1–12
  final DateTime generatedOn;
  final double basic;
  final double hra;
  final double conveyance;
  final double medical;
  final double specialAllowance;
  final double performanceBonus;
  final double otherAllowance;
  final double grossSalary;
  final double pfEmployee; // Employee PF
  final double esiEmployee; // Employee ESIC
  final double tds;
  final double professionalTax;
  final double otherDeductions;
  final double totalDeductions;
  final double pfEmployer; // Employer PF contribution
  final double esiEmployer; // Employer ESIC contribution
  final double netSalary;
  final int workingDays;
  final int paidDays;
  final int lopDays;
  final String? bankName;
  final String? accountNumber;
  final String? paymentStatus;
  final List<SalaryComponent> earnings;
  final List<SalaryComponent> deductions;

  const Payslip({
    required this.id,
    required this.employee,
    required this.month,
    this.monthIndex = 1,
    required this.generatedOn,
    required this.basic,
    required this.hra,
    this.conveyance = 0,
    this.medical = 0,
    this.specialAllowance = 0,
    this.performanceBonus = 0,
    this.otherAllowance = 0,
    required this.grossSalary,
    required this.pfEmployee,
    this.esiEmployee = 0,
    this.tds = 0,
    this.professionalTax = 0,
    this.otherDeductions = 0,
    required this.totalDeductions,
    this.pfEmployer = 0,
    this.esiEmployer = 0,
    required this.netSalary,
    required this.workingDays,
    required this.paidDays,
    this.lopDays = 0,
    this.bankName,
    this.accountNumber,
    this.paymentStatus = 'Paid',
    this.earnings = const [],
    this.deductions = const [],
  });

  /// Total CTC = Gross Earnings + Employer PF + Employer ESIC
  double get totalCTC => grossSalary + pfEmployer + esiEmployer;

  /// Total deductions including employer contributions (for CTC breakdown)
  double get totalCTCDeductions => totalDeductions + pfEmployer + esiEmployer;

  String get formattedNet => '₹${_formatCurrency(netSalary)}';
  String get formattedGross => '₹${_formatCurrency(grossSalary)}';
  String get formattedDeductions => '₹${_formatCurrency(totalDeductions)}';
  String get formattedCTC => '₹${_formatCurrency(totalCTC)}';
  String get formattedPfEmployer => '₹${_formatCurrency(pfEmployer)}';
  String get formattedEsiEmployer => '₹${_formatCurrency(esiEmployer)}';

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

  Payslip copyWith({
    String? id,
    Employee? employee,
    String? month,
    int? monthIndex,
    DateTime? generatedOn,
    double? basic,
    double? hra,
    double? conveyance,
    double? medical,
    double? specialAllowance,
    double? performanceBonus,
    double? otherAllowance,
    double? grossSalary,
    double? pfEmployee,
    double? esiEmployee,
    double? tds,
    double? professionalTax,
    double? otherDeductions,
    double? totalDeductions,
    double? pfEmployer,
    double? esiEmployer,
    double? netSalary,
    int? workingDays,
    int? paidDays,
    int? lopDays,
    String? bankName,
    String? accountNumber,
    String? paymentStatus,
    List<SalaryComponent>? earnings,
    List<SalaryComponent>? deductions,
  }) {
    return Payslip(
      id: id ?? this.id,
      employee: employee ?? this.employee,
      month: month ?? this.month,
      monthIndex: monthIndex ?? this.monthIndex,
      generatedOn: generatedOn ?? this.generatedOn,
      basic: basic ?? this.basic,
      hra: hra ?? this.hra,
      conveyance: conveyance ?? this.conveyance,
      medical: medical ?? this.medical,
      specialAllowance: specialAllowance ?? this.specialAllowance,
      performanceBonus: performanceBonus ?? this.performanceBonus,
      otherAllowance: otherAllowance ?? this.otherAllowance,
      grossSalary: grossSalary ?? this.grossSalary,
      pfEmployee: pfEmployee ?? this.pfEmployee,
      esiEmployee: esiEmployee ?? this.esiEmployee,
      tds: tds ?? this.tds,
      professionalTax: professionalTax ?? this.professionalTax,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      pfEmployer: pfEmployer ?? this.pfEmployer,
      esiEmployer: esiEmployer ?? this.esiEmployer,
      netSalary: netSalary ?? this.netSalary,
      workingDays: workingDays ?? this.workingDays,
      paidDays: paidDays ?? this.paidDays,
      lopDays: lopDays ?? this.lopDays,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      earnings: earnings ?? this.earnings,
      deductions: deductions ?? this.deductions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee': employee.toJson(),
        'month': month,
        'monthIndex': monthIndex,
        'generatedOn': generatedOn.toIso8601String(),
        'basic': basic,
        'hra': hra,
        'conveyance': conveyance,
        'medical': medical,
        'specialAllowance': specialAllowance,
        'performanceBonus': performanceBonus,
        'otherAllowance': otherAllowance,
        'grossSalary': grossSalary,
        'pfEmployee': pfEmployee,
        'esiEmployee': esiEmployee,
        'tds': tds,
        'professionalTax': professionalTax,
        'otherDeductions': otherDeductions,
        'totalDeductions': totalDeductions,
        'pfEmployer': pfEmployer,
        'esiEmployer': esiEmployer,
        'netSalary': netSalary,
        'workingDays': workingDays,
        'paidDays': paidDays,
        'lopDays': lopDays,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'paymentStatus': paymentStatus,
        'earnings': earnings.map((e) => e.toJson()).toList(),
        'deductions': deductions.map((d) => d.toJson()).toList(),
      };

  factory Payslip.fromJson(Map<String, dynamic> json) => Payslip(
        id: json['id'] as String,
        employee: Employee.fromJson(json['employee'] as Map<String, dynamic>),
        month: json['month'] as String,
        monthIndex: json['monthIndex'] as int? ?? 1,
        generatedOn: DateTime.parse(json['generatedOn'] as String),
        basic: (json['basic'] as num).toDouble(),
        hra: (json['hra'] as num).toDouble(),
        conveyance: (json['conveyance'] as num?)?.toDouble() ?? 0,
        medical: (json['medical'] as num?)?.toDouble() ?? 0,
        specialAllowance: (json['specialAllowance'] as num?)?.toDouble() ?? 0,
        performanceBonus: (json['performanceBonus'] as num?)?.toDouble() ?? 0,
        otherAllowance: (json['otherAllowance'] as num?)?.toDouble() ?? 0,
        grossSalary: (json['grossSalary'] as num).toDouble(),
        pfEmployee: (json['pfEmployee'] as num?)?.toDouble() ?? (json['pf'] as num?)?.toDouble() ?? 0,
        esiEmployee: (json['esiEmployee'] as num?)?.toDouble() ?? (json['esi'] as num?)?.toDouble() ?? 0,
        tds: (json['tds'] as num?)?.toDouble() ?? 0,
        professionalTax: (json['professionalTax'] as num?)?.toDouble() ?? 0,
        otherDeductions: (json['otherDeductions'] as num?)?.toDouble() ?? 0,
        totalDeductions: (json['totalDeductions'] as num).toDouble(),
        pfEmployer: (json['pfEmployer'] as num?)?.toDouble() ?? 0,
        esiEmployer: (json['esiEmployer'] as num?)?.toDouble() ?? 0,
        netSalary: (json['netSalary'] as num).toDouble(),
        workingDays: json['workingDays'] as int,
        paidDays: json['paidDays'] as int,
        lopDays: json['lopDays'] as int? ?? 0,
        bankName: json['bankName'] as String?,
        accountNumber: json['accountNumber'] as String?,
        paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
        earnings: (json['earnings'] as List<dynamic>?)
                ?.map((e) => SalaryComponent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        deductions: (json['deductions'] as List<dynamic>?)
                ?.map((d) => SalaryComponent.fromJson(d as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class SalaryHistory {
  final List<Payslip> payslips;
  final int year;

  const SalaryHistory({
    required this.payslips,
    required this.year,
  });

  double get totalEarned => payslips.fold(0, (sum, p) => sum + p.netSalary);
  double get totalDeducted =>
      payslips.fold(0, (sum, p) => sum + p.totalDeductions);
}