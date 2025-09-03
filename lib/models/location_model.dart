class LocationModel {
  final int userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationModel({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'lat': latitude,
      'lng': longitude,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      userId: json['user_id'] ?? 0,
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocationModel(userId: $userId, lat: $latitude, lng: $longitude, time: $timestamp)';
  }

  bool isValid() {
    return latitude != 0.0 && longitude != 0.0 && userId > 0;
  }
}