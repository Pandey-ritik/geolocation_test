import 'package:flutter/material.dart';
import 'package:geo_tracker_app/screens/settings_screen.dart';
import 'package:geo_tracker_app/widgets/location_status.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/geofence_controller.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final LocationController locationController = Get.find<LocationController>();
    final GeofenceController geofenceController = Get.put(GeofenceController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Geo Tracker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              Get.offAll(() => const LoginScreen());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfoCard(authController),
            const SizedBox(height: 16),
            _buildLocationCard(locationController),
            const SizedBox(height: 16),
            const LocationStatusWidget(),
            const SizedBox(height: 16),
            _buildControlButtons(locationController),
            const SizedBox(height: 16),
            _buildLocationHistory(locationController),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(AuthController authController) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              'Email: ${authController.currentUser.value?.email ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            )),
            Obx(() => Text(
              'User ID: ${authController.currentUser.value?.userId ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(LocationController locationController) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                    'Lat: ${locationController.currentLatitude.value.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.transparent),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                    'Lng: ${locationController.currentLongitude.value.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: locationController.isTracking.value 
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                locationController.locationStatus.value,
                style: TextStyle(
                  fontSize: 12,
                  color: locationController.isTracking.value 
                      ? AppColors.success
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(LocationController locationController) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => locationController.getCurrentLocation(),
            icon: const Icon(Icons.my_location),
            label: const Text('Get Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton.icon(
            onPressed: () {
              if (locationController.isTracking.value) {
                locationController.stopLocationTracking();
              } else {
                locationController.startLocationTracking();
              }
            },
            icon: Icon(
              locationController.isTracking.value 
                  ? Icons.stop 
                  : Icons.play_arrow,
            ),
            label: Text(
              locationController.isTracking.value 
                  ? 'Stop Tracking' 
                  : 'Start Tracking',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: locationController.isTracking.value 
                  ? Colors.red 
                  : AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildLocationHistory(LocationController locationController) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Location History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (locationController.locationHistory.isEmpty) {
                  return const Center(
                    child: Text(
                      'No location data yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: locationController.locationHistory.length,
                  itemBuilder: (context, index) {
                    final location = locationController.locationHistory[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _formatDateTime(location.timestamp),
                        style: const TextStyle(fontSize: 10),
                      ),
                      dense: true,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
