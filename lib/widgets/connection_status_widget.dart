import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ConnectivityService connectivityService = Get.put(ConnectivityService());

    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: connectivityService.isConnected.value ? 0 : 40,
      child: connectivityService.isConnected.value
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: Colors.red,
              child: const Center(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
    ));
  }
}
