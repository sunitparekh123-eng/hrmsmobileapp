import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/leave.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  LeaveStatus? _selectedLeaveStatusFilter;
  bool _showAllLeaves = false;

  // Form state — fromDate + toDate for date range (1 or 2 days)
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _modalError;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcDuration(DateTime from, DateTime to) {
    return _dateOnly(to).difference(_dateOnly(from)).inDays + 1;
  }

  bool _hasOverlappingLeaveRange(DateTime from, DateTime to, List<LeaveRequest> requests) {
    final f = _dateOnly(from);
    final t = _dateOnly(to);
    return requests.any((r) {
      if (r.status != LeaveStatus.approved && r.status != LeaveStatus.pending) return false;
      final rf = _dateOnly(r.fromDate);
      final rt = _dateOnly(r.toDate);
      return rf.compareTo(t) <= 0 && f.compareTo(rt) <= 0;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _openApplyForm() {
    _fromDate = null;
    _toDate = null;
    _modalError = null;
    _reasonController.clear();
    _contactController.clear();

    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
    final balance = dashboard.leaveBalances.isNotEmpty
        ? dashboard.leaveBalances.first
        : const LeaveBalance(available: 0, used: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return _buildApplyForm(balance, dashboard, setModalState);
        },
      ),
    );
  }

  Future<void> _pickDate(StateSetter setModalState) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() {
        _fromDate = picked;
        // Clear to-date if it's now before the new from-date
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = null;
        }
        _modalError = null;
      });
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _pickToDate(StateSetter setModalState) async {
    if (_fromDate == null) return;
    final now = DateTime.now();
    final first = _fromDate!.isAfter(now) ? _fromDate! : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? first,
      firstDate: first,
      lastDate: _fromDate!.add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() {
        _toDate = picked;
        _modalError = null;
      });
      setState(() {
        _toDate = picked;
      });
    }
  }

  Future<void> _submitLeave(DashboardProvider dashboard, StateSetter setModalState) async {
    if (_fromDate == null) {
      setModalState(() {
        _modalError = 'Please select a from date';
      });
      return;
    }
    if (_toDate == null) {
      setModalState(() {
        _modalError = 'Please select a to date';
      });
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setModalState(() {
        _modalError = 'Please enter a reason';
      });
      return;
    }
    if (reason.length < 10) {
      setModalState(() {
        _modalError =
            'Reason must be at least 10 characters (currently ${reason.length})';
      });
      return;
    }

    final duration = _calcDuration(_fromDate!, _toDate!);

    // Duration must be 1 or 2 days
    if (duration < 1 || duration > 2) {
      setModalState(() {
        _modalError = 'You can only apply for 1 or 2 days of leave at a time.';
      });
      return;
    }

    // Check overlapping leave requests for the date range
    if (_hasOverlappingLeaveRange(_fromDate!, _toDate!, dashboard.leaveRequests)) {
      setModalState(() {
        _modalError = 'You already have a pending/approved leave request that overlaps with these dates';
      });
      return;
    }

    // Check max 2 leaves per month (based on from_date's month)
    final monthKey = '${_fromDate!.year}-${_fromDate!.month}';
    final usedInMonth = dashboard.leaveRequests
        .where((r) =>
            '${r.fromDate.year}-${r.fromDate.month}' == monthKey &&
            (r.status == LeaveStatus.approved || r.status == LeaveStatus.pending))
        .fold(0, (sum, r) => sum + r.duration);
    if (usedInMonth + duration > 2) {
      setModalState(() {
        _modalError = 'You already have $usedInMonth day(s) of leave in this month. With $duration new day(s), this would exceed the maximum of 2 leaves per month.';
      });
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await dashboard.applyLeave(
        fromDate: _fromDate!,
        toDate: _toDate!,
        duration: duration,
        reason: reason,
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
      );

      // Pop loading dialog
      Navigator.of(context).pop();
      // Pop apply form modal
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('EL leave applied for $duration day(s)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      // Pop loading dialog
      Navigator.of(context).pop();
      // Extract detailed validation messages from the backend response
      String displayError = e.message;
      if (e.errors is List && (e.errors as List).isNotEmpty) {
        final parts = (e.errors as List)
            .map((err) {
              if (err is Map) {
                return err['message']?.toString() ?? '';
              }
              return err.toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) {
          displayError = parts.join('\n');
        }
      }
      setModalState(() {
        _modalError = displayError;
      });
    } catch (e) {
      // Pop loading dialog
      Navigator.of(context).pop();
      setModalState(() {
        _modalError = 'Failed to apply leave: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final balances = dashboard.leaveBalances;
    final balance = balances.isNotEmpty ? balances.first : const LeaveBalance(available: 0, used: 0);
    final requests = dashboard.leaveRequests;

    final filteredRequests = requests.where((request) {
      if (_selectedLeaveStatusFilter == null) return true;
      return request.status == _selectedLeaveStatusFilter;
    }).toList();

    final displayedRequests = _showAllLeaves
        ? filteredRequests
        : filteredRequests.take(5).toList();

    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your time off',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openApplyForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Leave Balance Card — simple design matching dashboard style
            _buildBalanceCard(balance),
            const SizedBox(height: 12),

            // Accrual Rules Info
            _buildAccrualInfo(),
            const SizedBox(height: 24),

            // Leave Requests
            SectionHeader(title: 'Leave History'),
            const SizedBox(height: 10),
            _buildLeaveFilterChips(),
            const SizedBox(height: 14),

            if (filteredRequests.isEmpty)
              _buildEmptyState()
            else ...[
              ...displayedRequests.map((request) => _buildRequestCard(request)),
              if (filteredRequests.length > 5) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAllLeaves = !_showAllLeaves;
                      });
                    },
                    icon: Icon(
                      _showAllLeaves ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: Text(
                      _showAllLeaves ? 'Show Less' : 'Show All (${filteredRequests.length})',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(LeaveBalance balance) {
    return Container(
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
                  '${balance.available} available · ${balance.used} used',
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
                  '${balance.available}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: balance.usagePercentage / 100,
                    backgroundColor: AppColors.borderLight,
                    color: AppColors.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccrualInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                'Accrual Rules',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAccrualRow('2 EL earned per month (onboarding grants 2 EL)'),
          const SizedBox(height: 4),
          _buildAccrualRow('Unused leaves carry forward up to 3 months'),
          const SizedBox(height: 4),
          _buildAccrualRow('If unused for 3 consecutive months, accrued leaves expire & reset'),
        ],
      ),
    );
  }

  Widget _buildAccrualRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 24),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(LeaveRequest request) {
    Color statusColor;
    switch (request.status) {
      case LeaveStatus.approved:
        statusColor = AppColors.success;
        break;
      case LeaveStatus.pending:
        statusColor = AppColors.warning;
        break;
      case LeaveStatus.rejected:
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textTertiary;
    }

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.typeLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: request.statusLabel),
              const Spacer(),
              Text(
                '${request.duration} day${request.duration > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                request.dateRange,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
              const Spacer(),
              if (request.remarks != null && request.remarks!.isNotEmpty)
                Text(
                  request.remarks!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyForm(LeaveBalance balance, DashboardProvider dashboard, StateSetter setModalState) {

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply for Leave',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '2 EL per month • Max 2 days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_modalError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _modalError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Balance info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 20, color: AppColors.primaryDark),
                        const SizedBox(width: 10),
                        Text(
                          '${balance.available} EL available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          'Max 2/month',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // From Date picker
                  _formLabel('From Date'),
                  const SizedBox(height: 8),
                  _dateTile(
                    label: 'Select start date',
                    value: _fromDate,
                    onTap: () => _pickDate(setModalState),
                  ),

                  const SizedBox(height: 16),

                  // To Date picker (max 2 days from from-date)
                  _formLabel('To Date'),
                  const SizedBox(height: 8),
                  _dateTile(
                    label: _fromDate == null
                        ? 'Select from date first'
                        : 'Select end date (max 2 days)',
                    value: _toDate,
                    onTap: _fromDate == null
                        ? null
                        : () => _pickToDate(setModalState),
                  ),

                  if (_fromDate != null && _toDate != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_calcDuration(_fromDate!, _toDate!)} day(s) EL leave from ${_formatShortDate(_fromDate!)} to ${_formatShortDate(_toDate!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Reason
                  _formLabel('Reason'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    maxLength: 200,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Briefly describe why you need leave...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact during leave
                  _formLabel('Contact During Leave (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '+91-9876543210',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.call_rounded, size: 18),
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _submitLeave(dashboard, setModalState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SUBMIT REQUEST',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceSecondary
              : AppColors.borderLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: onTap != null
              ? Border.all(color: AppColors.borderLight)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: value != null ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? _formatShortDate(value)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
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
            Icon(Icons.beach_access, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('No leave requests yet', style: TextStyle(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveFilterChips() {
    final filters = [
      (label: 'All', value: null),
      (label: 'Pending', value: LeaveStatus.pending),
      (label: 'Approved', value: LeaveStatus.approved),
      (label: 'Rejected', value: LeaveStatus.rejected),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedLeaveStatusFilter == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedLeaveStatusFilter = filter.value;
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSecondary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}