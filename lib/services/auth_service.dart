import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || (_isInitialized && _auth.currentUser != null);

  /// Ensures Firebase core is initialized before attempting any auth or database calls
  Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase initialization notice in AuthService: $e');
      }
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _ensureInitialized();

      final currentFbUser = _auth.currentUser;
      if (currentFbUser != null) {
        await _fetchUserProfile(currentFbUser.uid);
      }

      // Listen for Firebase auth state changes
      _auth.authStateChanges().listen((fb.User? user) async {
        if (user != null) {
          await _fetchUserProfile(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
      _isInitialized = true;
    } catch (e) {
      debugPrint('AuthService initialization notice: $e');
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    // 1. Try to load user profile from Firestore with timeout
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentUser = User.fromJson(data);
        UserService().updateCache(_currentUser!);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Notice: could not load user profile from Firestore ($e). Falling back to Auth profile.');
    }

    // 2. Fallback: populate user profile from Firebase Auth user data
    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null && fbUser.uid == uid) {
        final displayName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : (fbUser.email?.isNotEmpty == true ? fbUser.email!.split('@').first : 'User');
        final initials = _getInitials(displayName);
        final fallbackUser = User(
          id: uid,
          name: displayName,
          email: fbUser.email ?? '',
          phone: '',
          rating: 5.0,
          totalRides: 0,
          avatarInitials: initials,
        );

        _currentUser = fallbackUser;
        UserService().updateCache(fallbackUser);
        notifyListeners();

        // Best-effort attempt to save document into Firestore without blocking
        _firestore.collection('users').doc(uid).set({
          'id': uid,
          'name': displayName,
          'email': fbUser.email ?? '',
          'phone': '',
          'rating': 5.0,
          'totalRides': 0,
          'avatarInitials': initials,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4)).catchError((err) {
          debugPrint('Notice: Firestore background write skipped: $err');
          return null;
        });
      }
    } catch (e) {
      debugPrint('Error creating fallback user profile: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    await _ensureInitialized();
    await initialize();
    return _auth.currentUser != null;
  }

  Future<User?> login(String email, String password) async {
    await _ensureInitialized();

    final userCred = await _auth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Login timed out. Please check your network connection.'),
        );

    final fbUser = userCred.user;
    if (fbUser != null) {
      await _fetchUserProfile(fbUser.uid);
      if (_currentUser == null) {
        final displayName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
            ? fbUser.displayName!.trim()
            : (fbUser.email?.isNotEmpty == true ? fbUser.email!.split('@').first : 'User');
        _currentUser = User(
          id: fbUser.uid,
          name: displayName,
          email: fbUser.email ?? email.trim(),
          phone: '',
          rating: 5.0,
          totalRides: 0,
          avatarInitials: _getInitials(displayName),
        );
      }
    }

    notifyListeners();
    return _currentUser;
  }

  Future<User?> signUp(String name, String email, String password, [String phone = '']) async {
    await _ensureInitialized();

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPhone = phone.trim();

    // 1. Create account in Firebase Authentication
    final userCred = await _auth
        .createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: password,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Firebase authentication timed out. Please check your network connection.',
          ),
        );

    final fbUser = userCred.user;
    if (fbUser != null) {
      final uid = fbUser.uid;

      // Update displayName in Firebase Auth
      try {
        await fbUser.updateDisplayName(trimmedName).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Notice: updateDisplayName notice: $e');
      }

      final initials = _getInitials(trimmedName.isNotEmpty ? trimmedName : 'User');
      final newUser = User(
        id: uid,
        name: trimmedName.isNotEmpty ? trimmedName : 'User',
        email: trimmedEmail,
        phone: trimmedPhone,
        rating: 5.0,
        totalRides: 0,
        avatarInitials: initials,
      );

      // Set current user immediately so authenticated session is ready
      _currentUser = newUser;
      UserService().updateCache(newUser);
      notifyListeners();

      // Best-effort Firestore write with timeout so uncreated/disabled Firestore never blocks signup
      try {
        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'name': trimmedName,
          'email': trimmedEmail,
          'phone': trimmedPhone,
          'rating': 5.0,
          'totalRides': 0,
          'avatarInitials': initials,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Notice: Firestore user profile sync notice: $e');
      }

      return _currentUser;
    }

    return null;
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    final updated = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      phone: phone ?? _currentUser!.phone,
    );

    if (name != null && name.trim().isNotEmpty) {
      try {
        await _auth.currentUser?.updateDisplayName(name.trim()).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Notice: updateDisplayName notice: $e');
      }
    }

    _currentUser = updated;
    UserService().updateCache(updated);
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name.trim();
      if (phone != null) data['phone'] = phone.trim();
      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(data).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Notice: Error updating profile in Firestore ($e).');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _currentUser = null;
    notifyListeners();
  }

  Future<User?> getUserProfile(String uid, {bool forceRefresh = false}) =>
      UserService().getUserProfile(uid, forceRefresh: forceRefresh);

  Stream<User?> getUserProfileStream(String uid) =>
      UserService().getUserProfileStream(uid);

  static String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

