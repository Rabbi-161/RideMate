import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_constants.dart';

/// Client-side repository handling Cloud Firestore operations for
/// the `notifications` collection.
class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection(FirestoreCollections.notifications);

  /// Generates a new unique notification document ID.
  String newNotificationId() => _notificationsCol.doc().id;

  /// Real-time stream of notifications for a recipient.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications(String recipientId) {
    return _notificationsCol
        .where('recipientId', isEqualTo: recipientId)
        .snapshots();
  }

  /// Writes a notification document to Firestore.
  Future<void> saveNotification(String id, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _notificationsCol.doc(id).set(data).timeout(timeout);
  }

  /// Updates a notification document to mark as read.
  Future<void> markAsRead(String notificationId,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _notificationsCol.doc(notificationId).update({
      'isRead': true,
    }).timeout(timeout);
  }
}
