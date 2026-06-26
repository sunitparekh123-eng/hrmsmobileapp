import '../../models/employee.dart';

/// Mock current logged-in employee
class MockAuth {
  static Employee get currentEmployee => Employee(
        id: 'EMP001',
        name: 'Arjun Singh',
        email: 'arjun.singh@company.com',
        phone: '+91-9876543210',
        avatarUrl: '',
        designation: 'Sr. Software Engineer',
        department: 'Engineering',
        branch: 'Indore Hub',
        employeeId: 'EMP-2024-001',
        joiningDate: DateTime(2024, 3, 15),
        bloodGroup: 'B+',
        emergencyContact: '+91-9876543211',
        dateOfBirth: DateTime(1995, 8, 12),
        aadhaarNumber: 'XXXX-XXXX-1234',
        panNumber: 'ABCDE1234F',
        bankName: 'HDFC Bank',
        accountNumber: 'XXXXXX7890',
        ifscCode: 'HDFC0001234',
        pfNumber: 'MH/0001234/000/1234567',
        uan: '100123456789',
        licDetails: 'LIC Jeevan Anand — Policy No. 123456789',
        // -- New onboarding fields --
        emergencyContactRelation: 'Father',
        location: 'Indore Hub',
        companyName: 'Apaar Logistics & Cold Supply Chain Pvt Ltd',
        gender: 'Male',
        address: '123, Scheme No. 54, Vijay Nagar, Indore - 452010, Madhya Pradesh',
        // -- Salary fields (denormalized from SalaryStructure) --
        fixedGross: 31800,
        basicSalary: 12720,   // 40% of 31800
        pfApplicable: true,
        pfCeiling: 15000,
        esicApplicable: true,
        pfContributionMode: 'shared',
        esicContributionMode: 'shared',
      );

  static const Map<String, String> credentials = {
    'arjun.singh@company.com': 'password123',
    'rahul.sharma@company.com': 'password123',
    'anita.kapoor@company.com': 'password123',
  };
}