import 'location.dart';

class Ride {
  final String id;
  final String hostId;
  final String hostName;
  final double hostRating;
  final String hostPhone;
  final String hostAvatar;
  final Location fromLocation;
  final Location toLocation;
  final String date;
  final String time;
  final int availableSeats;
  final int totalSeats;
  final String note;
  final String matchStatus;

  const Ride({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostRating,
    required this.hostPhone,
    required this.hostAvatar,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    required this.time,
    required this.availableSeats,
    required this.totalSeats,
    required this.note,
    this.matchStatus = '100% Route Match',
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? '',
      hostRating: (json['hostRating'] as num?)?.toDouble() ?? 5.0,
      hostPhone: json['hostPhone'] as String? ?? '',
      hostAvatar: json['hostAvatar'] as String? ?? 'RM',
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
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 1,
      totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 4,
      note: json['note'] as String? ?? '',
      matchStatus: json['matchStatus'] as String? ?? '100% Route Match',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostRating': hostRating,
      'hostPhone': hostPhone,
      'hostAvatar': hostAvatar,
      'fromDivision': fromLocation.division,
      'fromCity': fromLocation.city,
      'fromArea': fromLocation.area,
      'toDivision': toLocation.division,
      'toCity': toLocation.city,
      'toArea': toLocation.area,
      'date': date,
      'time': time,
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'note': note,
      'matchStatus': matchStatus,
    };
  }

  Ride copyWith({
    String? id,
    String? hostId,
    String? hostName,
    double? hostRating,
    String? hostPhone,
    String? hostAvatar,
    Location? fromLocation,
    Location? toLocation,
    String? date,
    String? time,
    int? availableSeats,
    int? totalSeats,
    String? note,
    String? matchStatus,
  }) {
    return Ride(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostRating: hostRating ?? this.hostRating,
      hostPhone: hostPhone ?? this.hostPhone,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      date: date ?? this.date,
      time: time ?? this.time,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      note: note ?? this.note,
      matchStatus: matchStatus ?? this.matchStatus,
    );
  }
}
