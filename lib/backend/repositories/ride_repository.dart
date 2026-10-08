import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/ride.dart';
import '../../models/ride_request.dart';
import '../firebase/firebase_constants.dart';

/// Client-side repository handling Cloud Firestore operations for
/// `rides` and `ride_requests` collections.
class RideRepository {
  static final RideRepository _instance = RideRepository._internal();
  factory RideRepository() => _instance;
  RideRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ridesCol =>
      _firestore.collection(FirestoreCollections.rides);

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection(FirestoreCollections.rideRequests);

  /// Generates a new auto-generated document ID for `ride_requests`.
  String newRequestId() => _requestsCol.doc().id;

  /// Generates a new auto-generated document ID for `rides`.
  String newRideId() => _ridesCol.doc().id;

  /// Fetches a single ride by its document ID.
  Future<Ride?> getRideById(String id, {Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final doc = await _ridesCol.doc(id).get().timeout(timeout);
      if (doc.exists && doc.data() != null) {
        return Ride.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('RideRepository notice (getRideById): $e');
    }
    return null;
  }

  /// Writes a ride document to Firestore.
  Future<void> saveRide(String id, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _ridesCol.doc(id).set(data).timeout(timeout);
  }

  /// Queries the `rides` collection matching the route and date.
  Future<QuerySnapshot<Map<String, dynamic>>> queryRides({
    required String fromArea,
    required String toArea,
    required String date,
    Duration timeout = const Duration(seconds: 4),
  }) {
    return _ridesCol
        .where('fromArea', isEqualTo: fromArea)
        .where('toArea', isEqualTo: toArea)
        .where('date', isEqualTo: date)
        .get()
        .timeout(timeout);
  }

  /// Queries open ride requests matching the route and date.
  Future<QuerySnapshot<Map<String, dynamic>>> queryRideRequests({
    required String fromArea,
    required String toArea,
    required String date,
    Duration timeout = const Duration(seconds: 4),
  }) {
    return _requestsCol
        .where('fromArea', isEqualTo: fromArea)
        .where('toArea', isEqualTo: toArea)
        .where('date', isEqualTo: date)
        .get()
        .timeout(timeout);
  }

  /// Creates a ride request document.
  Future<void> saveRideRequest(String id, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _requestsCol.doc(id).set(data).timeout(timeout);
  }

  /// Real-time stream of outgoing ride requests where requesterId == currentUserId.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamOutgoingRequests(String currentUserId) {
    return _requestsCol
        .where('requesterId', isEqualTo: currentUserId)
        .snapshots();
  }

  /// Real-time stream of incoming ride requests where hostId == currentUserId.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamIncomingRequests(String currentUserId) {
    return _requestsCol
        .where('hostId', isEqualTo: currentUserId)
        .snapshots();
  }

  /// Loads outgoing requests once for current user.
  Future<List<RideRequest>> fetchOutgoingRequests(String currentUserId,
      {Duration timeout = const Duration(seconds: 4)}) async {
    final snap = await _requestsCol
        .where('requesterId', isEqualTo: currentUserId)
        .get()
        .timeout(timeout);
    return snap.docs
        .map((doc) => RideRequest.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Loads incoming requests once for current user.
  Future<List<RideRequest>> fetchIncomingRequests(String currentUserId,
      {Duration timeout = const Duration(seconds: 4)}) async {
    final snap = await _requestsCol
        .where('hostId', isEqualTo: currentUserId)
        .get()
        .timeout(timeout);
    return snap.docs
        .map((doc) => RideRequest.fromFirestore(doc.data(), doc.id))
        .where((r) => r.requesterId != currentUserId)
        .toList();
  }

  /// Fetches a single ride request by document ID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getRequestDoc(String requestId,
      {Duration timeout = const Duration(seconds: 4)}) {
    return _requestsCol.doc(requestId).get().timeout(timeout);
  }

  /// Updates fields of a ride request document.
  Future<void> updateRequest(String requestId, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 4)}) async {
    await _requestsCol.doc(requestId).update(data).timeout(timeout);
  }
}
