import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/ride_service.dart';
import '../theme/app_theme.dart';
import '../widgets/search_card.dart';
import 'location_selection_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'rides_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);

  static void switchToTab(int index) {
    tabNotifier.value = index;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Location? _fromLocation;
  Location? _toLocation;
  DateTime _travelDate = DateTime(2026, 10, 10);
  TimeOfDay _departureTime = const TimeOfDay(hour: 17, minute: 30);
  int _seats = 1;

  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final RideService _rideService = RideService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _currentIndex = HomeScreen.tabNotifier.value;
    HomeScreen.tabNotifier.addListener(_onTabNotifierChanged);
    _authService.addListener(_onAuthChanged);
    _notificationService.latestNotification.addListener(_onNewNotification);
    _initDefaults();
  }

  void _onNewNotification() {
    final notif = _notificationService.latestNotification.value;
    if (notif == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              notif.type == 'ride_accepted'
                  ? Icons.check_circle_rounded
                  : (notif.type == 'ride_denied'
                      ? Icons.cancel_rounded
                      : Icons.notifications_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    notif.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            HomeScreen.switchToTab(1); // My Rides
          },
        ),
        backgroundColor: notif.type == 'ride_accepted'
            ? AppTheme.successColor
            : (notif.type == 'ride_denied'
                ? AppTheme.errorColor
                : AppTheme.primaryColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onTabNotifierChanged() {
    if (mounted && _currentIndex != HomeScreen.tabNotifier.value) {
      setState(() {
        _currentIndex = HomeScreen.tabNotifier.value;
      });
    }
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    HomeScreen.tabNotifier.removeListener(_onTabNotifierChanged);
    _authService.removeListener(_onAuthChanged);
    _notificationService.latestNotification.removeListener(_onNewNotification);
    super.dispose();
  }

  Future<void> _initDefaults() async {
    await _locationService.initialize();
    if (!mounted) return;
    setState(() {
      _fromLocation = _locationService.findLocationByArea('Kazla');
      _toLocation = _locationService.findLocationByArea('Shaheb Bazar');
    });
  }

  Future<void> _selectFromLocation() async {
    final selected = await Navigator.push<Location>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          title: 'Select Departure',
          currentLocation: _fromLocation,
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _fromLocation = selected;
      });
    }
  }

  Future<void> _selectToLocation() async {
    final selected = await Navigator.push<Location>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          title: 'Select Destination',
          currentLocation: _toLocation,
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _toLocation = selected;
      });
    }
  }

  void _swapLocations() {
    if (_fromLocation == null && _toLocation == null) return;
    setState(() {
      final temp = _fromLocation;
      _fromLocation = _toLocation;
      _toLocation = temp;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Swapped departure and destination locations.'),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFromLocation() {
    setState(() {
      _fromLocation = null;
    });
  }

  void _clearToLocation() {
    setState(() {
      _toLocation = null;
    });
  }

  void _onSearch(Location from, Location to, String date, String time, int seats) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          from: from,
          to: to,
          date: date,
          time: time,
        ),
      ),
    );
  }

  Future<void> _onRequestRide(Location from, Location to, String date, String time, int seats) async {
    try {
      await _rideService.createRideRequest(
        from: from,
        to: to,
        date: date,
        time: time,
        seats: seats,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
              SizedBox(width: 8),
              Text('Ride Requested'),
            ],
          ),
          content: Text(
            'Your ride request for ${from.displayText} → ${to.displayText} ($seats ${seats == 1 ? "seat" : "seats"}) has been saved to Firebase!\n\nOther users searching this route can now find and match with your request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                HomeScreen.switchToTab(1); // Switch to Rides tab
              },
              child: const Text('View in My Rides'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post ride request: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.commute_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'RideMate',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: ListenableBuilder(
                              listenable: _notificationService,
                              builder: (context, _) {
                                final unread = _notificationService.unreadCount;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    if (unread > 0)
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.errorColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            tooltip: 'Notifications',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _authService.currentUser != null
                                      ? 'Hi, ${_authService.currentUser!.name.split(" ").first}'
                                      : 'RideMate User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find people travelling your way.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Section containing exactly:
          // 1. From
          // 2. To
          // 3. Date
          // 4. Time
          // 5. Number of Seats
          // 6. Search Ride
          // 7. Request Ride
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchCard(
              initialFrom: _fromLocation,
              initialTo: _toLocation,
              initialDate: _travelDate,
              initialTime: _departureTime,
              initialSeats: _seats,
              onSelectFrom: _selectFromLocation,
              onSelectTo: _selectToLocation,
              onClearFrom: _clearFromLocation,
              onClearTo: _clearToLocation,
              onSwapLocations: _swapLocations,
              onDateChanged: (d) => setState(() => _travelDate = d),
              onTimeChanged: (t) => setState(() => _departureTime = t),
              onSeatsChanged: (s) => setState(() => _seats = s),
              onSearch: _onSearch,
              onRequestRide: _onRequestRide,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardTab(),
      const RidesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HomeScreen.tabNotifier.value = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car_rounded),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
