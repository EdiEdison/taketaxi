import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsController extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  NotificationsController() {
    _loadNotifications(); // Load dummy data on init
  }

  void _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    // Simulate fetching notifications
    await Future.delayed(const Duration(seconds: 1));

    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Ride Confirmed!',
        body: 'Your ride to Buea Town is confirmed. Driver en route.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Payment Processed',
        body: 'Your payment for the last ride has been successfully processed.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: 'New Feature Alert!',
        body: 'Check out our new feature: Scheduled Rides!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: '4',
        title: 'Security Update',
        body: 'Please update your password for enhanced security.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Your driver has arrived!',
        body: 'Your driver is waiting at your pickup location.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isRead: false,
      ),
    ];
    _notifications.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    ); // Sort by newest first
    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      log("Notification $id marked as read.");
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      log("All notifications marked as read.");
    }
  }

  void deleteNotification(String id, BuildContext context) async {
    // Simulate deletion
    _isLoading = true;
    notifyListeners();
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate API call

    _notifications.removeWhere((n) => n.id == id);
    _isLoading = false;
    notifyListeners();
    showCustomSnackbar(context, "Notification deleted.", ToastType.success);
    log("Notification $id deleted.");
  }
}
