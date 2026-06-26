/// Salary structure model for employee compensation breakdown
class SalaryStructure {
  final String id;
  final String employeeId;
  final double fixedGross;
  final double basicSalary; // 40% of fixedGross
  final double hra; // 40% of basic
  final double specialAllowance;
  final double otherAllowance;
  final double conveyance;
  final double medicalAllowance;
  final bool pfApplicable;
  final double pfCeiling; // 0 or 15000
  final String pfContributionMode; // none | employee_only | employer_only | shared
  final double pfEmployeeRate; // e.g., 0.12
  final double pfEmployerRate; // e.g., 0.12
  final bool esicApplicable;
  final String esicContributionMode; // none | shared
  final double esicEmployeeRate; // e.g., 0.0075
  final double esicEmployerRate; // e.g., 0.0325
  final bool ptApplicable;
  final int effectiveWorkDays; // typically 26
  final DateTime effectiveFrom;
  final DateTime? effectiveTo; // null = currently active
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalaryStructure({
    required this.id,
    required this.employeeId,
    required this.fixedGross,
    required this.basicSalary,
    required this.hra,
    this.specialAllowance = 0,
    this.otherAllowance = 0,
    this.conveyance = 0,
    this.medicalAllowance = 0,
    this.pfApplicable = true,
    this.pfCeiling = 15000,
    this.pfContributionMode = 'shared',
    this.pfEmployeeRate = 0.12,
    this.pfEmployerRate = 0.12,
    this.esicApplicable = true,
    this.esicContributionMode = 'shared',
    this.esicEmployeeRate = 0.0075,
    this.esicEmployerRate = 0.0325,
    this.ptApplicable = true,
    this.effectiveWorkDays = 26,
    required this.effectiveFrom,
    this.effectiveTo,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalaryStructure.fromJson(Map<String, dynamic> json) => SalaryStructure(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        fixedGross: (json['fixedGross'] as num).toDouble(),
        basicSalary: (json['basicSalary'] as num).toDouble(),
        hra: (json['hra'] as num).toDouble(),
        specialAllowance: (json['specialAllowance'] as num?)?.toDouble() ?? 0,
        otherAllowance: (json['otherAllowance'] as num?)?.toDouble() ?? 0,
        conveyance: (json['conveyance'] as num?)?.toDouble() ?? 0,
        medicalAllowance: (json['medicalAllowance'] as num?)?.toDouble() ?? 0,
        pfApplicable: json['pfApplicable'] as bool? ?? true,
        pfCeiling: (json['pfCeiling'] as num?)?.toDouble() ?? 15000,
        pfContributionMode: json['pfContributionMode'] as String? ?? 'shared',
        pfEmployeeRate: (json['pfEmployeeRate'] as num?)?.toDouble() ?? 0.12,
        pfEmployerRate: (json['pfEmployerRate'] as num?)?.toDouble() ?? 0.12,
        esicApplicable: json['esicApplicable'] as bool? ?? true,
        esicContributionMode: json['esicContributionMode'] as String? ?? 'shared',
        esicEmployeeRate: (json['esicEmployeeRate'] as num?)?.toDouble() ?? 0.0075,
        esicEmployerRate: (json['esicEmployerRate'] as num?)?.toDouble() ?? 0.0325,
        ptApplicable: json['ptApplicable'] as bool? ?? true,
        effectiveWorkDays: json['effectiveWorkDays'] as int? ?? 26,
        effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
        effectiveTo: json['effectiveTo'] != null
            ? DateTime.parse(json['effectiveTo'] as String)
            : null,
        createdBy: json['createdBy'] as String?,
        updatedBy: json['updatedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'fixedGross': fixedGross,
        'basicSalary': basicSalary,
        'hra': hra,
        'specialAllowance': specialAllowance,
        'otherAllowance': otherAllowance,
        'conveyance': conveyance,
        'medicalAllowance': medicalAllowance,
        'pfApplicable': pfApplicable,
        'pfCeiling': pfCeiling,
        'pfContributionMode': pfContributionMode,
        'pfEmployeeRate': pfEmployeeRate,
        'pfEmployerRate': pfEmployerRate,
        'esicApplicable': esicApplicable,
        'esicContributionMode': esicContributionMode,
        'esicEmployeeRate': esicEmployeeRate,
        'esicEmployerRate': esicEmployerRate,
        'ptApplicable': ptApplicable,
        'effectiveWorkDays': effectiveWorkDays,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'effectiveTo': effectiveTo?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Salary revision audit trail
class SalaryRevision {
  final String id;
  final String employeeId;
  final double previousGross;
  final double newGross;
  final double previousBasic;
  final double newBasic;
  final String revisionType; // 'initial', 'increment', 'decrement', 'promotion'
  final DateTime effectiveDate;
  final String? remarks;
  final String? approvedBy;
  final DateTime createdAt;

  const SalaryRevision({
    required this.id,
    required this.employeeId,
    required this.previousGross,
    required this.newGross,
    required this.previousBasic,
    required this.newBasic,
    required this.revisionType,
    required this.effectiveDate,
    this.remarks,
    this.approvedBy,
    required this.createdAt,
  });

  factory SalaryRevision.fromJson(Map<String, dynamic> json) => SalaryRevision(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        previousGross: (json['previousGross'] as num).toDouble(),
        newGross: (json['newGross'] as num).toDouble(),
        previousBasic: (json['previousBasic'] as num).toDouble(),
        newBasic: (json['newBasic'] as num).toDouble(),
        revisionType: json['revisionType'] as String,
        effectiveDate: DateTime.parse(json['effectiveDate'] as String),
        remarks: json['remarks'] as String?,
        approvedBy: json['approvedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'previousGross': previousGross,
        'newGross': newGross,
        'previousBasic': previousBasic,
        'newBasic': newBasic,
        'revisionType': revisionType,
        'effectiveDate': effectiveDate.toIso8601String(),
        'remarks': remarks,
        'approvedBy': approvedBy,
        'createdAt': createdAt.toIso8601String(),
      };
}