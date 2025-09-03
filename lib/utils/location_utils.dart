import 'dart:math';

class LocationUtils {
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radiusOfEarth = 6371;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = radiusOfEarth * c;

    return distance * 1000; 
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static bool isWithinGeofence(
    double currentLat,
    double currentLng,
    double geofenceLat,
    double geofenceLng,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      currentLat,
      currentLng,
      geofenceLat,
      geofenceLng,
    );
    return distance <= radiusInMeters;
  }
}