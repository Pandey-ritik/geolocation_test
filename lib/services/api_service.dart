import 'dart:convert';
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geo_tracker_app/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../services/error_handler.dart';

class ApiService {
  static const String baseUrl = 'https://api.helixtahr.com/api/v1';
  static const String loginEndpoint = '$baseUrl/login';
  static const String locationEndpoint = '$baseUrl/location';
  static const Duration timeoutDuration = Duration(seconds: 15);
   static FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<UserModel?> login({
    required String email,
    required String password,
    required double latitude,
    required double longitude,
    required int browserId,
  }) async {
    try {
      print('Attempting login for: $email');
      print('Browser ID: $browserId');
      print('Location: $latitude, $longitude');

      final requestBody = {
        'email': email,
        'password': password,
        'lng': longitude,
        'lat': latitude,
        'browser_id': browserId,
      };

      print('Login request body: $requestBody');

      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(timeoutDuration);

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data['token']);
        
        // Handle different response structures
        if (data['success'] == true || data['status'] == 'success' || data['token'] != null) {
          final user = UserModel(
            userId: data['user_id'] ?? data['id'] ?? _extractUserIdFromEmail(email),
            email: email,
            token: data['data']['token'] ,
          );
          
          print('Login successful for user: ${user.userId}');
          return user;
        } else {
          print('Login failed: ${data['message'] ?? 'Invalid response format'}');
          return null;
        }
      } else {
        ErrorHandler.handleApiError(response.statusCode, response.body);
        return null;
      }
    } on TimeoutException {
      print('Login request timeout');
      ErrorHandler.handleApiError(408, 'Request timeout - please check your internet connection');
      return null;
    } catch (e) {
      print('Login error: $e');
      ErrorHandler.handleApiError(500, e.toString());
      return null;
    }
  }

  static Future<bool> sendLocationUpdate(LocationModel location) async {
    try {
      if (!location.isValid()) {
        print('Invalid location data, skipping update');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(token);

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final requestBody = location.toJson();
      print('Sending location update: $requestBody');

      final response = await http.post(
        Uri.parse(locationEndpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(timeoutDuration);

      print('Location update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Location update sent successfully at ${DateTime.now()}');
         _showLocationNotification(location);
       
        return true;
      } else {
        print('Location update failed: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 401) {
          print('Authentication token might be expired');
        }
        return false;
      }
    } on TimeoutException {
      print('Location update timeout');
      return false;
    } catch (e) {
      print('Location update error: $e');
      return false;
    }
  }

  static int _extractUserIdFromEmail(String email) {
    // Extract numeric part from email like NAV1003
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(email);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 2035;
    }
    return 2035; // Default user ID
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode < 500;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  static Future<void> _showLocationNotification(LocationModel location) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'location_channel',
    'Location Updates', 
    channelDescription: 'Shows location updates',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: AppColors.primary, 
  );

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, 
    'Location Updated',
    'Lat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}',
    platformDetails,
  );
}
}