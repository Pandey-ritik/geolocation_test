import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../controllers/geofence_controller.dart';
import '../utils/app_colors.dart';

class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final LocationController locationController = Get.find<LocationController>();
    final GeofenceController geofenceController = Get.put(GeofenceController());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Obx(() => Icon(
                  Icons.circle,
                  color: locationController.isTracking.value 
                      ? AppColors.success 
                      : Colors.grey,
                  size: 12,
                )),
                const SizedBox(width: 8),
                Obx(() => Text(
                  locationController.isTracking.value 
                      ? 'Active Tracking' 
                      : 'Inactive',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: locationController.isTracking.value 
                        ? AppColors.success 
                        : Colors.grey,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: [
                Icon(
                  Icons.shield,
                  color: geofenceController.isInsideAnyGeofence.value 
                      ? AppColors.success 
                      : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    geofenceController.isInsideAnyGeofence.value
                        ? 'Inside: ${geofenceController.currentGeofenceName.value}'
                        : 'Outside all geofences',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 8),
            Obx(() => Text(
              'Total Updates: ${locationController.locationHistory.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
