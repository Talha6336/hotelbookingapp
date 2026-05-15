import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'notification_model.dart';
import 'notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking_pending':
        return Icons.pending_actions_rounded;
      case 'booking_approved':
        return Icons.check_circle_rounded;
      case 'booking_rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'booking_pending':
        return Colors.orange;
      case 'booking_approved':
        return Colors.green;
      case 'booking_rejected':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Text(
              'Please login first',
              style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppBackground(
        useSafeArea: true,
        child: Column(
          children: [
            _buildHeader(context, uid),

            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: NotificationService.getUserNotifications(
                  userId: uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Unable to load notifications\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(context, notifications[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.adaptiveSurface(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.adaptiveBorder(context),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.adaptiveShadow(context),
                    blurRadius: 10,
                  )
                ]
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.adaptiveTextPrimary(context),
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              NotificationService.markAllAsRead(userId: uid);
            },
            child: const Text(
              'Mark all',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.adaptiveBorder(context),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.adaptiveShadow(context),
                blurRadius: 20,
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 74,
                color: AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking updates will appear here.',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final color = _getColor(notification.type);
    final icon = _getIcon(notification.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (!notification.isRead) {
          NotificationService.markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.adaptiveSurface(context)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? AppColors.adaptiveBorder(context)
                : AppColors.primary.withValues(alpha: 0.3),
          ),
          boxShadow: notification.isRead 
            ? [BoxShadow(color: AppColors.adaptiveShadow(context), blurRadius: 10, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 15,
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      color: AppColors.adaptiveTextTertiary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (!notification.isRead)
              Container(
                height: 9,
                width: 9,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}