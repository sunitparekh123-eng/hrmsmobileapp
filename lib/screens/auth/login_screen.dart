import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/nav_shell.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const NavShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.1),

                // Header
                Center(
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'Welcome Back!',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontSize: 28),
                      ).animate().fadeIn(delay: 200.ms).slideY(
                            begin: -0.2,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 6),

                      Text(
                        'Sign in to your employee account',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.06),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    if (auth.error != null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 400.ms);
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Email Field
                Text(
                  'WORK EMAIL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    hintText: 'arjun.singh@company.com',
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(
                      begin: -0.1,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 22),

                // Password Field
                Text(
                  'PASSWORD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideX(
                      begin: -0.1,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 16),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, auth, child) => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const Text(
                              'SIGN IN',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(
                      begin: 0.3,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),

                // Help text
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Employee login only',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          // Could open support
                        },
                        icon: const Icon(Icons.headset_mic_outlined, size: 16),
                        label: Text(
                          'Need help? Contact HR Support',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms),

                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}