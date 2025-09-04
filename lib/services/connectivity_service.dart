import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends GetxService {
  final RxBool isConnected = true.obs;
  final RxBool isCheckingConnection = false.obs;
  final Rx<DateTime> lastConnectedTime = DateTime.now().obs;

  Timer? _connectivityTimer;

  @override
  void onInit() {
    super.onInit();
    _startConnectivityCheck();
    _checkInitialConnection();
  }

  @override
  void onClose() {
    _connectivityTimer?.cancel();
    super.onClose();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkInitialConnection() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (isCheckingConnection.value) return;

    try {
      isCheckingConnection.value = true;

      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      final wasConnected = isConnected.value;
      final nowConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      isConnected.value = nowConnected;

      if (nowConnected) {
        lastConnectedTime.value = DateTime.now();
      }

      if (!wasConnected && nowConnected) {
        Get.snackbar(
          'Connection Restored',
          'Internet connection is back online',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.wifi, color: Colors.white),
        );
        print('Internet connection restored');
      } else if (wasConnected && !nowConnected) {
        Get.snackbar(
          'No Connection',
          'Internet connection lost - data will be queued',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.wifi_off, color: Colors.white),
        );
        print('Internet connection lost');
      }
    } catch (e) {
      final wasConnected = isConnected.value;
      isConnected.value = false;

      if (wasConnected) {
        print('Connection check failed: $e');
      }
    } finally {
      isCheckingConnection.value = false;
    }
  }

  Future<bool> testApiConnection() async {
    try {
      final result = await InternetAddress.lookup('api.helixtahr.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  String getConnectionStatusText() {
    if (isConnected.value) {
      return 'Connected';
    } else {
      final timeSinceLastConnection =
          DateTime.now().difference(lastConnectedTime.value);
      if (timeSinceLastConnection.inMinutes < 1) {
        return 'Disconnected (${timeSinceLastConnection.inSeconds}s ago)';
      } else if (timeSinceLastConnection.inHours < 1) {
        return 'Disconnected (${timeSinceLastConnection.inMinutes}m ago)';
      } else {
        return 'Disconnected (${timeSinceLastConnection.inHours}h ago)';
      }
    }
  }
}
