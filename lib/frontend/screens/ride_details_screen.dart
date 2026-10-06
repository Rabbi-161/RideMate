import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../models/user.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/ride_service.dart';
import '../../backend/services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final Ride ride;

  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  late Ride _currentRide;
  int _seatsToRequest = 1;
  bool _isRequesting = false;
  bool _isAlreadyRequested = false;

  @override
  void initState() {
    super.initState();
    _currentRide = widget.ride;
    _checkInitialStatus();
  }

  void _checkInitialStatus() {
    final requested = _rideService.isRideRequested(_currentRide.id);

    setState(() {
      _isAlreadyRequested = requested;
      // Clamp seats to available
      if (_currentRide.availableSeats > 0 && _seatsToRequest > _currentRide.availableSeats) {
        _seatsToRequest = _currentRide.availableSeats;
      }
    });
  }

  Future<void> _handleRequestToJoin() async {
    final currentUserId = _authService.currentUser?.id ?? '';
    if (_currentRide.hostId.isNotEmpty && _currentRide.hostId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot request to join your own ride.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isAlreadyRequested || _currentRide.availableSeats <= 0) return;

    setState(() => _isRequesting = true);

    try {
      final currentUser = _authService.currentUser;
      final passengerName = currentUser?.name ?? 'Passenger';
      final passengerEmail = currentUser?.email ?? '';

      await _rideService.sendRideRequest(
        ride: _currentRide,
        passengerName: passengerName,
        passengerEmail: passengerEmail,
        seatsRequested: _seatsToRequest,
      );

      // Refresh current ride object from service
      final updatedRide = await _rideService.getRideById(_currentRide.id);

      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _isAlreadyRequested = true;
        if (updatedRide != null) {
          _currentRide = updatedRide;
        }
      });

      _showRequestConfirmationDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRequestConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ride request sent successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your request for $_seatsToRequest seat(s) on ${_currentRide.fromLocation.displayText} → ${_currentRide.toLocation.displayText} (${_currentRide.time}, ${_currentRide.date}) has been sent to host ${_currentRide.hostName}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_done_rounded,
                      size: 14, color: AppTheme.successColor),
                  SizedBox(width: 6),
                  Text(
                    'Synced with Cloud Firestore (Pending Host Review)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx); // close dialog
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HomeScreen.switchToTab(1); // switch to My Rides tab
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'View in My Rides',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = _currentRide;
    final bool isFull = ride.availableSeats <= 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ride Details'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ride.hostId.isNotEmpty &&
                  ride.hostId == (_authService.currentUser?.id ?? '')) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.star_rounded, size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are the host of this ride.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const CustomButton(
                  text: 'You Are The Host',
                  icon: Icons.shield_rounded,
                  onPressed: null,
                ),
              ] else ...[
                if (_isAlreadyRequested)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'You have submitted a join request for this ride.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HomeScreen.switchToTab(1);
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'View Rides',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomButton(
                  text: _isAlreadyRequested
                      ? 'Request Sent'
                      : isFull
                          ? 'Ride Full'
                          : 'Request to Join',
                  icon: _isAlreadyRequested
                      ? Icons.check_circle_rounded
                      : isFull
                          ? Icons.block_rounded
                          : Icons.person_add_alt_1_rounded,
                  isLoading: _isRequesting,
                  onPressed: (_isAlreadyRequested || isFull)
                      ? null
                      : _handleRequestToJoin,
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host Information Card (Streamed from Firestore users/{hostId})
            StreamBuilder<User?>(
              stream: _userService.getUserProfileStream(ride.hostId),
              builder: (context, userSnap) {
                final profile = userSnap.data;
                final hostName = (profile?.name.trim().isNotEmpty == true)
                    ? profile!.name.trim()
                    : (ride.hostName.isNotEmpty ? ride.hostName : 'Ride Host');
                final rawPhone = (profile?.phone.trim().isNotEmpty == true)
                    ? profile!.phone.trim()
                    : ride.hostPhone.trim();
                final hostPhone = rawPhone.isNotEmpty && rawPhone != 'Phone number not available'
                    ? rawPhone
                    : 'Phone number not available';
                final hostAvatar = (profile?.avatarInitials.isNotEmpty == true)
                    ? profile!.avatarInitials
                    : (ride.hostAvatar.isNotEmpty
                        ? ride.hostAvatar
                        : (hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H'));

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryLight,
                        child: Text(
                          hostAvatar,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Host Profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hostName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    hostPhone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: hostPhone != 'Phone number not available'
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                      fontStyle: hostPhone == 'Phone number not available'
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Route Information Card (Full Hierarchy - PRD Section 22)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROUTE INFORMATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Departure
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trip_origin_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Departure Location',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.fromLocation.displayText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.fromLocation.fullHierarchy,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 14, top: 4, bottom: 4),
                    child: SizedBox(
                      height: 22,
                      child: VerticalDivider(
                        color: AppTheme.borderColor,
                        thickness: 1.5,
                      ),
                    ),
                  ),

                  // Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination Location',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.toLocation.displayText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.toLocation.fullHierarchy,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule & Seats Info (PRD Section 22)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: ride.date,
                  ),
                  const Divider(height: 20, color: AppTheme.dividerColor),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Departure Time',
                    value: ride.time,
                  ),
                  const Divider(height: 20, color: AppTheme.dividerColor),
                  _buildDetailRow(
                    icon: Icons.airline_seat_recline_normal_rounded,
                    label: 'Available Seats',
                    value: '${ride.availableSeats} of ${ride.totalSeats} seats',
                    valueColor: isFull ? AppTheme.errorColor : null,
                  ),
                  const Divider(height: 20, color: AppTheme.dividerColor),
                  _buildDetailRow(
                    icon: Icons.navigation_rounded,
                    label: 'Route Match',
                    value: ride.matchStatus,
                    valueColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seat Request Selector (If seats available and not yet requested)
            if (!_isAlreadyRequested && !isFull && ride.availableSeats > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seats to Request',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Max ${ride.availableSeats} available',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _seatsToRequest > 1
                              ? () => setState(() => _seatsToRequest--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: AppTheme.primaryColor,
                          visualDensity: VisualDensity.compact,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_seatsToRequest',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _seatsToRequest < ride.availableSeats
                              ? () => setState(() => _seatsToRequest++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: AppTheme.primaryColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Optional Note (PRD Section 22)
            if (ride.note.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OPTIONAL NOTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${ride.note}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
