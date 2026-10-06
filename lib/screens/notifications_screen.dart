import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'ride_accepted':
        return Icons.check_circle_rounded;
      case 'ride_denied':
        return Icons.cancel_rounded;
      case 'ride_request':
        return Icons.person_pin_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'ride_accepted':
        return AppTheme.successColor;
      case 'ride_denied':
        return AppTheme.errorColor;
      case 'ride_request':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final items = _notificationService.notifications;
    final unreadCount = _notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _notificationService.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyStateWidget(
              title: 'No notifications yet',
              message:
                  'You will receive in-app notifications when hosts accept or deny your ride requests.',
              icon: Icons.notifications_none_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = _getColorForType(item.type);
                final icon = _getIconForType(item.type);
                final isUnread = !item.isRead;

                return InkWell(
                  onTap: () async {
                    if (isUnread) {
                      await _notificationService.markAsRead(item.id);
                    }
                    if (!context.mounted) return;
                    if (item.relatedRequestId.isNotEmpty) {
                      HomeScreen.switchToTab(1); // Switch to My Rides
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnread
                            ? color.withValues(alpha: 0.4)
                            : AppTheme.borderColor,
                        width: isUnread ? 1.5 : 1,
                      ),
                      boxShadow: isUnread
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUnread
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  height: 1.35,
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(item.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
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
    );
  }
}
