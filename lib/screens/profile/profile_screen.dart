import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/employee_avatar.dart';
import '../../widgets/common/common_widgets.dart';
import '../../models/document.dart';
import '../../models/letter.dart';
import '../../data/mock/mock_documents.dart';
import '../auth/login_screen.dart';
import '../documents/documents_screen.dart';
import '../letters/letters_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/attendance_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee;

    if (employee == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final docs = context.watch<DashboardProvider>().myDocuments;
    final letters = context.watch<DashboardProvider>().myLetters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header — SOW 3.1 full employee identity
          Center(
            child: Column(
              children: [
                EmployeeAvatar(name: employee.name, size: 88, fontSize: 32),
                const SizedBox(height: 16),
                Text(employee.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(employee.designation, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '${employee.department} • ${employee.branch}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -- Personal Information (Employment) --
          _buildSection(context, 'Personal Information', [
            InfoRow(label: 'Employee ID', value: employee.employeeId, icon: Icons.badge),
            InfoRow(label: 'Email', value: employee.email, icon: Icons.email),
            InfoRow(label: 'Phone', value: employee.phone, icon: Icons.phone),
            InfoRow(label: 'Blood Group', value: employee.bloodGroup, icon: Icons.bloodtype),
            InfoRow(label: 'Gender', value: employee.gender.isNotEmpty ? employee.gender : '—', icon: Icons.person),
            InfoRow(label: 'DOB', value: _formatDateOrNA(employee.dateOfBirth), icon: Icons.cake),
            InfoRow(label: 'Join Date', value: _formatDate(employee.joiningDate), icon: Icons.calendar_today),
            InfoRow(label: 'Address', value: employee.address.isNotEmpty ? employee.address : '—', icon: Icons.location_on),
            InfoRow(label: 'Location / Branch', value: employee.location.isNotEmpty ? employee.location : employee.branch, icon: Icons.business),
            InfoRow(label: 'Emergency Contact', value: employee.emergencyContact, icon: Icons.emergency),
            InfoRow(label: 'Relation', value: employee.emergencyContactRelation.isNotEmpty ? employee.emergencyContactRelation : '—', icon: Icons.people),
          ]),
          const SizedBox(height: 16),

          // -- Identity & Statutory Details --
          _buildSection(context, 'Identity & Statutory', [
            InfoRow(label: 'Aadhaar', value: employee.aadhaarNumber, icon: Icons.credit_card),
            InfoRow(label: 'PAN', value: employee.panNumber, icon: Icons.credit_card),
            InfoRow(label: 'UAN', value: employee.uan, icon: Icons.badge),
            InfoRow(label: 'PF Number', value: employee.pfNumber, icon: Icons.savings),
          ]),
          const SizedBox(height: 16),

          // -- Bank Details --
          if (employee.bankName.isNotEmpty) ...[
            _buildSection(context, 'Bank Details', [
              InfoRow(label: 'Bank', value: employee.bankName, icon: Icons.account_balance),
              InfoRow(label: 'Account', value: employee.accountNumber, icon: Icons.account_balance_wallet),
              InfoRow(label: 'IFSC', value: employee.ifscCode, icon: Icons.qr_code),
              InfoRow(label: 'LIC', value: employee.licDetails, icon: Icons.assured_workload),
            ]),
            const SizedBox(height: 16),
          ],


          // -- SOW 3.1 & 3.7: Quick-access tiles for Documents & Letters --
          _buildQuickAccessCard(context, docs, letters),
          const SizedBox(height: 16),

          // Actions
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildActionTile(Icons.settings, 'Settings', () {}),
                const Divider(height: 1),
                _buildActionTile(Icons.help_outline, 'Help & Support', () {}),
                const Divider(height: 1),
                _buildActionTile(Icons.info_outline, 'About HRMS', () {}),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                // Reset all provider state BEFORE clearing auth tokens
                // so the next employee never sees stale data
                if (mounted) {
                  context.read<DashboardProvider>().reset();
                  context.read<AttendanceProvider>().reset();
                }
                await auth.logout();
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('LOGOUT',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSalaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
          ),
        ],
      ),
    );
  }

  // -- SOW 3.1 & 3.7: Documents & Letters quick-access card --
  Widget _buildQuickAccessCard(
    BuildContext context,
    List<EmployeeDocument> docs,
    List<EmployeeLetter> letters,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Documents & Letters'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickTile(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'My Documents',
                  subtitle: '${docs.length} documents',
                  badge: _pendingDocCount(docs),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickTile(
                  context,
                  icon: Icons.mail_outline,
                  title: 'Letters',
                  subtitle: '${letters.length} letters',
                  badge: letters.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LettersScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _pendingDocCount(List<EmployeeDocument> docs) {
    return docs.where((d) => d.status == DocumentStatus.pending).length;
  }

  Widget _buildQuickTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primaryDark, size: 22),
                  ),
                  const Spacer(),
                  if (badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
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
          SectionHeader(title: title),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  String _formatDateOrNA(DateTime? d) {
    if (d == null) return '—';
    return _formatDate(d);
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
}