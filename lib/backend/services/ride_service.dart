import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/location.dart';
import '../../models/ride.dart';
import '../../models/ride_request.dart';
import '../../models/user.dart';
import '../repositories/ride_repository.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

class RideService extends ChangeNotifier {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final RideRepository _rideRepo = RideRepository();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  final List<Ride> _rides = [];
  List<RideRequest> _outgoingRequests = [];
  List<RideRequest> _incomingRequests = [];
  List<RideRequest> _allRequests = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inSub;

  bool _isInitialized = false;

  List<Ride> get rides => List.unmodifiable(_rides);
  List<RideRequest> get requests => List.unmodifiable(_allRequests);
  List<RideRequest> get outgoingRequests => List.unmodifiable(_outgoingRequests);
  List<RideRequest> get incomingRequests => List.unmodifiable(_incomingRequests);

  int get incomingPendingCount => _incomingRequests
      .where((r) => r.status.toLowerCase() == 'pending')
      .length;

  Future<Ride?> getRideById(String id) async {
    final ride = await _rideRepo.getRideById(id);
    if (ride != null) return ride;
    return _rides.cast<Ride?>().firstWhere((r) => r?.id == id, orElse: () => null);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _startStreams();
    _authService.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _startStreams();
  }

  void _startStreams() {
    _outSub?.cancel();
    _inSub?.cancel();

    final currentUserId = _authService.currentUser?.id ?? '';
    if (currentUserId.isEmpty) {
      _outgoingRequests = [];
      _incomingRequests = [];
      _allRequests = [];
      notifyListeners();
      return;
    }

    try {
      // 1. Stream outgoing requests where current user is requester
      _outSub = _rideRepo
          .streamOutgoingRequests(currentUserId)
          .listen((snap) {
        _outgoingRequests = snap.docs.map((doc) {
          return RideRequest.fromFirestore(doc.data(), doc.id);
        }).toList();
        _outgoingRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        _updateCombinedRequests();
      }, onError: (err) {
        debugPrint('RideService outgoing stream notice: $err');
      });

      // 2. Stream incoming requests where current user is the ride host
      _inSub = _rideRepo
          .streamIncomingRequests(currentUserId)
          .listen((snap) {
        // Exclude self-requests if any
        _incomingRequests = snap.docs
            .map((doc) => RideRequest.fromFirestore(doc.data(), doc.id))
            .where((req) => req.requesterId != currentUserId)
            .toList();
        _incomingRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        _updateCombinedRequests();
      }, onError: (err) {
        debugPrint('RideService incoming stream notice: $err');
      });
    } catch (e) {
      debugPrint('Error starting ride request streams: $e');
    }
  }

  void _updateCombinedRequests() {
    final Map<String, RideRequest> map = {};
    for (final r in _outgoingRequests) {
      map[r.id] = r;
    }
    for (final r in _incomingRequests) {
      map[r.id] = r;
    }
    _allRequests = map.values.toList();
    _allRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    notifyListeners();
  }

  // Save a general Ride Request into Cloud Firestore (route post)
  Future<String> createRideRequest({
    required Location from,
    required Location to,
    required String date,
    required String time,
    required int seats,
  }) async {
    final user = _authService.currentUser;
    final docId = _rideRepo.newRequestId();

    final data = {
      'id': docId,
      'requesterId': user?.id ?? '',
      'requesterName': user?.name ?? 'Passenger',
      'requesterEmail': user?.email ?? '',
      'requesterPhone': user?.phone ?? '',
      'hostId': '', // Open route post
      'hostName': '',
      'hostPhone': '',
      'hostAvatar': '',
      'fromDivision': from.division,
      'fromCity': from.city,
      'fromArea': from.area,
      'toDivision': to.division,
      'toCity': to.city,
      'toArea': to.area,
      'date': date,
      'time': time,
      'seatsRequested': seats,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _rideRepo.saveRideRequest(docId, data);
    } catch (e) {
      debugPrint('Notice: Error saving ride request to Firestore: $e');
    }
    await loadUserRequests();
    notifyListeners();
    return docId;
  }

