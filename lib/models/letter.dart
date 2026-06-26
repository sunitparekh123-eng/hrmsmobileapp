/// Employee letter model (SOW 3.7 — Letter & Document Generation)
enum LetterType { offer, appointment, warning, nonPerformance, absenteeism }

class EmployeeLetter {
  final String id;
  final String employeeId;
  final LetterType type;
  final String title;
  final String content; // Dynamic fields filled; mock contains placeholder text
  final DateTime issuedOn;
  final String? issuedBy;
  final bool emailed;

  const EmployeeLetter({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.title,
    required this.content,
    required this.issuedOn,
    this.issuedBy,
    this.emailed = false,
  });

  String get typeLabel {
    switch (type) {
      case LetterType.offer:
        return 'Offer Letter';
      case LetterType.appointment:
        return 'Appointment Letter';
      case LetterType.warning:
        return 'Warning Letter';
      case LetterType.nonPerformance:
        return 'Non-Performance Letter';
      case LetterType.absenteeism:
        return 'Absenteeism Letter';
    }
  }

  factory EmployeeLetter.fromBackendJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'appointment';
    LetterType letterType = LetterType.appointment;
    if (typeStr == 'offer') {
      letterType = LetterType.offer;
    } else if (typeStr == 'warning') {
      letterType = LetterType.warning;
    }

    return EmployeeLetter(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      type: letterType,
      title: json['title'] as String? ?? 'Letter',
      content: json['content'] as String? ?? '',
      issuedOn: json['issued_date'] != null ? DateTime.tryParse(json['issued_date'] as String) ?? DateTime.now() : DateTime.now(),
      issuedBy: json['issued_by']?.toString() ?? 'HR Manager',
      emailed: true,
    );
  }
}