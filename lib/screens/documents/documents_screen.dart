import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../models/document.dart';
import '../../providers/dashboard_provider.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<DashboardProvider>().myDocuments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('My Documents', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'All your official documents at one place',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),

          // Upload CTA
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showUploadSnackbar(context),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload New Document',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Document list
          ...docs.map((doc) => _buildDocumentCard(context, doc)),
        ],
      ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, EmployeeDocument doc) {
    final statusColor = switch (doc.status) {
      DocumentStatus.verified => AppColors.success,
      DocumentStatus.pending => AppColors.warning,
      DocumentStatus.rejected => AppColors.error,
    };
    final statusBg = switch (doc.status) {
      DocumentStatus.verified => AppColors.successBg,
      DocumentStatus.pending => AppColors.warningBg,
      DocumentStatus.rejected => AppColors.errorBg,
    };
    final iconData = switch (doc.type) {
      DocumentType.aadhaar => Icons.credit_card,
      DocumentType.pan => Icons.credit_card,
      DocumentType.bankPassbook => Icons.account_balance,
      DocumentType.pfStatement => Icons.savings,
      DocumentType.uanCard => Icons.badge,
      DocumentType.licPolicy => Icons.assured_workload,
      DocumentType.offerLetter => Icons.description,
      DocumentType.appointmentLetter => Icons.assignment_turned_in,
      DocumentType.other => Icons.insert_drive_file,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(doc.fileName ?? '', style: Theme.of(context).textTheme.bodySmall),
                    if (doc.verifiedBy != null) ...[
                      const SizedBox(width: 8),
                      Text('• Verified by ${doc.verifiedBy}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              doc.statusLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document upload will be available in the next release.',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}