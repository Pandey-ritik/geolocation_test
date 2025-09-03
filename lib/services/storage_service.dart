import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';

class StorageService {
  static const String userKey = 'current_user';
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String emailKey = 'email';
  static const String locationHistoryKey = 'location_history';
  static const String backgroundUpdatesKey = 'background_updates';
  static const String lastLocationUpdateKey = 'last_location_update';

  static Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, jsonEncode(user.toJson()));
      await prefs.setString(authTokenKey, user.token);
      await prefs.setString(userIdKey, user.userId.toString());
      await prefs.setString(emailKey, user.email);
      
      print('User data saved successfully: ${user.email}');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(userKey);
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        final user = UserModel.fromJson(userData);
        print('User data loaded from storage: ${user.email}');
        return user;
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userKey);
      await prefs.remove(authTokenKey);
      await prefs.remove(userIdKey);
      await prefs.remove(emailKey);
      
      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  static Future<void> saveLocationHistory(List<LocationModel> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = locations.map((loc) => {
        'user_id': loc.userId,
        'lat': loc.latitude,
        'lng': loc.longitude,
        'timestamp': loc.timestamp.millisecondsSinceEpoch,
      }).toList();
      
      await prefs.setString(locationHistoryKey, jsonEncode(locationsJson));
      print('Saved ${locations.length} location records to storage');
    } catch (e) {
      print('Error saving location history: $e');
    }
  }

  static Future<List<LocationModel>> getLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(locationHistoryKey);
      
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> locationsList = jsonDecode(historyJson);
        final locations = locationsList.map((json) {
          return LocationModel(
            userId: json['user_id'] ?? 0,
            latitude: (json['lat'] ?? 0.0).toDouble(),
            longitude: (json['lng'] ?? 0.0).toDouble(),
            timestamp: json['timestamp'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
                : DateTime.now(),
          );
        }).toList();
        
        print('Loaded ${locations.length} location records from storage');
        return locations;
      }
    } catch (e) {
      print('Error getting location history: $e');
    }
    return [];
  }

  static Future<void> saveLastLocationUpdate(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastLocationUpdateKey, timestamp.toIso8601String());
    } catch (e) {
      print('Error saving last location update: $e');
    }
  }

  static Future<DateTime?> getLastLocationUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(lastLocationUpdateKey);
      
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
    } catch (e) {
      print('Error getting last location update: $e');
    }
    return null;
  }

  static Future<int> getBackgroundUpdateCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(backgroundUpdatesKey) ?? 0;
    } catch (e) {
      print('Error getting background update count: $e');
      return 0;
    }
  }

  static Future<void> incrementBackgroundUpdateCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(backgroundUpdatesKey) ?? 0;
      await prefs.setInt(backgroundUpdatesKey, currentCount + 1);
    } catch (e) {
      print('Error incrementing background update count: $e');
    }
  }
}