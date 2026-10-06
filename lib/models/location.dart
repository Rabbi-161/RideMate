class Location {
  final String division;
  final String city;
  final String area;

  const Location({
    required this.division,
    required this.city,
    required this.area,
  });

  String get displayText => area;

  String get fullHierarchy => '$division → $city → $area';

  String get id => '$division/$city/$area';

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      division: json['division'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'division': division,
      'city': city,
      'area': area,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          division.toLowerCase() == other.division.toLowerCase() &&
          city.toLowerCase() == other.city.toLowerCase() &&
          area.toLowerCase() == other.area.toLowerCase();

  @override
  int get hashCode =>
      division.toLowerCase().hashCode ^
      city.toLowerCase().hashCode ^
      area.toLowerCase().hashCode;

  @override
  String toString() => fullHierarchy;
}
