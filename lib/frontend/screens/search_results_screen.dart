import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../models/ride.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/matching_service.dart';
import '../../backend/services/ride_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/ride_card.dart';
import 'ride_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final Location from;
  final Location to;
  final String date;
  final String time;

  const SearchResultsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final MatchingService _matchingService = MatchingService();
  final RideService _rideService = RideService();
  final AuthService _authService = AuthService();

  List<Ride> _matchingRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    final results = await _matchingService.searchRides(
      from: widget.from,
      to: widget.to,
      date: widget.date,
      time: widget.time,
    );

    if (!mounted) return;
    setState(() {
      _matchingRides = results;
      _isLoading = false;
    });
  }

  void _showCreateRideModal() {
    final user = _authService.currentUser;
    final hostName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Ride Host';
    final hostPhone = (user?.phone != null && user!.phone.trim().isNotEmpty)
        ? user.phone.trim()
        : 'Phone number not available';
    final hostAvatar = user?.avatarInitials ?? 'RH';

    int seats = 3;
    final noteController = TextEditingController(
      text: 'Heading towards ${widget.to.displayText} from ${widget.from.displayText}. Join me!',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_road_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Create a Ride (Prototype)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Post a mock ride on this route so you and other students can test ride matching.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Divider(height: 24, color: AppTheme.dividerColor),

                    // Pre-filled route preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin_rounded,
                                  size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                widget.from.displayText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: AppTheme.textMuted),
                              ),
                              Text(
                                widget.to.displayText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                widget.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                widget.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seats selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Seats',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: seats > 1
                                  ? () => setModalState(() => seats--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: AppTheme.primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$seats',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: seats < 6
                                  ? () => setModalState(() => seats++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: AppTheme.primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Optional Note
                    const Text(
                      'Trip Note (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Leaving punctually at the campus gate.',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    CustomButton(
                      text: 'Publish Ride',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () async {
                        final newRide = Ride(
                          id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
                          hostId: user?.id ?? 'u_new',
                          hostName: hostName,
                          hostRating: 5.0,
                          hostPhone: hostPhone,
                          hostAvatar: hostAvatar,
                          fromLocation: widget.from,
                          toLocation: widget.to,
                          date: widget.date,
                          time: widget.time,
                          availableSeats: seats,
                          totalSeats: seats + 1,
                          note: noteController.text.trim(),
                          matchStatus: '100% Route Match',
                        );

                        await _rideService.addRide(newRide);
                        if (!modalCtx.mounted) return;
                        Navigator.pop(modalCtx);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ride created and published successfully!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        _performSearch();
                      },
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

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _authService.currentUser?.email;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Available RideMates'),
      ),
      body: Column(
        children: [
          // Route & Search query banner (PRD Section 20)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.from.displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
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
                    Text(
                      widget.to.displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading && _matchingRides.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_matchingRides.length} found',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _matchingRides.isEmpty
                    ? EmptyStateWidget(
                        title: 'No RideMate found for this route yet.',
                        message: 'Try another date, time, or route.',
                        buttonText: 'Create a Ride',
                        onButtonPressed: _showCreateRideModal,
                      )
                    : RefreshIndicator(
                        onRefresh: _performSearch,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _matchingRides.length,
                          itemBuilder: (context, index) {
                            final ride = _matchingRides[index];
                            final isRequested = _rideService.isRideRequested(
                              ride.id,
                              passengerEmail: currentUserEmail,
                            );

                            return RideCard(
                              ride: ride,
                              isRequested: isRequested,
                              onViewRide: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RideDetailsScreen(ride: ride),
                                  ),
                                );
                                if (mounted) {
                                  _performSearch();
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
