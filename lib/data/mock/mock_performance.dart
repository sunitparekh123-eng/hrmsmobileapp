import '../../models/performance.dart';
import '../../models/employee.dart';
import 'mock_auth.dart';

class MockPerformanceData {
  static Employee get employee => MockAuth.currentEmployee;

  static PerformanceMetrics getMetrics() => PerformanceMetrics(
        recognitionPoints: 1420,
        rating: 4.2,
        objectivesCompleted: 3,
        totalObjectives: 5,
        appraisalCycle: 1,
        projectVelocity: 'High',
        strategicAlignment: 88.0,
      );

  static List<PerformanceObjective> getObjectives() => [
        PerformanceObjective(
          id: 'OBJ001',
          title: 'Lead HRMS UI Deployment',
          progress: 85,
          employee: employee,
          status: 'Active',
          category: 'Technical',
          startDate: DateTime(2026, 1, 15),
          targetDate: DateTime(2026, 6, 30),
          description: 'Lead the front-end deployment of the new HRMS across all branches with React/Next.js and Flutter mobile app integration.',
        ),
        PerformanceObjective(
          id: 'OBJ002',
          title: 'Statutory Compliance Audit',
          progress: 42,
          employee: employee,
          status: 'Review',
          category: 'Compliance',
          startDate: DateTime(2026, 2, 1),
          targetDate: DateTime(2026, 7, 15),
          description: 'Complete statutory compliance audit for all payroll, tax, and labor law regulations.',
        ),
        PerformanceObjective(
          id: 'OBJ003',
          title: 'Personnel Ingest V 2.0',
          progress: 100,
          employee: employee,
          status: 'Completed',
          category: 'Technical',
          startDate: DateTime(2025, 11, 1),
          targetDate: DateTime(2026, 3, 31),
          description: 'Upgrade the employee data ingestion pipeline with batch processing and real-time sync.',
        ),
        PerformanceObjective(
          id: 'OBJ004',
          title: 'Internal Training Program',
          progress: 20,
          employee: employee,
          status: 'Planning',
          category: 'Leadership',
          startDate: DateTime(2026, 4, 1),
          targetDate: DateTime(2026, 8, 30),
          description: 'Design and conduct internal training on modern front-end development practices.',
        ),
        PerformanceObjective(
          id: 'OBJ005',
          title: 'Mobile App Performance Optimization',
          progress: 60,
          employee: employee,
          status: 'Active',
          category: 'Technical',
          startDate: DateTime(2026, 3, 1),
          targetDate: DateTime(2026, 5, 30),
          description: 'Improve Flutter mobile app launch time and reduce memory footprint by 30%.',
        ),
      ];

  static List<AppraisalStage> getAppraisalStages() => [
        const AppraisalStage(
          label: 'Self Audit',
          status: 'Verified',
          feedback: 'Strong performance across key metrics',
          rating: 4.5,
        ),
        const AppraisalStage(
          label: 'Peer Review',
          status: 'Pending',
        ),
        const AppraisalStage(
          label: 'Manager Input',
          status: 'Pending',
        ),
      ];

  static int get completedObjectives =>
      getObjectives().where((o) => o.isCompleted).length;
}