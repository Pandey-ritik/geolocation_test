class AppConstants {
  static const int locationUpdateIntervalSeconds = 30;
  static const int minimumDistanceFilter = 1; 
  static const int maxLocationHistoryCount = 100;
  
  static const double defaultGeofenceRadius = 100.0; 
  
  static const int apiTimeoutSeconds = 15;
  static const int maxRetryAttempts = 3;
  
  static const String backgroundServiceName = 'GeoTrackerService';
  static const String notificationChannelId = 'geo_tracker_channel';
  static const String notificationChannelName = 'Geo Tracker';
}