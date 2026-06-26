import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/nav_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    // Try to restore session from stored token
    final loggedIn = await authProvider.tryAutoLogin();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            loggedIn ? const NavShell() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primaryBg,
              AppColors.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon with glow
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (_, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.badge_rounded,
                    size: 52,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (_, child) => Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
              child: Column(
                children: [
                  Text(
                    'HRMS',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: 6,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EMPLOYEE PORTAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 8,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Tagline
            Opacity(
              opacity: 0.4,
              child: Text(
                'Seamless Workforce Management',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}