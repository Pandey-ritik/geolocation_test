import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/location_model.dart';
import '../utils/app_constants.dart';

class BackgroundLocationService {
  static const String channelId = 'location_tracking_channel';
  static const String channelName = 'Location Tracking';
  static const int notificationId = 123;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'This channel is used for location tracking notifications.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: 'Geo Tracker Active',
        initialNotificationContent: 'Tracking your location in the background',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    print('Background service initialized successfully');
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    print('iOS background service started');
    return true;
  }

  static void onStart(ServiceInstance service) async {
    print('Background service started');

    Timer.periodic(
        Duration(seconds: AppConstants.locationUpdateIntervalSeconds),
        (timer) async {
      try {
        final position = await _getCurrentPosition();
        if (position != null) {
          await _sendLocationToServer(position);

          // Update notification with current location
          service.invoke(
            'setAsForeground',
            {
              "title": "Geo Tracker Active",
              "content":
                  "Last update: ${DateTime.now().toString().split(' ')[1].split('.')[0]}\n"
                      "Lat: ${position.latitude.toStringAsFixed(4)}, "
                      "Lng: ${position.longitude.toStringAsFixed(4)}",
            },
          );
        }
      } catch (e) {
        print('Background location error: $e');
        service.invoke(
          'setAsForeground',
          {
            "title": "Geo Tracker - Error",
            "content": "Location tracking encountered an error",
          },
        );
      }
    });

    service.on('stopService').listen((event) {
      print('Stopping background service');
      service.stopSelf();
    });

    service.on('updateInterval').listen((event) {
      final newInterval =
          event?['interval'] ?? AppConstants.locationUpdateIntervalSeconds;
      print('Updated background service interval to: ${newInterval}s');
    });
  }

  static Future<Position?> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied in background service');
        return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service disabled');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
          'Background location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting position in background: $e');
      return null;
    }
  }

  static Future<void> _sendLocationToServer(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('user_id');

      if (userIdString == null) {
        print('No user ID found in background service');
        return;
      }

      final userId = int.tryParse(userIdString) ?? 0;

      if (userId == 0) {
        print('Invalid user ID in background service');
        return;
      }

      final location = LocationModel(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      final success = await ApiService.sendLocationUpdate(location);

      if (success) {
        print('Background location update sent successfully');
        // Store successful update count
        final updateCount = prefs.getInt('background_updates') ?? 0;
        await prefs.setInt('background_updates', updateCount + 1);
      } else {
        print('Background location update failed');
      }
    } catch (e) {
      print('Error sending location to server from background: $e');
    }
  }

  static Future<void> startService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        print('Background service started successfully');
      } else {
        print('Background service is already running');
      }
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  static Future<void> stopService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      print('Background service stop signal sent');
    } catch (e) {
      print('Error stopping background service: $e');
    }
  }

  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      print('Error checking service status: $e');
      return false;
    }
  }
}
