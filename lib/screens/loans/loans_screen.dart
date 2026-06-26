import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/loans.dart';
import '../../data/mock/mock_loans.dart';
import '../../widgets/common/common_widgets.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final loans = dashboard.myLoans;

    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loans',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your advances & loans',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary
            _buildSummary(loans),
            const SizedBox(height: 20),

            // Loan List
            ...loans.map((loan) => _buildLoanCard(loan)),

            if (loans.isEmpty)
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(List<dynamic> loans) {
    final active = loans.where((l) => l.status == LoanStatus.active);
    final totalBorrowed = active.fold<double>(0, (s, l) => s + l.principal);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Active Loans',
            value: '${active.length}',
            icon: Icons.credit_card_rounded,
            iconColor: AppColors.purple,
            backgroundColor: AppColors.purpleBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Total Borrowed',
            value: '₹${_formatCurrency(totalBorrowed)}',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.warning,
            backgroundColor: AppColors.warningBg,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    final statusColor = switch (loan.status as LoanStatus) {
      LoanStatus.active => AppColors.success,
      LoanStatus.pending => AppColors.warning,
      LoanStatus.closed => AppColors.textTertiary,
      LoanStatus.rejected => AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.typeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 13,
                          ),
                    ),
                    Text(
                      'ID: ${loan.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: loan.statusLabel,
                color: statusColor.withValues(alpha: 0.12),
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLoanDetail('Principal', loan.formattedPrincipal),
              const SizedBox(width: 16),
              _buildLoanDetail('EMI/mo', loan.formattedEmi),
              const SizedBox(width: 16),
              _buildLoanDetail('Remaining', loan.formattedRemaining),
            ],
          ),
          if (loan.status == LoanStatus.active) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Repayment',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 9)),
                          Text(
                            '${loan.paidPercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: loan.paidPercentage / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.borderLight,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      loan.formattedRemaining,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                    ),
                    Text(
                      'remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (loan.nextEmiDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningBg.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Next EMI: ${_formatDate(loan.nextEmiDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.credit_card_off, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('No loans found', style: TextStyle(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(0).split('.');
    final chars = parts[0].split('').reversed.toList();
    final formatted = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 2 == 0 && i != chars.length - 1) {
        formatted.add(',');
      }
      formatted.add(chars[i]);
    }
    return formatted.reversed.join();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}