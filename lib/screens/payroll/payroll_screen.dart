import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final payslips = dashboard.payslipsHistory;

    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payslips',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Download your monthly payslips',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Payslip History
            ...payslips.map((p) => _buildPayslipItem(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipItem(dynamic payslip) {
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
            child: const Icon(Icons.receipt_long,
                color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payslip.month,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${payslip.paidDays} days paid',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final today = DateTime.now().day;
              if (today > 7) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payslip download is only available from 1st to 7th of the month.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              _downloadPayslip(payslip.id, payslip.month);
            },
            icon: const Icon(Icons.download_rounded, size: 20),
            color: AppColors.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payslip.formattedNet,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
              ),
              StatusBadge(label: payslip.paymentStatus ?? 'Paid'),
            ],
          ),
        ],
      ),
    );
  }

  bool _isDownloading = false;

  Future<void> _downloadPayslip(String payslipId, String month) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final messenger = ScaffoldMessenger.of(context);

    // Show progress indicator
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Downloading payslip for $month…'),
          ],
        ),
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );

    try {
      final api = context.read<ApiService>();
      final bytes = await api.downloadBytes('/payroll/payslips/$payslipId/download');

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Payslip_${month.replaceAll(' ', '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // Open the downloaded PDF
      await OpenFilex.open(file.path);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Payslip downloaded successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _format(double value) {
    return value.toStringAsFixed(0);
  }
}