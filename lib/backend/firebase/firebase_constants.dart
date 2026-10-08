/// Centralized Cloud Firestore collection names and integration constants for RideMate.
///
/// NOTE: These constants are used by the client-side Firebase repositories and services
/// to interact with Google Cloud Firestore collections.
class FirestoreCollections {
  /// Collection storing user profiles (keyed by Firebase Auth UID).
  static const String users = 'users';

  /// Collection storing hosted ride listings.
  static const String rides = 'rides';

  /// Collection storing ride join and route requests.
  static const String rideRequests = 'ride_requests';

  /// Collection storing real-time in-app user notifications.
  static const String notifications = 'notifications';
}
