import '../../models/location.dart';
import '../../models/ride.dart';
import 'ride_service.dart';

class MatchingService {
  final RideService _rideService;

  MatchingService({RideService? rideService})
      : _rideService = rideService ?? RideService();

  Future<List<Ride>> searchRides({
    required Location from,
    required Location to,
    required String date,
    required String time,
  }) async {
    return _rideService.searchMatchingRides(
      from: from,
      to: to,
      date: date,
      time: time,
    );
  }
}
