import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Service responsible for fetching and streaming user identity profiles
/// directly from Firestore `users/{uid}` collection.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, User> _cache = {};

  /// Retrieves a user's Firestore profile from `users/{uid}`.
  /// If found, returns the User object. Caches in memory to minimize network calls.
  Future<User?> getUserProfile(String uid, {bool forceRefresh = false}) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    if (!forceRefresh && _cache.containsKey(cleanUid)) {
      return _cache[cleanUid];
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(cleanUid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final user = User.fromJson(doc.data()!);
        _cache[cleanUid] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Notice: Error fetching Firestore profile for $cleanUid: $e');
    }

    return null;
  }

  /// Real-time stream of a user's Firestore profile from `users/{uid}`.
  Stream<User?> getUserProfileStream(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(cleanUid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final user = User.fromJson(doc.data()!);
        _cache[cleanUid] = user;
        return user;
      }
      return null;
    }).handleError((err) {
      debugPrint('Notice: Firestore user stream notice for $cleanUid: $err');
      return null;
    });
  }

  void updateCache(User user) {
    if (user.id.isNotEmpty) {
      _cache[user.id] = user;
    }
  }

  void clearCache([String? uid]) {
    if (uid != null) {
      _cache.remove(uid);
    } else {
      _cache.clear();
    }
  }
}