  // Retrieve matching rides and ride requests from Cloud Firestore
  Future<List<Ride>> searchMatchingRides({
    required Location from,
    required Location to,
    required String date,
    required String time,
  }) async {
    final currentUserId = _authService.currentUser?.id ?? '';
    final List<Ride> results = [];

    try {
      // 1. Query rides collection in Firestore with timeout
      final ridesSnap = await _rideRepo.queryRides(
        fromArea: from.area,
        toArea: to.area,
        date: date,
      );

      for (final doc in ridesSnap.docs) {
        final data = doc.data();
        final hostId = data['hostId'] as String? ?? '';
        // Exclude current user's own rides from search results
        if (hostId != currentUserId) {
          final ride = Ride.fromJson(data);
          // Retrieve host profile directly from Firestore users/{hostId}
          User? hostProfile;
          if (hostId.isNotEmpty) {
            hostProfile = await _userService.getUserProfile(hostId);
          }
          final resolvedName = (hostProfile?.name.trim().isNotEmpty == true)
              ? hostProfile!.name.trim()
              : (ride.hostName.isNotEmpty ? ride.hostName : 'Ride Host');
          final rawPhone = hostProfile?.phone.trim() ?? '';
          final resolvedPhone = rawPhone.isNotEmpty
              ? rawPhone
              : 'Phone number not available';
          final resolvedAvatar = (hostProfile?.avatarInitials.isNotEmpty == true)
              ? hostProfile!.avatarInitials
              : _getInitials(resolvedName);

          results.add(ride.copyWith(
            hostName: resolvedName,
            hostPhone: resolvedPhone,
            hostAvatar: resolvedAvatar,
          ));
        }
      }

      // 2. Query ride_requests collection in Firestore from other users with timeout
      final reqsSnap = await _rideRepo.queryRideRequests(
        fromArea: from.area,
        toArea: to.area,
        date: date,
      );

      for (final doc in reqsSnap.docs) {
        final data = doc.data();
        final reqUserId = data['requesterId'] as String? ?? '';
        final status = (data['status'] as String? ?? '').toLowerCase();

        // Exclude current user's own requests and non-active requests
        if (reqUserId != currentUserId &&
            status != 'cancelled' &&
            status != 'completed') {
          // Retrieve requester profile directly from Firestore users/{reqUserId}
          User? reqProfile;
          if (reqUserId.isNotEmpty) {
            reqProfile = await _userService.getUserProfile(reqUserId);
          }
          final resolvedName = (reqProfile?.name.trim().isNotEmpty == true)
              ? reqProfile!.name.trim()
              : (data['requesterName'] as String? ?? 'Co-traveler');
          final rawPhone = reqProfile?.phone.trim() ?? '';
          final resolvedPhone = rawPhone.isNotEmpty
              ? rawPhone
              : 'Phone number not available';
          final resolvedAvatar = (reqProfile?.avatarInitials.isNotEmpty == true)
              ? reqProfile!.avatarInitials
              : _getInitials(resolvedName);

          results.add(
            Ride(
              id: data['id'] ?? doc.id,
              hostId: reqUserId,
              hostName: resolvedName,
              hostRating: 5.0,
              hostPhone: resolvedPhone,
              hostAvatar: resolvedAvatar,
              fromLocation: Location(
                division: data['fromDivision'] ?? '',
                city: data['fromCity'] ?? '',
                area: data['fromArea'] ?? '',
              ),
              toLocation: Location(
                division: data['toDivision'] ?? '',
                city: data['toCity'] ?? '',
                area: data['toArea'] ?? '',
              ),
              date: data['date'] ?? date,
              time: data['time'] ?? time,
              availableSeats: (data['seatsRequested'] as num?)?.toInt() ?? 1,
              totalSeats: 4,
              note: 'Ride request posted by fellow commuter.',
              matchStatus: '100% Route Match',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching rides in Firestore: $e');
    }

    return results;
  }

  // Load current user's requests from Firestore manually if needed
  Future<List<RideRequest>> loadUserRequests() async {
    final currentUserId = _authService.currentUser?.id ?? '';
    if (currentUserId.isEmpty) {
      _outgoingRequests = [];
      _incomingRequests = [];
      _allRequests = [];
      return [];
    }

    try {
      _outgoingRequests = await _rideRepo.fetchOutgoingRequests(currentUserId);
      _outgoingRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

      _incomingRequests = await _rideRepo.fetchIncomingRequests(currentUserId);
      _incomingRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

      _updateCombinedRequests();
    } catch (e) {
      debugPrint('Error loading user requests from Firestore: $e');
    }

    return _allRequests;
  }

  Future<List<RideRequest>> getRequests() async {
    await loadUserRequests();
    return List.unmodifiable(_allRequests);
  }

  Future<List<RideRequest>> getRequestsByStatus(String status) async {
    await loadUserRequests();
    return _allRequests
        .where((r) => r.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  bool isRideRequested(String rideId, {String? passengerEmail}) {
    final currentUserId = _authService.currentUser?.id ?? '';
    return _outgoingRequests.any((r) =>
        r.ride.id == rideId &&
        (currentUserId.isEmpty || r.requesterId == currentUserId) &&
        (r.status.toLowerCase() == 'pending' || r.status.toLowerCase() == 'accepted'));
  }

  // Create a join ride request in Cloud Firestore
  Future<bool> sendRideRequest({
    required Ride ride,
    required String passengerName,
    required String passengerEmail,
    int seatsRequested = 1,
  }) async {
    final user = _authService.currentUser;
    final currentUserId = user?.id ?? '';

    if (currentUserId.isEmpty) {
      throw Exception('You must be logged in to request a ride.');
    }

    // 1. Prevent requesting own ride
    if (ride.hostId.isNotEmpty && ride.hostId == currentUserId) {
      throw Exception('You cannot request to join your own ride.');
    }

    // 2. Prevent duplicate active requests
    final isAlreadyRequested = _outgoingRequests.any((r) =>
        r.ride.id == ride.id &&
        (r.status.toLowerCase() == 'pending' || r.status.toLowerCase() == 'accepted'));
    if (isAlreadyRequested) {
      throw Exception('You already have an active request for this ride.');
    }

    final docId = _rideRepo.newRequestId();

    try {
      final data = {
        'id': docId,
        'rideId': ride.id,
        'hostId': ride.hostId,
        'hostName': ride.hostName,
        'hostPhone': ride.hostPhone,
        'hostAvatar': ride.hostAvatar,
        'requesterId': currentUserId,
        'requesterName': passengerName,
        'requesterEmail': passengerEmail,
        'requesterPhone': user?.phone ?? '',
        'fromDivision': ride.fromLocation.division,
        'fromCity': ride.fromLocation.city,
        'fromArea': ride.fromLocation.area,
        'toDivision': ride.toLocation.division,
        'toCity': ride.toLocation.city,
        'toArea': ride.toLocation.area,
        'date': ride.date,
        'time': ride.time,
        'seatsRequested': seatsRequested,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _rideRepo.saveRideRequest(docId, data);

      // Notify the ride host if hostId is present
      if (ride.hostId.isNotEmpty && ride.hostId != currentUserId) {
        await _notificationService.createNotification(
          recipientId: ride.hostId,
          title: 'New Ride Request',
          message:
              '$passengerName requested $seatsRequested seat(s) for your ride from ${ride.fromLocation.area} to ${ride.toLocation.area}.',
          relatedRequestId: docId,
          type: 'ride_request',
        );
      }

      await loadUserRequests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending ride request to Firestore: $e');
      rethrow;
    }
  }

  // User B accepts incoming ride request from User A
  Future<bool> acceptRideRequest(String requestId) async {
    final currentUserId = _authService.currentUser?.id ?? '';

    try {
      final snap = await _rideRepo.getRequestDoc(requestId);

      if (!snap.exists) return false;
      final data = snap.data()!;
      final requesterId = data['requesterId'] as String? ?? '';
      final hostId = data['hostId'] as String? ?? '';

      // Verify caller is the host
      if (hostId.isNotEmpty && hostId != currentUserId) {
        throw Exception('Only the ride host can accept this request.');
      }

      // Prevent a user from accepting their own request
      if (requesterId.isNotEmpty && requesterId == currentUserId) {
        throw Exception('You cannot accept your own ride request.');
      }

      // Update status to 'Accepted'
      await _rideRepo.updateRequest(requestId, {
        'status': 'Accepted',
      });

      // User A receives notification: "Your ride request has been accepted."
      if (requesterId.isNotEmpty) {
        await _notificationService.createNotification(
          recipientId: requesterId,
          title: 'Ride Request Accepted',
          message: 'Your ride request has been accepted.',
          relatedRequestId: requestId,
          type: 'ride_accepted',
        );
      }

      await loadUserRequests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error accepting request in Firestore: $e');
      rethrow;
    }
  }

  // User B denies incoming ride request from User A
  Future<bool> denyRideRequest(String requestId) async {
    final currentUserId = _authService.currentUser?.id ?? '';

    try {
      final snap = await _rideRepo.getRequestDoc(requestId);

      if (!snap.exists) return false;
      final data = snap.data()!;
      final requesterId = data['requesterId'] as String? ?? '';
      final hostId = data['hostId'] as String? ?? '';

      // Verify caller is the host
      if (hostId.isNotEmpty && hostId != currentUserId) {
        throw Exception('Only the ride host can deny this request.');
      }

      // Prevent a user from denying their own request
      if (requesterId.isNotEmpty && requesterId == currentUserId) {
        throw Exception('You cannot deny your own ride request.');
      }

      // Update status to 'Denied'
      await _rideRepo.updateRequest(requestId, {
        'status': 'Denied',
      });

      // User A receives notification: "Your ride request was denied."
      if (requesterId.isNotEmpty) {
        await _notificationService.createNotification(
          recipientId: requesterId,
          title: 'Ride Request Denied',
          message: 'Your ride request was denied.',
          relatedRequestId: requestId,
          type: 'ride_denied',
        );
      }

      await loadUserRequests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error denying request in Firestore: $e');
      rethrow;
    }
  }

  // User A cancels their outgoing request
  Future<bool> cancelRideRequest(String requestId) async {
    try {
      await _rideRepo.updateRequest(requestId, {
        'status': 'Cancelled',
      });
      await loadUserRequests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error cancelling request in Firestore: $e');
      return false;
    }
  }

  Future<bool> completeRideRequest(String requestId) async {
    try {
      await _rideRepo.updateRequest(requestId, {
        'status': 'Completed',
      });
      await loadUserRequests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing request in Firestore: $e');
      return false;
    }
  }

  Future<void> addRide(Ride ride) async {
    try {
      final docId = ride.id.isEmpty ? _rideRepo.newRideId() : ride.id;
      final data = ride.toJson();
      data['id'] = docId;
      data['createdAt'] = FieldValue.serverTimestamp();
      await _rideRepo.saveRide(docId, data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding ride to Firestore: $e');
    }
  }

  static String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  void dispose() {
    _outSub?.cancel();
    _inSub?.cancel();
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
