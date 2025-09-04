import 'package:geo_tracker_app/utils/app_colors.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../utils/location_utils.dart';
import 'location_controller.dart';

class GeofenceController extends GetxController {
  final RxList<GeofenceZone> geofences = <GeofenceZone>[].obs;
  final RxBool isInsideAnyGeofence = false.obs;
  final RxString currentGeofenceName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupDefaultGeofences();
    _startGeofenceMonitoring();
  }

  void _setupDefaultGeofences() {
    geofences.addAll([
      GeofenceZone(
        id: '1',
        name: 'Office Zone',
        latitude: 1.3565952,
        longitude: 103.809024,
        radius: 100, 
      ),
      GeofenceZone(
        id: '2',
        name: 'Home Zone',
        latitude: 1.3521,
        longitude: 103.8198,
        radius: 50, 
      ),
    ]);
  }

  void _startGeofenceMonitoring() {
    final LocationController locationController = Get.find<LocationController>();
    
    ever(locationController.currentLatitude, (_) => _checkGeofences());
    ever(locationController.currentLongitude, (_) => _checkGeofences());
  }

  void _checkGeofences() {
    final LocationController locationController = Get.find<LocationController>();
    final currentLat = locationController.currentLatitude.value;
    final currentLng = locationController.currentLongitude.value;

    if (currentLat == 0.0 || currentLng == 0.0) return;

    bool insideAnyFence = false;
    String currentZoneName = '';

    for (final geofence in geofences) {
      final isInside = LocationUtils.isWithinGeofence(
        currentLat,
        currentLng,
        geofence.latitude,
        geofence.longitude,
        geofence.radius,
      );

      if (isInside) {
        insideAnyFence = true;
        currentZoneName = geofence.name;
        
        if (!isInsideAnyGeofence.value) {
          _onGeofenceEnter(geofence);
        }
        break;
      }
    }

    if (!insideAnyFence && isInsideAnyGeofence.value) {
      _onGeofenceExit();
    }

    isInsideAnyGeofence.value = insideAnyFence;
    currentGeofenceName.value = currentZoneName;
  }

  void _onGeofenceEnter(GeofenceZone geofence) {
    Get.snackbar(
      'Geofence Entry',
      'You entered: ${geofence.name}',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    print('Entered geofence: ${geofence.name}');
  }

  void _onGeofenceExit() {
    Get.snackbar(
      'Geofence Exit',
      'You left the geofenced area',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    print('Exited geofence');
  }

  void addGeofence(GeofenceZone geofence) {
    geofences.add(geofence);
  }

  void removeGeofence(String id) {
    geofences.removeWhere((geofence) => geofence.id == id);
  }
}

class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; 

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}