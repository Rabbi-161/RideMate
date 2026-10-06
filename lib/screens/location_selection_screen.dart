import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final Location? currentLocation;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    this.currentLocation,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  List<Location> _allLocations = [];
  List<Location> _filteredLocations = [];
  List<String> _divisions = ['All'];
  String _selectedDivision = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    final list = await _locationService.getLocations();
    if (!mounted) return;

    final uniqueDivisions = <String>{'All'};
    for (final loc in list) {
      if (loc.division.isNotEmpty) {
        uniqueDivisions.add(loc.division);
      }
    }

    setState(() {
      _allLocations = list;
      _divisions = uniqueDivisions.toList();
      _filteredLocations = list;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLocations = _allLocations.where((loc) {
        final matchesDivision = _selectedDivision == 'All' ||
            loc.division.toLowerCase() == _selectedDivision.toLowerCase();

        if (!matchesDivision) return false;

        if (query.isEmpty) return true;

        return loc.area.toLowerCase().contains(query) ||
            loc.city.toLowerCase().contains(query) ||
            loc.division.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onDivisionSelected(String division) {
    setState(() {
      _selectedDivision = division;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    // Group locations by division and city for PRD Section 11 & 13 hierarchy display
    final Map<String, Map<String, List<Location>>> grouped = {};
    for (final loc in _filteredLocations) {
      grouped.putIfAbsent(loc.division, () => {});
      grouped[loc.division]!.putIfAbsent(loc.city, () => []);
      grouped[loc.division]![loc.city]!.add(loc);
    }

    // Popular demo areas for quick 1-tap selection
    const popularDemoAreas = [
      'Kazla',
      'Shaheb Bazar',
      'Talaimari',
      'Binodpur',
      'Laxmipur',
      'Railgate',
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Search box & Filters container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Division Filter Chips
                if (_divisions.length > 2) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _divisions.map((div) {
                        final isSelected = _selectedDivision == div;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(div),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                            selectedColor: AppTheme.primaryColor,
                            backgroundColor: AppTheme.backgroundColor,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) => _onDivisionSelected(div),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Quick Popular Area Chips (Shown when search query is empty)
                if (_searchController.text.isEmpty) ...[
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, size: 14, color: AppTheme.accentColor),
                      SizedBox(width: 4),
                      Text(
                        'QUICK SELECT POPULAR AREAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: popularDemoAreas.map((areaName) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            label: Text(
                              areaName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            onPressed: () {
                              final matched = _locationService.findLocationByArea(areaName);
                              if (matched != null) {
                                Navigator.pop(context, matched);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

          // Hierarchy list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredLocations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 36,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No locations match "${_searchController.text}"',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try searching for an area like Kazla, Talaimari, or Shaheb Bazar.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  _onDivisionSelected('All');
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset Search'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(140, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, divIndex) {
                          final divisionName = grouped.keys.elementAt(divIndex);
                          final citiesMap = grouped[divisionName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Division header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_city_rounded,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      divisionName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Cities
                              ...citiesMap.keys.map((cityName) {
                                final areas = citiesMap[cityName]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // City subheader
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(40, 8, 16, 4),
                                      child: Text(
                                        cityName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),

                                    // Areas
                                    ...areas.map((loc) {
                                      final isSelected = widget.currentLocation != null &&
                                          widget.currentLocation == loc;

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 3,
                                        ),
                                        child: Material(
                                          color: isSelected
                                              ? AppTheme.primaryLight
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () {
                                              Navigator.pop(context, loc);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppTheme.primaryColor
                                                      : AppTheme.borderColor,
                                                  width: isSelected ? 1.5 : 1.0,
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected
                                                        ? Icons.check_circle_rounded
                                                        : Icons.radio_button_unchecked_rounded,
                                                    color: isSelected
                                                        ? AppTheme.primaryColor
                                                        : AppTheme.textMuted,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          loc.area,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isSelected
                                                                ? FontWeight.w700
                                                                : FontWeight.w500,
                                                            color: isSelected
                                                                ? AppTheme.primaryColor
                                                                : AppTheme.textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          loc.fullHierarchy,
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
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
