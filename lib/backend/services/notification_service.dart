import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import 'auth_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final NotificationRepository _notifRepo = NotificationRepository();
  final AuthService _authService = AuthService();

  List<AppNotification> _notifications = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isInitialized = false;

  // Track latest notification ID to broadcast new in-app alerts
  String? _lastNotifiedId;
  final ValueNotifier<AppNotification?> latestNotification = ValueNotifier<AppNotification?>(null);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _startListening();
    _authService.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    final currentUserId = _authService.currentUser?.id ?? '';

    if (currentUserId.isEmpty) {
      _notifications = [];
      notifyListeners();
      return;
    }

    try {
      _subscription = _notifRepo
          .streamNotifications(currentUserId)
          .listen(
        (snapshot) {
          final items = snapshot.docs.map((doc) {
            return AppNotification.fromFirestore(doc.data(), doc.id);
          }).toList();

          // Sort in memory by createdAt descending to avoid composite index requirements
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Check if there is a newly received unread notification
          if (items.isNotEmpty) {
            final newest = items.first;
            if (!newest.isRead && newest.id != _lastNotifiedId) {
              _lastNotifiedId = newest.id;
              latestNotification.value = newest;
            }
          }

          _notifications = items;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('NotificationService stream notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Error starting notification listener: $e');
    }
  }

  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String message,
    required String relatedRequestId,
    required String type,
  }) async {
    if (recipientId.isEmpty) return;

    try {
      final docId = _notifRepo.newNotificationId();
      final data = {
        'id': docId,
        'recipientId': recipientId,
        'title': title,
        'message': message,
        'relatedRequestId': relatedRequestId,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _notifRepo.saveNotification(docId, data);
    } catch (e) {
      debugPrint('Notice: Error creating notification in Firestore: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifRepo.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read in Firestore: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final item in unread) {
      await markAsRead(item.id);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
