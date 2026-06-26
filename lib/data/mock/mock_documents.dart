import '../../models/document.dart';
import '../../models/letter.dart';

/// Mock documents for the currently logged-in employee
class MockDocuments {
  static List<EmployeeDocument> get all => [
        EmployeeDocument(
          id: 'DOC001',
          employeeId: 'EMP001',
          type: DocumentType.aadhaar,
          title: 'Aadhaar Card',
          fileName: 'aadhaar_arjun.pdf',
          status: DocumentStatus.verified,
          uploadedOn: DateTime(2025, 1, 10),
          verifiedBy: 'HR Admin',
        ),
        EmployeeDocument(
          id: 'DOC002',
          employeeId: 'EMP001',
          type: DocumentType.pan,
          title: 'PAN Card',
          fileName: 'pan_arjun.pdf',
          status: DocumentStatus.verified,
          uploadedOn: DateTime(2025, 1, 10),
          verifiedBy: 'HR Admin',
        ),
        EmployeeDocument(
          id: 'DOC003',
          employeeId: 'EMP001',
          type: DocumentType.bankPassbook,
          title: 'Bank Passbook / Cancelled Cheque',
          fileName: 'bank_hdfc_arjun.pdf',
          status: DocumentStatus.verified,
          uploadedOn: DateTime(2025, 3, 5),
        ),
        EmployeeDocument(
          id: 'DOC004',
          employeeId: 'EMP001',
          type: DocumentType.pfStatement,
          title: 'PF Statement 2025-26',
          fileName: 'pf_stmt.pdf',
          status: DocumentStatus.pending,
          uploadedOn: DateTime(2026, 4, 1),
        ),
        EmployeeDocument(
          id: 'DOC005',
          employeeId: 'EMP001',
          type: DocumentType.licPolicy,
          title: 'LIC Jeevan Anand Policy',
          fileName: 'lic_policy.pdf',
          status: DocumentStatus.pending,
          uploadedOn: DateTime(2025, 8, 20),
        ),
      ];
}

/// Mock letters for the currently logged-in employee
class MockLetters {
  static List<EmployeeLetter> get all => [
        EmployeeLetter(
          id: 'LET001',
          employeeId: 'EMP001',
          type: LetterType.offer,
          title: 'Offer of Employment — Sr. Software Engineer',
          content:
              'Dear Arjun Singh,\n\nWe are pleased to offer you the position of Sr. Software Engineer '
              'in the Engineering department at NexGen Logistics Pvt. Ltd., Indore Hub. '
              'Your date of joining is 15 March 2024.\n\n'
              'CTC: ₹12,00,000 per annum\n'
              'Probation Period: 6 months\n\n'
              'We look forward to having you on board.\n\nSincerely,\nHR Department',
          issuedOn: DateTime(2024, 2, 20),
          issuedBy: 'HR Manager',
          emailed: true,
        ),
        EmployeeLetter(
          id: 'LET002',
          employeeId: 'EMP001',
          type: LetterType.appointment,
          title: 'Appointment Letter — Confirmation of Employment',
          content:
              'Dear Arjun Singh,\n\nThis letter confirms your appointment as Sr. Software Engineer '
              'at NexGen Logistics Pvt. Ltd. with effect from 15 March 2024.\n\n'
              'Your employment terms are as per the offer letter dated 20 February 2024.\n\n'
              'Sincerely,\nHR Department',
          issuedOn: DateTime(2024, 3, 15),
          issuedBy: 'HR Manager',
          emailed: true,
        ),
        EmployeeLetter(
          id: 'LET003',
          employeeId: 'EMP001',
          type: LetterType.warning,
          title: 'Warning Letter — Unauthorised Absence',
          content:
              'Dear Arjun,\n\nThis is to bring to your notice that you were absent without prior '
              'intimation on 10 April 2026.\n\n'
              'This is being treated as an unauthorised absence. Please ensure you apply for leave '
              'in advance going forward.\n\n'
              'Regards,\nHR Department',
          issuedOn: DateTime(2026, 4, 12),
          issuedBy: 'Team Lead',
          emailed: true,
        ),
      ];
}