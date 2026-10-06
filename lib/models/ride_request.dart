import 'package:cloud_firestore/cloud_firestore.dart';
import 'location.dart';
import 'ride.dart';

class RideRequest {
  final String id;
  final String rideId;
  final String hostId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String requesterPhone;
  final Ride ride;
  final String status; // 'Pending', 'Accepted', 'Denied', 'Upcoming', 'Completed', 'Cancelled'
  final DateTime requestedAt;
  final int seatsRequested;

  const RideRequest({
    required this.id,
    this.rideId = '',
    this.hostId = '',
    this.requesterId = '',
    this.requesterName = '',
    this.requesterEmail = '',
    this.requesterPhone = '',
    required this.ride,
    required this.status,
    required this.requestedAt,
    this.seatsRequested = 1,
  });

  // Backward-compatibility getters
  String get passengerName => requesterName.isNotEmpty ? requesterName : 'Passenger';
  String get passengerEmail => requesterEmail;

  factory RideRequest.fromFirestore(Map<String, dynamic> json, String docId) {
    DateTime date = DateTime.now();
    final rawDate = json['createdAt'] ?? json['requestedAt'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final reqName = json['requesterName'] as String? ??
        json['passengerName'] as String? ??
        'Passenger';
    final reqEmail = json['requesterEmail'] as String? ??
        json['passengerEmail'] as String? ??
        '';
    final reqPhone = json['requesterPhone'] as String? ?? '';
    final rId = json['rideId'] as String? ?? '';
    final hId = json['hostId'] as String? ?? '';

    // Build or extract nested Ride
    Ride rideObj;
    if (json['ride'] is Map<String, dynamic>) {
      rideObj = Ride.fromJson(json['ride'] as Map<String, dynamic>);
    } else {
      final hostName = json['hostName'] as String? ?? 'Host';
      rideObj = Ride(
        id: rId.isNotEmpty ? rId : docId,
        hostId: hId,
        hostName: hostName,
        hostRating: (json['hostRating'] as num?)?.toDouble() ?? 5.0,
        hostPhone: json['hostPhone'] as String? ?? '',
        hostAvatar: json['hostAvatar'] as String? ??
            (hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H'),
        fromLocation: Location(
          division: json['fromDivision'] as String? ?? '',
          city: json['fromCity'] as String? ?? '',
          area: json['fromArea'] as String? ?? '',
        ),
        toLocation: Location(
          division: json['toDivision'] as String? ?? '',
          city: json['toCity'] as String? ?? '',
          area: json['toArea'] as String? ?? '',
        ),
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        availableSeats: (json['seatsRequested'] as num?)?.toInt() ?? 1,
        totalSeats: 4,
        note: json['note'] as String? ?? '',
        matchStatus: '100% Route Match',
      );
    }

    return RideRequest(
      id: docId.isNotEmpty ? docId : (json['id'] as String? ?? ''),
      rideId: rId.isNotEmpty ? rId : rideObj.id,
      hostId: hId.isNotEmpty ? hId : rideObj.hostId,
      requesterId: json['requesterId'] as String? ?? '',
      requesterName: reqName,
      requesterEmail: reqEmail,
      requesterPhone: reqPhone,
      ride: rideObj,
      status: json['status'] as String? ?? 'Pending',
      requestedAt: date,
      seatsRequested: (json['seatsRequested'] as num?)?.toInt() ?? 1,
    );
  }

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest.fromFirestore(json, json['id'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId.isNotEmpty ? rideId : ride.id,
      'hostId': hostId.isNotEmpty ? hostId : ride.hostId,
      'hostName': ride.hostName,
      'hostPhone': ride.hostPhone,
      'hostAvatar': ride.hostAvatar,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requesterPhone': requesterPhone,
      'fromDivision': ride.fromLocation.division,
      'fromCity': ride.fromLocation.city,
      'fromArea': ride.fromLocation.area,
      'toDivision': ride.toLocation.division,
      'toCity': ride.toLocation.city,
      'toArea': ride.toLocation.area,
      'date': ride.date,
      'time': ride.time,
      'seatsRequested': seatsRequested,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  RideRequest copyWith({
    String? id,
    String? rideId,
    String? hostId,
    String? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? requesterPhone,
    Ride? ride,
    String? status,
    DateTime? requestedAt,
    int? seatsRequested,
  }) {
    return RideRequest(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      hostId: hostId ?? this.hostId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      ride: ride ?? this.ride,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      seatsRequested: seatsRequested ?? this.seatsRequested,
    );
  }
}
