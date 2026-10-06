import 'package:flutter/material.dart';
import '../models/ride_request.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/ride_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'ride_details_screen.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RideService _rideService = RideService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  // Requests sub-filter: 0 = Incoming, 1 = Sent
  int _requestsSubFilter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rideService.addListener(_onServiceChanged);
    _notificationService.addListener(_onServiceChanged);

    // If host has incoming requests, default to Incoming
    if (_rideService.incomingPendingCount > 0) {
      _requestsSubFilter = 0;
    } else {
      _requestsSubFilter = 1;
    }
  }

  @override
  void dispose() {
    _rideService.removeListener(_onServiceChanged);
    _notificationService.removeListener(_onServiceChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'upcoming':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'denied':
      case 'cancelled':
        return AppTheme.errorColor;
      case 'completed':
        return AppTheme.textSecondary;
      default:
        return AppTheme.primaryColor;
    }
  }

  Future<void> _acceptRequest(RideRequest req) async {
    try {
      final success = await _rideService.acceptRideRequest(req.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted ride request from ${req.requesterName}.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not accept request: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _denyRequest(RideRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deny Ride Request?'),
        content: Text(
          'Are you sure you want to deny ${req.requesterName}\'s request for ${req.seatsRequested} seat(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Deny'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _rideService.denyRideRequest(req.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Denied ride request from ${req.requesterName}.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not deny request: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelRequest(RideRequest req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride Request?'),
        content: Text(
          'Are you sure you want to cancel your request for ${req.ride.fromLocation.displayText} → ${req.ride.toLocation.displayText}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rideService.cancelRideRequest(req.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildIncomingRequestsList() {
    // Only pending incoming requests should appear as actionable pending for User B
    final incomingPending = _rideService.incomingRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();

    if (incomingPending.isEmpty) {
      return const EmptyStateWidget(
        title: 'No incoming requests',
        message: 'When passengers request to join your rides, they will appear here for you to Accept or Deny.',
        icon: Icons.inbox_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: incomingPending.length,
      itemBuilder: (context, index) {
        final item = incomingPending[index];
        final ride = item.ride;
        final statusColor = _getStatusColor(item.status);

        // Fetch requester's profile directly from Firestore users/{uid}
        return StreamBuilder<User?>(
          stream: _userService.getUserProfileStream(item.requesterId),
          builder: (context, userSnap) {
            final profile = userSnap.data;
            final requesterName = (profile?.name.trim().isNotEmpty == true)
                ? profile!.name.trim()
                : (item.requesterName.isNotEmpty ? item.requesterName : 'Passenger');
            final rawPhone = (profile?.phone.trim().isNotEmpty == true)
                ? profile!.phone.trim()
                : item.requesterPhone.trim();
            final requesterPhone = rawPhone.isNotEmpty && rawPhone != 'Phone number not available'
                ? rawPhone
                : 'Phone number not available';
            final avatar = (profile?.avatarInitials.isNotEmpty == true)
                ? profile!.avatarInitials
                : (requesterName.isNotEmpty ? requesterName[0].toUpperCase() : 'P');

            return Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Requester Profile Name + Phone + Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  avatar,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Requester Profile Name
                                    Text(
                                      requesterName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Requester Profile Phone Number
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            requesterPhone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: requesterPhone != 'Phone number not available'
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.textMuted,
                                              fontStyle: requesterPhone == 'Phone number not available'
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
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Route: From -> To
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.fromLocation.displayText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  ride.fromLocation.city,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  ride.toLocation.displayText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  ride.toLocation.city,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date, Time & Seats
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          ride.date,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          ride.time,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.seatsRequested} seat${item.seatsRequested > 1 ? "s" : ""}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppTheme.dividerColor),

                    // Host Action Buttons: Accept & Deny
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _denyRequest(item),
                          icon: const Icon(Icons.close_rounded, size: 15, color: AppTheme.errorColor),
                          label: const Text(
                            'Deny',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _acceptRequest(item),
                          icon: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                          label: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequestsList() {
    final outgoing = _rideService.outgoingRequests;

    if (outgoing.isEmpty) {
      return EmptyStateWidget(
        title: 'No sent requests',
        message: 'You haven\'t requested any rides yet. Search and join available rides on your route.',
        icon: Icons.send_rounded,
        buttonText: 'Find a Ride',
        onButtonPressed: () => HomeScreen.switchToTab(0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: outgoing.length,
      itemBuilder: (context, index) {
        final item = outgoing[index];
        final ride = item.ride;
        final statusColor = _getStatusColor(item.status);
        final isPending = item.status.toLowerCase() == 'pending';

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status Badge + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          ride.date,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Route: From -> To
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.fromLocation.displayText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              ride.fromLocation.city,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ride.toLocation.displayText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              ride.toLocation.city,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, color: AppTheme.dividerColor),

                // Host & Time & Seats Row
                StreamBuilder<User?>(
                  stream: _userService.getUserProfileStream(
                    item.hostId.isNotEmpty ? item.hostId : ride.hostId,
                  ),
                  builder: (context, hostSnap) {
                    final hostProfile = hostSnap.data;
                    final hostName = (hostProfile?.name.trim().isNotEmpty == true)
                        ? hostProfile!.name.trim()
                        : (ride.hostName.isNotEmpty ? ride.hostName : 'Ride Host');
                    final hostAvatar = (hostProfile?.avatarInitials.isNotEmpty == true)
                        ? hostProfile!.avatarInitials
                        : (ride.hostAvatar.isNotEmpty ? ride.hostAvatar : 'H');

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            hostAvatar,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hostName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.airline_seat_recline_normal_rounded,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.seatsRequested} seat${item.seatsRequested > 1 ? "s" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ride.time,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _cancelRequest(item),
                        icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.errorColor),
                        label: const Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final incomingCount = _rideService.incomingPendingCount;
    final outgoingCount = _rideService.outgoingRequests.length;

    return Column(
      children: [
        // Pill filter toggle: Incoming vs Sent
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _requestsSubFilter = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _requestsSubFilter == 0
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Incoming',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _requestsSubFilter == 0
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (incomingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _requestsSubFilter == 0
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$incomingCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _requestsSubFilter == 0
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _requestsSubFilter = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _requestsSubFilter == 1
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'My Sent Requests',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _requestsSubFilter == 1
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (outgoingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _requestsSubFilter == 1
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$outgoingCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _requestsSubFilter == 1
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List View based on sub-filter
        Expanded(
          child: _requestsSubFilter == 0
              ? _buildIncomingRequestsList()
              : _buildSentRequestsList(),
        ),
      ],
    );
  }

  Widget _buildListForFilter(
    List<String> statuses,
    String emptyTitle,
    String emptyMessage, {
    String? emptyActionText,
  }) {
    // Collect matching rides: accepted / upcoming / completed
    final list = _rideService.requests.where((req) {
      return statuses.contains(req.status.toLowerCase());
    }).toList();

    if (list.isEmpty) {
      return EmptyStateWidget(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.directions_car_outlined,
        buttonText: emptyActionText,
        onButtonPressed: emptyActionText != null
            ? () => HomeScreen.switchToTab(0)
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final ride = item.ride;
        final statusColor = _getStatusColor(item.status);
        final statusLower = item.status.toLowerCase();
        final bool isUpcoming = statusLower == 'upcoming' || statusLower == 'accepted';

        return Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideDetailsScreen(ride: ride),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ride.date,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Route: From -> To
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.fromLocation.displayText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                ride.fromLocation.city,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ride.toLocation.displayText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                ride.toLocation.city,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, color: AppTheme.dividerColor),

                  // Host & Time & Seats Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryLight,
                        child: Text(
                          ride.hostAvatar.isNotEmpty ? ride.hostAvatar : 'H',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ride.hostName.isNotEmpty ? ride.hostName : 'Host',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.airline_seat_recline_normal_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item.seatsRequested} seat${item.seatsRequested > 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        ride.time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  if (isUpcoming) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _rideService.completeRideRequest(item.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride marked as completed!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.done_all_rounded,
                              size: 14, color: AppTheme.primaryColor),
                          label: const Text(
                            'Mark Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = _notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Rides'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                if (unreadNotifs > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: [
            const Tab(text: 'Upcoming'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_rideService.incomingPendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_rideService.incomingPendingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming: upcoming and accepted
          _buildListForFilter(
            ['upcoming', 'accepted'],
            'No upcoming rides',
            'Search and request a ride from the Home tab.',
            emptyActionText: 'Search Rides',
          ),
          // Requests: incoming & sent
          _buildRequestsTab(),
          // Completed: completed
          _buildListForFilter(
            ['completed'],
            'No completed rides yet',
            'Past completed rides will be archived here.',
          ),
        ],
      ),
    );
  }
}
