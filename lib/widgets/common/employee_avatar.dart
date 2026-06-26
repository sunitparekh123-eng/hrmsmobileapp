import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

class EmployeeAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;
  final String? imageUrl;

  const EmployeeAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize = 16,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0].toUpperCase();
    if (parts.length > 1) {
      return first + parts.last[0].toUpperCase();
    }
    return first;
  }
}