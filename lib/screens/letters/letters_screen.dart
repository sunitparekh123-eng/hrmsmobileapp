import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/letter.dart';
import '../../providers/dashboard_provider.dart';

class LettersScreen extends StatelessWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final letters = context.watch<DashboardProvider>().myLetters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters & Notices'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Letters & Notices', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Official letters issued to you',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),

          if (letters.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.mail_outline, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No letters yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else
            ...letters.map((letter) => _buildLetterCard(context, letter)),
        ],
      ),
      ),
    );
  }

  Widget _buildLetterCard(BuildContext context, EmployeeLetter letter) {
    final iconData = switch (letter.type) {
      LetterType.offer => Icons.work_outline,
      LetterType.appointment => Icons.assignment_turned_in,
      LetterType.warning => Icons.warning_amber,
      LetterType.nonPerformance => Icons.trending_down,
      LetterType.absenteeism => Icons.event_busy,
    };
    final colorBg = switch (letter.type) {
      LetterType.offer => AppColors.successBg,
      LetterType.appointment => AppColors.infoBg,
      LetterType.warning => AppColors.warningBg,
      LetterType.nonPerformance => AppColors.errorBg,
      LetterType.absenteeism => AppColors.purpleBg,
    };
    final colorIcon = switch (letter.type) {
      LetterType.offer => AppColors.success,
      LetterType.appointment => AppColors.info,
      LetterType.warning => AppColors.warning,
      LetterType.nonPerformance => AppColors.error,
      LetterType.absenteeism => AppColors.purple,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: colorBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(iconData, color: colorIcon, size: 20),
          ),
          title: Text(letter.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text(
            '${_formatDate(letter.issuedOn)}${letter.emailed ? '  •  Emailed' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                letter.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}