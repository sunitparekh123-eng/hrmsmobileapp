/// Employee model shared across all modules
class Employee {
  final String id;
  final String role; // 'employee', 'hr', 'admin' — used for mobile login gate
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String designation;
  final String department;
  final String branch;
  final String employeeId;
  final DateTime joiningDate;
  final String bloodGroup;
  final String emergencyContact;

  // -- SOW 3.1: Employee onboarding / documentation fields --
  final DateTime? dateOfBirth; // DOB
  final String aadhaarNumber; // Masked: "XXXX-XXXX-1234"
  final String panNumber; // Masked: "ABCDE1234F"
  final String bankName;
  final String accountNumber; // Masked
  final String ifscCode;
  final String pfNumber;
  final String uan;
  final String licDetails;

  // -- NEW: Extended onboarding fields (Phase 5) --
  final String emergencyContactRelation; // e.g., "Father", "Spouse"
  final String location; // e.g., "Indore Hub"
  final String companyName; // e.g., "Apaar Logistics & Cold Supply Chain Pvt Ltd"
  final String gender; // "Male", "Female", "Other"
  final String address; // Full address

  // -- Salary fields (denormalized from SalaryStructure) --
  final double fixedGross; // Fixed gross salary
  final double basicSalary; // 40% of fixedGross
  final bool pfApplicable;
  final double pfCeiling; // 0 if not applicable or 15000
  final bool esicApplicable;
  final String pfContributionMode; // 'none', 'employee_only', 'employer_only', 'shared'
  final String esicContributionMode; // 'none', 'shared'

  const Employee({
    required this.id,
    this.role = 'employee',
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    required this.designation,
    required this.department,
    required this.branch,
    required this.employeeId,
    required this.joiningDate,
    this.bloodGroup = '',
    this.emergencyContact = '',
    this.dateOfBirth,
    this.aadhaarNumber = '',
    this.panNumber = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.pfNumber = '',
    this.uan = '',
    this.licDetails = '',
    this.emergencyContactRelation = '',
    this.location = '',
    this.companyName = 'Apaar Logistics & Cold Supply Chain Pvt Ltd',
    this.gender = '',
    this.address = '',
    this.fixedGross = 0,
    this.basicSalary = 0,
    this.pfApplicable = true,
    this.pfCeiling = 15000,
    this.esicApplicable = true,
    this.pfContributionMode = 'shared',
    this.esicContributionMode = 'shared',
  });

