import 'dart:async';
import '../../models/user.dart';
import '../repositories/user_repository.dart';

/// Service responsible for fetching, streaming, and caching user profiles
/// directly from Firestore `users/{uid}` via [UserRepository].
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final UserRepository _userRepo = UserRepository();
  final Map<String, User> _cache = {};

  /// Retrieves a user's Firestore profile from `users/{uid}`.
  /// If found, returns the User object. Caches in memory to minimize network calls.
  Future<User?> getUserProfile(String uid, {bool forceRefresh = false}) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return null;

    if (!forceRefresh && _cache.containsKey(cleanUid)) {
      return _cache[cleanUid];
    }

    final user = await _userRepo.getUserById(cleanUid);
    if (user != null) {
      _cache[cleanUid] = user;
      return user;
    }

    return null;
  }

  /// Real-time stream of a user's Firestore profile from `users/{uid}`.
  Stream<User?> getUserProfileStream(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Stream.value(null);

    return _userRepo.streamUser(cleanUid).map((user) {
      if (user != null) {
        _cache[cleanUid] = user;
      }
      return user;
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
