import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/features/notifications/controller/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              "Notifications",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back, color: AppColors.black),
            ),
            actions: [
              if (controller.notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: controller.markAllAsRead,
                  child: const Text(
                    "Mark all as read",
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ),
            ],
            backgroundColor: AppColors.white,
            elevation: 0.5,
          ),
          body:
              controller.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : controller.notifications.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 60,
                          color: AppColors.textMuted.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No new notifications",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: controller.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = controller.notifications[index];
                      return _buildNotificationCard(
                        context,
                        notification,
                        controller,
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
    NotificationsController controller,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification.id, context);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
        color: AppColors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Icon(
            notification.isRead
                ? Icons.notifications_active
                : Icons.circle_sharp,
            color:
                notification.isRead ? AppColors.textMuted : AppColors.primary,
            size: notification.isRead ? 20.0 : 12.0,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: TextStyle(color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatNotificationTime(notification.timestamp),
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          onTap: () {
            controller.markAsRead(notification.id);
            // Optionally navigate to details or handle notification action
          },
        ),
      ),
    );
  }

  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}
