import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HRMSMobileApp());
}

class HRMSMobileApp extends StatelessWidget {
  const HRMSMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'HRMS Employee',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
