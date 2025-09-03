import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geo_tracker_app/utils/app_colors.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import '../services/api_service.dart';
import '../services/background_service.dart';
import '../services/storage_service.dart';
import '../services/error_handler.dart';
import '../utils/app_constants.dart';
import 'auth_controller.dart';

class LocationController extends GetxController {
  final RxDouble currentLatitude = 0.0.obs;
  final RxDouble currentLongitude = 0.0.obs;
  final RxBool isTracking = false.obs;
  final RxString locationStatus = 'Not tracking'.obs;
  final RxList<LocationModel> locationHistory = <LocationModel>[].obs;
  final RxInt totalLocationUpdates = 0.obs;
  final RxDouble accuracy = 0.0.obs;
  final Rx<DateTime> lastUpdateTime= DateTime.now().obs;


  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LocationModel> _pendingUpdates = [];

  @override
  void onInit() {
    super.onInit();
    _loadLocationHistory();
    _checkLocationPermissions();
    _initLocalNotifications() ;
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

   void _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: (response) {
      print("User tapped on notification: ${response.payload}");
    });
  }



  Future<void> _loadLocationHistory() async {
    try {
      final history = await StorageService.getLocationHistory();
      locationHistory.assignAll(history);
      totalLocationUpdates.value = history.length;
      print('Loaded ${history.length} location records from storage');
    } catch (e) {
      print('Error loading location history: $e');
    }
  }

  Future<void> _checkLocationPermissions() async {
    final locationPermission = await Permission.location.status;
    final locationAlwaysPermission = await Permission.locationAlways.status;
    
    if (!locationPermission.isGranted || !locationAlwaysPermission.isGranted) {
      await _requestLocationPermissions();
    }
  }

  Future<bool> _requestLocationPermissions() async {
    final permissions = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ].request();

    final allGranted = permissions.values.every(
      (status) => status == PermissionStatus.granted,
    );

    if (!allGranted) {
      ErrorHandler.handleLocationError(
        'Location permissions are required for this app to work properly.'
      );
    }

    return allGranted;
  }

  Future<void> getCurrentLocation() async {
    try {
      locationStatus.value = 'Getting location...';
      
      final hasPermission = await _checkLocationService();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
      accuracy.value = position.accuracy;
      lastUpdateTime.value = DateTime.now();
      locationStatus.value = 'Location updated successfully';

      print('Current location: ${position.latitude}, ${position.longitude}');

      await _sendLocationUpdate(position);
    } catch (e) {
      locationStatus.value = 'Error getting location';
      ErrorHandler.handleLocationError('Failed to get current location: $e');
      print('Error getting current location: $e');
    }
  }

  Future<void> startLocationTracking() async {
    try {
      final hasPermission = await _checkLocationService();
      if (!hasPermission) return;

      isTracking.value = true;
      locationStatus.value = 'Starting location tracking...';

      await BackgroundLocationService.startService();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.minimumDistanceFilter,
        // timeLimit: Duration(seconds: 10),
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handleLocationUpdate(position);
        },
        onError: (error) {
          locationStatus.value = 'Tracking error occurred';
          ErrorHandler.handleLocationError('Location tracking error: $error');
          print('Location stream error: $error');
        },
      );

      locationStatus.value = 'Location tracking active';
      
      Get.snackbar(
        'Tracking Started',
        'Location tracking is now active in foreground and background',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.gps_fixed, color: Colors.white),
      );
    } catch (e) {
      isTracking.value = false;
      locationStatus.value = 'Failed to start tracking';
      ErrorHandler.handleLocationError('Failed to start location tracking: $e');
      print('Error starting location tracking: $e');
    }
  }

  Future<void> stopLocationTracking() async {
    try {
      isTracking.value = false;
      locationStatus.value = 'Stopping location tracking...';

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      await BackgroundLocationService.stopService();

      await StorageService.saveLocationHistory(locationHistory);

      locationStatus.value = 'Location tracking stopped';
      
      Get.snackbar(
        'Tracking Stopped',
        'Location tracking has been stopped',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.location_off, color: Colors.white),
      );
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  void _handleLocationUpdate(Position position) {
    currentLatitude.value = position.latitude;
    currentLongitude.value = position.longitude;
    accuracy.value = position.accuracy;
    lastUpdateTime.value = DateTime.now();
    
    print('Location updated: ${position.latitude}, ${position.longitude} (Accuracy: ${position.accuracy}m)');
    
    _sendLocationUpdate(position);
  }

  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ErrorHandler.handleLocationError('Please enable location services in your device settings');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ErrorHandler.handleLocationError('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ErrorHandler.handleLocationError('Location permissions are permanently denied. Please enable them in settings.');
      return false;
    }

    return true;
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      final AuthController authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.userId ?? 0;

      if (userId == 0) {
        print('No user ID found, skipping location update');
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
        locationHistory.insert(0, location);
        totalLocationUpdates.value++;
        
        if (locationHistory.length > AppConstants.maxLocationHistoryCount) {
          locationHistory.removeRange(
            AppConstants.maxLocationHistoryCount, 
            locationHistory.length
          );
        }
        
        if (totalLocationUpdates.value % 10 == 0) {
          await StorageService.saveLocationHistory(locationHistory);
        }

        print('Location update sent successfully. Total updates: ${totalLocationUpdates.value}');
      } else {
        _pendingUpdates.add(location);
        _retryPendingUpdates();
        print('Location update failed, added to retry queue');
      }
    } catch (e) {
      print('Error sending location update: $e');
    }
  }

  Future<void> _retryPendingUpdates() async {
    if (_pendingUpdates.isEmpty) return;
    
    print('Retrying ${_pendingUpdates.length} pending location updates');
    
    final List<LocationModel> successfulUpdates = [];
    
    for (final location in _pendingUpdates) {
      final success = await ApiService.sendLocationUpdate(location);
      if (success) {
        successfulUpdates.add(location);
        totalLocationUpdates.value++;
      }
    }
    
    for (final update in successfulUpdates) {
      _pendingUpdates.remove(update);
    }

    if (successfulUpdates.isNotEmpty) {
      print('Successfully sent ${successfulUpdates.length} pending updates');
    }
  }

  void clearLocationHistory() {
    locationHistory.clear();
    totalLocationUpdates.value = 0;
    StorageService.saveLocationHistory([]);
  }
}