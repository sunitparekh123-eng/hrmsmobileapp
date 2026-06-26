import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.getAuth('/notifications?limit=50');
      setState(() {
        _notifications = res ?? [];
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final api = context.read<ApiService>();
      await api.patchAuth('/notifications/mark-all-read', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }

  Future<void> _markAsRead(int id, bool isRead) async {
    if (isRead) return;
    try {
      final api = context.read<ApiService>();
      await api.patchAuth('/notifications/$id/read', {});
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          _notifications[idx]['is_read'] = true;
        }
      });
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return Icons.beach_access_rounded;
      case 'PAYROLL':
        return Icons.account_balance_wallet_rounded;
      case 'ATTENDANCE':
        return Icons.fingerprint_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return AppColors.warning;
      case 'PAYROLL':
        return AppColors.success;
      case 'ATTENDANCE':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _notifications.any((n) => n['is_read'] == false) ? _markAllAsRead : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['is_read'] == true;
                      final type = notif['type'] ?? 'SYSTEM';
                      
                      return InkWell(
                        onTap: () => _markAsRead(notif['id'], isRead),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? AppColors.surface : AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getColorForType(type).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconForType(type),
                                  color: _getColorForType(type),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif['title'] ?? 'Notification',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                  color: isRead ? null : AppColors.primaryDark,
                                                ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['message'] ?? '',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isRead ? AppColors.textTertiary : AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDate(notif['created_at']),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
