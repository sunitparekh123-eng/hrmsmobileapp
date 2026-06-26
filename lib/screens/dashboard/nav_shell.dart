import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../leave/leave_screen.dart';
import '../payroll/payroll_screen.dart';
import '../loans/loans_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _currentIndex = 0;

  // Keep screen references for state preservation, but only render the active one.
  // IndexedStack forces all children into a Stack with StackParentData, which causes
  // semantics parentDataDirty assertion errors when multiple screens rebuild simultaneously
  // from provider changes. Rendering only the active screen eliminates this issue.
  final Map<int, GlobalKey> _screenKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // Load dashboard data on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildActiveScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          key: _screenKeys[0],
          onNavigate: _navigateToTab,
        );
      case 1:
        return AttendanceScreen(key: _screenKeys[1]);
      case 2:
        return LeaveScreen(key: _screenKeys[2]);
      case 3:
        return PayrollScreen(key: _screenKeys[3]);
      case 4:
        return LoansScreen(key: _screenKeys[4]);
      default:
        return DashboardScreen(
          key: _screenKeys[0],
          onNavigate: _navigateToTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Company logo placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspaces_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'NexGen',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _buildActiveScreen(),
      // Use BottomNavigationBar directly in the Scaffold slot with built-in styling.
      // Wrapping in Container > SafeArea > Padding breaks Scaffold's parent data chain
      // for the bottomNavigationBar slot, causing semantics parentDataDirty assertion errors.
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            context.read<DashboardProvider>().loadDashboard();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint_outlined),
            activeIcon: Icon(Icons.fingerprint),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.beach_access_outlined),
            activeIcon: Icon(Icons.beach_access),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Payroll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Loans',
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}