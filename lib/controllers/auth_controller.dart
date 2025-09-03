import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/error_handler.dart';
import 'location_controller.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final user = await StorageService.getUser();
      if (user != null && user.token.isNotEmpty) {
        currentUser.value = user;
        isLoggedIn.value = true;
        print('User found in storage: ${user.email}');
      } else {
        print('No valid user found in storage');
      }
    } catch (e) {
      print('Error checking login status: $e');
      isLoggedIn.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      
      final LocationController locationController = Get.find<LocationController>();
      await locationController.getCurrentLocation();
      
      final currentLat = locationController.currentLatitude.value;
      final currentLng = locationController.currentLongitude.value;
      
      final lat = currentLat != 0.0 ? currentLat : 1.3565952;
      final lng = currentLng != 0.0 ? currentLng : 103.809024;
      
      final browserId = _generateBrowserId();
      
      final user = await ApiService.login(
        email: email,
        password: password,
        latitude: lat,
        longitude: lng,
        browserId: browserId,
      );

      if (user != null && user.token.isNotEmpty) {
        await StorageService.saveUser(user);
        currentUser.value = user;
        isLoggedIn.value = true;
        
        await Future.delayed(const Duration(seconds: 1));
        locationController.startLocationTracking();
        
        Get.snackbar(
          'Success',
          'Welcome back! Location tracking started.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        return true;
      } else {
        ErrorHandler.handleApiError(401, 'Invalid credentials or server response');
        return false;
      }
    } catch (e) {
      ErrorHandler.handleApiError(500, e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      final LocationController locationController = Get.find<LocationController>();
      await locationController.stopLocationTracking();
      
      await StorageService.clearUserData();
      
      currentUser.value = null;
      isLoggedIn.value = false;
      
      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.logout, color: Colors.white),
      );
    } catch (e) {
      print('Logout error: $e');
      ErrorHandler.handleApiError(500, 'Error during logout');
    }
  }

  int _generateBrowserId() {
    final random = Random();
    return random.nextInt(999999999) + 1000000000;
  }
}