  String get initials {
    final parts = name.split(' ').where((s) => s.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Employee copyWith({
    String? id,
    String? role,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? designation,
    String? department,
    String? branch,
    String? employeeId,
    DateTime? joiningDate,
    String? bloodGroup,
    String? emergencyContact,
    DateTime? dateOfBirth,
    String? aadhaarNumber,
    String? panNumber,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? pfNumber,
    String? uan,
    String? licDetails,
    String? emergencyContactRelation,
    String? location,
    String? companyName,
    String? gender,
    String? address,
    double? fixedGross,
    double? basicSalary,
    bool? pfApplicable,
    double? pfCeiling,
    bool? esicApplicable,
    String? pfContributionMode,
    String? esicContributionMode,
  }) {
    return Employee(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      branch: branch ?? this.branch,
      employeeId: employeeId ?? this.employeeId,
      joiningDate: joiningDate ?? this.joiningDate,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      pfNumber: pfNumber ?? this.pfNumber,
      uan: uan ?? this.uan,
      licDetails: licDetails ?? this.licDetails,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      location: location ?? this.location,
      companyName: companyName ?? this.companyName,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      fixedGross: fixedGross ?? this.fixedGross,
      basicSalary: basicSalary ?? this.basicSalary,
      pfApplicable: pfApplicable ?? this.pfApplicable,
      pfCeiling: pfCeiling ?? this.pfCeiling,
      esicApplicable: esicApplicable ?? this.esicApplicable,
      pfContributionMode: pfContributionMode ?? this.pfContributionMode,
      esicContributionMode: esicContributionMode ?? this.esicContributionMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'designation': designation,
        'department': department,
        'branch': branch,
        'employeeId': employeeId,
        'joiningDate': joiningDate.toIso8601String(),
        'bloodGroup': bloodGroup,
        'emergencyContact': emergencyContact,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'aadhaarNumber': aadhaarNumber,
        'panNumber': panNumber,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'pfNumber': pfNumber,
        'uan': uan,
        'licDetails': licDetails,
        'emergencyContactRelation': emergencyContactRelation,
        'location': location,
        'companyName': companyName,
        'gender': gender,
        'address': address,
        'fixedGross': fixedGross,
        'basicSalary': basicSalary,
        'pfApplicable': pfApplicable,
        'pfCeiling': pfCeiling,
        'esicApplicable': esicApplicable,
        'pfContributionMode': pfContributionMode,
        'esicContributionMode': esicContributionMode,
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'employee',
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        designation: json['designation'] as String,
        department: json['department'] as String,
        branch: json['branch'] as String? ?? '',
        employeeId: json['employeeId'] as String,
        joiningDate: DateTime.parse(json['joiningDate'] as String),
        bloodGroup: json['bloodGroup'] as String? ?? '',
        emergencyContact: json['emergencyContact'] as String? ?? '',
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
        aadhaarNumber: json['aadhaarNumber'] as String? ?? '',
        panNumber: json['panNumber'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        ifscCode: json['ifscCode'] as String? ?? '',
        pfNumber: json['pfNumber'] as String? ?? '',
        uan: json['uan'] as String? ?? '',
        licDetails: json['licDetails'] as String? ?? '',
        emergencyContactRelation: json['emergencyContactRelation'] as String? ?? '',
        location: json['location'] as String? ?? '',
        companyName: json['companyName'] as String? ?? 'Apaar Logistics & Cold Supply Chain Pvt Ltd',
        gender: json['gender'] as String? ?? '',
        address: json['address'] as String? ?? '',
        fixedGross: (json['fixedGross'] as num?)?.toDouble() ?? 0,
        basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
        pfApplicable: json['pfApplicable'] as bool? ?? true,
        pfCeiling: (json['pfCeiling'] as num?)?.toDouble() ?? 15000,
        esicApplicable: json['esicApplicable'] as bool? ?? true,
        pfContributionMode: json['pfContributionMode'] as String? ?? 'shared',
        esicContributionMode: json['esicContributionMode'] as String? ?? 'shared',
      );

  /// Parse employee from the real backend's snake_case response
  /// (the object returned by POST /api/v1/auth/login inside `data.employee`).
  factory Employee.fromBackendJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      role: json['role'] as String? ?? 'employee',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['profile_image'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      branch: json['office_id']?.toString() ?? '',
      employeeId: json['emp_code'] as String? ?? '',
      joiningDate: json['date_of_joining'] != null
          ? DateTime.tryParse(json['date_of_joining'] as String) ?? DateTime.now()
          : DateTime.now(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      aadhaarNumber: json['aadhaar_number'] as String? ?? '',
      panNumber: json['pan_number'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      accountNumber: json['bank_account_number'] as String? ?? '',
      ifscCode: json['ifsc_code'] as String? ?? '',
      pfNumber: json['pf_number'] as String? ?? '',
      uan: json['uan'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? '',
      licDetails: json['lic_details'] as String? ?? '',
      emergencyContact: json['emergency_contact_name'] as String? ?? '',
      emergencyContactRelation: json['emergency_contact_relation'] as String? ?? '',
      location: json['location'] as String? ?? '',
      companyName: json['company_name'] as String? ?? 'Apaar Logistics & Cold Supply Chain Pvt Ltd',
      gender: json['gender'] as String? ?? '',
      address: json['address'] as String? ?? '',
      fixedGross: _parseDouble(json['fixed_gross']) ?? 0,
      basicSalary: _parseDouble(json['basic_salary']) ?? 0,
      pfApplicable: _parseBool(json['pf_applicable']) ?? true,
      pfCeiling: _parseDouble(json['pf_ceiling']) ?? 15000,
      esicApplicable: _parseBool(json['esic_applicable']) ?? true,
      pfContributionMode: json['pf_contribution_mode'] as String? ?? 'shared',
      esicContributionMode: json['esic_contribution_mode'] as String? ?? 'shared',
    );
  }

  /// Safely parse a numeric value that may arrive as a num (int/double)
  /// or as a String (MySQL DECIMAL columns serialize as JSON strings).
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  /// Safely parse a boolean value that may arrive as a bool,
  /// an int (0/1 from MySQL TINYINT), or a String ("true"/"false"/"0"/"1").
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
      return null;
    }
    return null;
  }
}