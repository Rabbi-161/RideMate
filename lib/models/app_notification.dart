import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String relatedRequestId;
  final String type; // 'ride_accepted', 'ride_denied', 'ride_request'
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.relatedRequestId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> json, String docId) {
    DateTime date = DateTime.now();
    final rawDate = json['createdAt'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return AppNotification(
      id: docId,
      recipientId: json['recipientId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      relatedRequestId: json['relatedRequestId'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: date,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'relatedRequestId': relatedRequestId,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? message,
    String? relatedRequestId,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedRequestId: relatedRequestId ?? this.relatedRequestId,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
