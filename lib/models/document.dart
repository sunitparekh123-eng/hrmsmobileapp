/// Employee document model (SOW 3.1 — Document upload & storage)
enum DocumentType { aadhaar, pan, bankPassbook, pfStatement, uanCard, licPolicy, offerLetter, appointmentLetter, other }

enum DocumentStatus { verified, pending, rejected }

class EmployeeDocument {
  final String id;
  final String employeeId;
  final DocumentType type;
  final String title;
  final String? fileName;
  final String? fileUrl; // In prod: cloud URL; mock: placeholder
  final DocumentStatus status;
  final DateTime uploadedOn;
  final String? verifiedBy;
  final String? remarks;

  const EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.title,
    this.fileName,
    this.fileUrl,
    this.status = DocumentStatus.pending,
    required this.uploadedOn,
    this.verifiedBy,
    this.remarks,
  });

  String get typeLabel {
    switch (type) {
      case DocumentType.aadhaar:
        return 'Aadhaar Card';
      case DocumentType.pan:
        return 'PAN Card';
      case DocumentType.bankPassbook:
        return 'Bank Passbook';
      case DocumentType.pfStatement:
        return 'PF Statement';
      case DocumentType.uanCard:
        return 'UAN Card';
      case DocumentType.licPolicy:
        return 'LIC Policy';
      case DocumentType.offerLetter:
        return 'Offer Letter';
      case DocumentType.appointmentLetter:
        return 'Appointment Letter';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }

  factory EmployeeDocument.fromBackendJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final typeStr = json['type'] as String? ?? '';
    final statusStr = json['status'] as String? ?? '';

    DocumentType docType = DocumentType.other;
    if (name.toLowerCase().contains('aadhaar')) {
      docType = DocumentType.aadhaar;
    } else if (name.toLowerCase().contains('pan')) {
      docType = DocumentType.pan;
    } else if (name.toLowerCase().contains('passbook') || name.toLowerCase().contains('cheque')) {
      docType = DocumentType.bankPassbook;
    } else if (name.toLowerCase().contains('pf')) {
      docType = DocumentType.pfStatement;
    } else if (name.toLowerCase().contains('uan')) {
      docType = DocumentType.uanCard;
    } else if (name.toLowerCase().contains('lic')) {
      docType = DocumentType.licPolicy;
    } else if (name.toLowerCase().contains('offer') || typeStr == 'offer_letter') {
      docType = DocumentType.offerLetter;
    } else if (name.toLowerCase().contains('appointment') || typeStr == 'contract') {
      docType = DocumentType.appointmentLetter;
    }

    DocumentStatus docStatus = DocumentStatus.pending;
    if (statusStr == 'verified') {
      docStatus = DocumentStatus.verified;
    } else if (statusStr == 'rejected') {
      docStatus = DocumentStatus.rejected;
    }

    return EmployeeDocument(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      type: docType,
      title: name,
      fileName: json['file_path'] != null ? (json['file_path'] as String).split('/').last : '',
      fileUrl: json['file_path'] as String?,
      status: docStatus,
      uploadedOn: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now() : DateTime.now(),
      verifiedBy: json['verified_by']?.toString(),
      remarks: json['remarks'] as String?,
    );
  }
}