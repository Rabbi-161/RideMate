import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../firebase/firebase_constants.dart';

/// Client-side repository handling Cloud Firestore operations for the `users` collection.
///
/// Communicates directly with Cloud Firestore at `users/{uid}`.
class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(FirestoreCollections.users);

  /// Fetches a user document from `users/{uid}` with a timeout.
  Future<User?> getUserById(String uid, {Duration timeout = const Duration(seconds: 4)}) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    try {
      final doc = await _usersCol.doc(cleanUid).get().timeout(timeout);
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('UserRepository notice (getUserById for $cleanUid): $e');
    }
    return null;
  }

  /// Real-time stream of a user document from `users/{uid}`.
  Stream<User?> streamUser(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Stream.value(null);

    return _usersCol.doc(cleanUid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      return null;
    }).handleError((err) {
      debugPrint('UserRepository stream notice for $cleanUid: $err');
      return null;
    });
  }

  /// Sets or overwrites a user document at `users/{uid}`.
  Future<void> setUserDoc(String uid, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _usersCol.doc(uid).set(data).timeout(timeout);
  }

  /// Updates specific fields of a user document at `users/{uid}`.
  Future<void> updateUserDoc(String uid, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _usersCol.doc(uid).update(data).timeout(timeout);
  }
}
