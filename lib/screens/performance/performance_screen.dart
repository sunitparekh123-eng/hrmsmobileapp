import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/mock/mock_performance.dart';
import '../../widgets/common/common_widgets.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final metrics = dashboard.performanceMetrics;
    final objectives = dashboard.objectives;
    final stages = MockPerformanceData.getAppraisalStages();

    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Growth & appraisal tracker',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Performance Metrics Cards
            _buildMetricsCards(metrics),
            const SizedBox(height: 24),

            // Objectives
            SectionHeader(
              title: 'Objective Tracking',
              subtitle: '${metrics.objectivesCompleted}/${metrics.totalObjectives} completed',
            ),
            const SizedBox(height: 8),
            ...objectives.map((obj) => _buildObjectiveCard(obj)),
            const SizedBox(height: 24),

            // Appraisal Status
            _buildAppraisalSection(stages),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards(dynamic metrics) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 22),
                const SizedBox(height: 10),
                Text(
                  '${metrics.recognitionPoints}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text('Recognition Pts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.speed, color: AppColors.purple, size: 22),
                const SizedBox(height: 10),
                Text(
                  metrics.projectVelocity,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text('Velocity',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectiveCard(dynamic objective) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  objective.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              StatusBadge(label: objective.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: objective.progress / 100,
                    backgroundColor: AppColors.borderLight,
                    color: objective.isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${objective.progress.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (objective.description != null) ...[
            const SizedBox(height: 8),
            Text(
              objective.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppraisalSection(dynamic stages) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Appraisal Cycle',
            subtitle: 'Q1 2026',
          ),
          const SizedBox(height: 8),
          ...stages.map((stage) {
            final isCompleted = stage.isCompleted;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.successBg
                          : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.access_time,
                      size: 16,
                      color: isCompleted ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stage.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  StatusBadge(
                    label: stage.status,
                    color: isCompleted ? AppColors.successBg : AppColors.warningBg,
                    textColor: isCompleted ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}