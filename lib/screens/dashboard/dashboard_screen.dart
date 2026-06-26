import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final employee = auth.currentEmployee;

    // Data is pre-populated in DashboardProvider — no loading state needed.
    // Always render the same widget tree structure to prevent parentDataDirty errors.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(employee?.name ?? 'Employee'),
            const SizedBox(height: 20),
            _buildAttendanceCard(dashboard),
            const SizedBox(height: 24),
            _buildLeaveSection(dashboard),
            const SizedBox(height: 24),
            _buildLoanSection(dashboard),
            const SizedBox(height: 24),
            _buildMonthCalendar(dashboard),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Text(
            _getFormattedDate(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: AppColors.primaryDark,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(DashboardProvider dashboard) {
    final status = dashboard.todayStatus;
    final isCheckedIn = status['isCheckedIn'] ?? false;
    final isCheckedOut = status['isCheckedOut'] ?? false;
    final cardThemeColor = isCheckedOut
        ? AppColors.info
        : (isCheckedIn ? AppColors.success : AppColors.warning);
    final cardThemeBg = isCheckedOut
        ? AppColors.infoBg
        : (isCheckedIn ? AppColors.successBg : AppColors.warningBg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardThemeBg, cardThemeBg.withValues(alpha: 0.4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardThemeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardThemeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCheckedOut
                      ? Icons.check_circle_rounded
                      : Icons.fingerprint,
                  size: 24,
                  color: cardThemeColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Attendance',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      isCheckedOut
                          ? 'Day Complete (${status['status']})'
                          : (status['status'] ?? 'Not Marked'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: cardThemeColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isCheckedOut
                    ? null
                    : () {
                        widget.onNavigate?.call(1); // Switch to attendance tab
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedOut
                      ? Colors.grey.shade400
                      : (isCheckedIn ? AppColors.success : AppColors.primary),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                child: Text(isCheckedOut
                    ? 'COMPLETED'
                    : (isCheckedIn ? 'CHECK OUT' : 'CHECK IN')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeBox(
                'Check In',
                status['checkInTime'] ?? '--:--',
                Icons.login_rounded,
              ),
              const SizedBox(width: 12),
              _buildTimeBox(
                'Check Out',
                status['checkOutTime'] ?? '--:--',
                Icons.logout_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLeaveSection(DashboardProvider dashboard) {
    final balances = dashboard.leaveBalances;
    // Leave policy: 1 earned leave per month, carry-forward max 1 month
    // (so max 2 leaves available), lapse if unused for 2 consecutive months
    final balance = balances.isNotEmpty ? balances.first : null;
    final available = balance?.available ?? 0;
    final used = balance?.used ?? 0;
    final lapsed = balance?.lapsed ?? 0;
    final maxAllowed = 2; // policy: max 2 available at any time
    final usageFrac = maxAllowed > 0 ? (used / maxAllowed).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Leave Balance',
          subtitle: '1 Earned Leave / month · Max 2 carry-forward',
          onAction: () => widget.onNavigate?.call(2),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
                child: const Icon(Icons.event_note_rounded,
                    color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned Leave (EL)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$available available · $used used${lapsed > 0 ? ' · $lapsed lapsed' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: available > 0
                                ? AppColors.primaryDark
                                : AppColors.textTertiary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usageFrac,
                        backgroundColor: AppColors.borderLight,
                        color: available > 0 ? AppColors.primary : AppColors.warning,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'max $maxAllowed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 8,
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalarySection(DashboardProvider dashboard) {
    final payslip = dashboard.latestPayslip;
    final summary = dashboard.salarySummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Salary Overview',
          subtitle: payslip.month,
          onAction: () => widget.onNavigate?.call(3),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              // Net Pay and Deduction cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successBg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Pay',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            payslip.formattedNet,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deductions',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            payslip.formattedDeductions,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Working days info chips
              Row(
                children: [
                  _buildMiniInfoChip('Working Days', '${payslip.workingDays}'),
                  const SizedBox(width: 8),
                  _buildMiniInfoChip('Paid Days', '${payslip.paidDays}'),
                  if (payslip.lopDays > 0) ...[
                    const SizedBox(width: 8),
                    _buildMiniInfoChip('LOP Days', '${payslip.lopDays}', color: AppColors.error),
                  ],
                ],
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                // 6-month salary trend chart
                // ExcludeSemantics prevents fl_chart's custom render objects
                // from corrupting the semantics tree during rebuilds
                ExcludeSemantics(
                  child: SizedBox(
                    height: 140,
                    child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: summary
                              .map((s) => (s['netSalary'] as double))
                              .reduce(
                                  (a, b) => a > b ? a : b) *
                          1.3,
                      barGroups: summary.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['netSalary'] as double),
                              color: AppColors.primary,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < summary.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    summary[idx]['month'].toString().substring(0, 3),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: null,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.borderLight,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                ), // closes ExcludeSemantics
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanSection(DashboardProvider dashboard) {
    final loans = dashboard.activeLoans;
    if (loans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Active Loans',
          subtitle: '${loans.length} active loan(s)',
          onAction: () => widget.onNavigate?.call(4),
        ),
        const SizedBox(height: 8),
        ...loans.map((loan) => Container(
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.purpleBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          size: 18,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.typeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 13),
                            ),
                            Text(
                              'EMI: ${loan.formattedEmi}/mo',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            loan.formattedRemaining,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                          ),
                          Text(
                            'remaining',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.paidPercentage / 100,
                      backgroundColor: AppColors.borderLight,
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loan.paidPercentage.toStringAsFixed(1)}% paid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            )),
      ],
    );
  }


  Widget _buildMonthCalendar(DashboardProvider dashboard) {
    final monthData = dashboard.currentMonthAttendance;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon..7=Sun
    final today = now.day;

    const dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Build lookup map from records
    final recordMap = <int, AttendanceRecord>{};
    for (final r in monthData.records) {
      recordMap[r.date.day] = r;
    }

    // Build calendar rows: each row has 7 cells (null for blanks)
    final rows = <List<int?>>[];
    var currentRow = <int?>[];

    // Add leading blank cells
    for (var i = 1; i < firstWeekday; i++) {
      currentRow.add(null);
    }

    // Add day cells
    for (var d = 1; d <= daysInMonth; d++) {
      currentRow.add(d);
      if (currentRow.length == 7) {
        rows.add(currentRow);
        currentRow = <int?>[];
      }
    }

    // Pad last row with blanks
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(null);
      }
      rows.add(currentRow);
    }

    // Attendance percentage
    final percentage = monthData.attendancePercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '${_monthName(now.month)} ${now.year} Attendance',
          subtitle: '${monthData.presentDays}P · ${monthData.absentDays}A · ${monthData.lateDays}L · ${monthData.halfDays}HD',
          onAction: () => widget.onNavigate?.call(1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Attendance percentage bar
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Rate',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppColors.borderLight,
                            color: percentage >= 85
                                ? AppColors.success
                                : percentage >= 60
                                    ? AppColors.warning
                                    : AppColors.error,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              // Day headers row
              Row(
                children: dayHeaders.map((h) {
                  final isWeekend = h == 'Sat' || h == 'Sun';
                  return Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isWeekend
                              ? AppColors.error.withValues(alpha: 0.7)
                              : AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid rows
              ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: row.map((day) {
                    if (day == null) {
                      return const Expanded(child: _CalendarCell.empty());
                    }

                    final record = recordMap[day];
                    final isToday = day == today;
                    final isFuture = day > today;
                    final isWeekend = DateTime(now.year, now.month, day).weekday >= 6;

                    Color bgColor;
                    Color textColor;
                    String? statusLetter;

                    if (isFuture) {
                      bgColor = AppColors.borderLight.withValues(alpha: 0.5);
                      textColor = AppColors.textTertiary.withValues(alpha: 0.3);
                      statusLetter = null;
                    } else if (record != null) {
                      statusLetter = record.statusLetter;
                      switch (record.status) {
                        case AttendanceStatus.present:
                          bgColor = AppColors.successBg;
                          textColor = AppColors.success;
                          break;
                        case AttendanceStatus.late:
                          bgColor = AppColors.warningBg;
                          textColor = AppColors.warning;
                          break;
                        case AttendanceStatus.absent:
                          bgColor = AppColors.errorBg;
                          textColor = AppColors.error;
                          break;
                        case AttendanceStatus.halfDay:
                          bgColor = AppColors.infoBg;
                          textColor = AppColors.info;
                          break;
                        case AttendanceStatus.weekend:
                          bgColor = AppColors.surfaceSecondary;
                          textColor = AppColors.textTertiary.withValues(alpha: 0.5);
                          break;
                        case AttendanceStatus.holiday:
                          bgColor = AppColors.purpleBg;
                          textColor = AppColors.purple;
                          break;
                      }
                    } else if (isWeekend) {
                      bgColor = AppColors.surfaceSecondary;
                      textColor = AppColors.textTertiary.withValues(alpha: 0.5);
                      statusLetter = 'W';
                    } else {
                      bgColor = AppColors.borderLight.withValues(alpha: 0.5);
                      textColor = AppColors.textTertiary.withValues(alpha: 0.3);
                      statusLetter = null;
                    }

                    return Expanded(
                      child: _CalendarCell(
                        day: day,
                        backgroundColor: bgColor,
                        textColor: textColor,
                        statusLetter: statusLetter,
                        isToday: isToday,
                        isFuture: isFuture,
                      ),
                    );
                  }).toList(),
                ),
              )),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              // Legend with letter codes
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _legendItem(AppColors.success, 'P', 'Present'),
                  _legendItem(AppColors.warning, 'L', 'Late'),
                  _legendItem(AppColors.error, 'A', 'Absent'),
                  _legendItem(AppColors.info, 'HD', 'Half-Day'),
                  _legendItem(AppColors.purple, 'H', 'Holiday'),
                  _legendItem(AppColors.textTertiary, 'W', 'Weekend'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String letter, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfoChip(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: (color ?? AppColors.info).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color ?? AppColors.info)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]}, ${now.year}';
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final Color backgroundColor;
  final Color textColor;
  final String? statusLetter;
  final bool isToday;
  final bool isFuture;

  const _CalendarCell({
    required this.day,
    required this.backgroundColor,
    required this.textColor,
    this.statusLetter,
    this.isToday = false,
    this.isFuture = false,
  });

  const _CalendarCell.empty()
      : day = 0,
        backgroundColor = Colors.transparent,
        textColor = Colors.transparent,
        statusLetter = null,
        isToday = false,
        isFuture = false;

  @override
  Widget build(BuildContext context) {
    if (day == 0) {
      return const SizedBox(height: 52);
    }

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isToday
            ? Border.all(color: AppColors.primary, width: 2.5)
            : null,
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          if (statusLetter != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: statusLetter!.length > 1 ? 3 : 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                statusLetter!,
                style: TextStyle(
                  fontSize: statusLetter!.length > 1 ? 7 : 8,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}