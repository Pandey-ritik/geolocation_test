import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../controllers/geofence_controller.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LocationController locationController = Get.find<LocationController>();
    final GeofenceController geofenceController = Get.find<GeofenceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: const Text('Auto Start Tracking'),
                    subtitle: const Text('Start tracking when app opens'),
                    trailing: Switch(
                      value: true, 
                      onChanged: (value) {
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer, color: AppColors.primary),
                    title: const Text('Update Interval'),
                    subtitle: const Text('Every 30 seconds'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Clear Location History'),
                    subtitle: const Text('Remove all stored location data'),
                    onTap: () {
                      _showClearHistoryDialog(context, locationController);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Geofence Zones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: geofenceController.geofences.length,
                itemBuilder: (context, index) {
                  final geofence = geofenceController.geofences[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_city, color: AppColors.primary),
                      title: Text(geofence.name),
                      subtitle: Text(
                        'Radius: ${geofence.radius}m\n'
                        'Lat: ${geofence.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${geofence.longitude.toStringAsFixed(6)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          geofenceController.removeGeofence(geofence.id);
                        },
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGeofenceDialog(context, geofenceController),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, LocationController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all location history?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.locationHistory.clear();
              Get.back();
              Get.snackbar(
                'Success',
                'Location history cleared',
                backgroundColor: AppColors.success,
                colorText: Colors.white,
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAddGeofenceDialog(BuildContext context, GeofenceController controller) {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Geofence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Zone Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lngController.text.isNotEmpty &&
                  radiusController.text.isNotEmpty) {
                
                final geofence = GeofenceZone(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  latitude: double.parse(latController.text),
                  longitude: double.parse(lngController.text),
                  radius: double.parse(radiusController.text),
                );

                controller.addGeofence(geofence);
                Get.back();
                
                Get.snackbar(
                  'Success',
                  'Geofence added successfully',
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}