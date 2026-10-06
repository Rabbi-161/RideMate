class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final int totalRides;
  final String avatarInitials;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.rating = 5.0,
    this.totalRides = 0,
    required this.avatarInitials,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return User(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      name: name,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: (json['totalRides'] as num?)?.toInt() ?? 0,
      avatarInitials: json['avatarInitials'] as String? ??
          (name.isNotEmpty
              ? name
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase()
              : 'U'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'rating': rating,
      'totalRides': totalRides,
      'avatarInitials': avatarInitials,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? rating,
    int? totalRides,
    String? avatarInitials,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      avatarInitials: avatarInitials ?? this.avatarInitials,
    );
  }
}
