import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final List<Location> _allLocations = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/locations.json');
      final List<dynamic> data = json.decode(jsonStr);
      _allLocations.clear();

      for (final div in data) {
        final divisionName = div['division'] as String? ?? '';
        final cities = div['cities'] as List<dynamic>? ?? [];
        for (final c in cities) {
          final cityName = c['name'] as String? ?? '';
          final areas = c['areas'] as List<dynamic>? ?? [];
          for (final area in areas) {
            _allLocations.add(Location(
              division: divisionName,
              city: cityName,
              area: area.toString(),
            ));
          }
        }
      }
    } catch (_) {
      // Fallback predefined Rajshahi City dataset
      const rajshahiAreas = [
        'Kazla',
        'Talaimari',
        'Binodpur',
        'Motihar',
        'Shaheb Bazar',
        'Laxmipur',
        'Vodra',
        'Railgate',
        'Shiroil',
        'New Market',
        'Bornali',
        'RUET (Rajshahi University of Engineering & Technology)',
        'RU (University of Rajshahi)',
      ];
      _allLocations.clear();
      for (final a in rajshahiAreas) {
        _allLocations.add(Location(
          division: 'Rajshahi',
          city: 'Rajshahi City',
          area: a,
        ));
      }
    }

    _isInitialized = true;
  }

  Future<List<Location>> getLocations() async {
    await initialize();
    return List.unmodifiable(_allLocations);
  }

  Future<List<Location>> searchLocations(String query) async {
    await initialize();
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return List.unmodifiable(_allLocations);
    }

    return _allLocations.where((loc) {
      return loc.area.toLowerCase().contains(trimmed) ||
          loc.city.toLowerCase().contains(trimmed) ||
          loc.division.toLowerCase().contains(trimmed);
    }).toList();
  }

  Location? findLocationByArea(String areaName) {
    try {
      return _allLocations.firstWhere(
        (loc) => loc.area.toLowerCase() == areaName.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
