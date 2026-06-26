import 'employee.dart';

class PerformanceObjective {
  final String id;
  final String title;
  final double progress;
  final Employee employee;
  final String status; // Active, Review, Completed, Planning
  final String? category; // Technical, Soft Skills, Leadership, etc.
  final DateTime startDate;
  final DateTime targetDate;
  final String? description;

  const PerformanceObjective({
    required this.id,
    required this.title,
    required this.progress,
    required this.employee,
    required this.status,
    this.category,
    required this.startDate,
    required this.targetDate,
    this.description,
  });

  String get statusLabel {
    switch (status) {
      case 'Active':
        return 'In Progress';
      case 'Review':
        return 'Under Review';
      case 'Completed':
        return 'Completed';
      case 'Planning':
        return 'Planning';
      default:
        return status;
    }
  }

  bool get isCompleted => progress >= 100;
}

class AppraisalStage {
  final String label;
  final String status; // Verified, Pending, In Progress
  final String? feedback;
  final double? rating;

  const AppraisalStage({
    required this.label,
    required this.status,
    this.feedback,
    this.rating,
  });

  bool get isCompleted => status == 'Verified' || status == 'Completed';
}

class PerformanceMetrics {
  final int recognitionPoints;
  final double rating;
  final int objectivesCompleted;
  final int totalObjectives;
  final int appraisalCycle;
  final String projectVelocity; // High, Medium, Low
  final double strategicAlignment;

  const PerformanceMetrics({
    required this.recognitionPoints,
    required this.rating,
    required this.objectivesCompleted,
    required this.totalObjectives,
    required this.appraisalCycle,
    required this.projectVelocity,
    required this.strategicAlignment,
  });

  double get completionRate =>
      totalObjectives > 0 ? objectivesCompleted / totalObjectives * 100 : 0;
}