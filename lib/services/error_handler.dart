import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorHandler {
  static void handleApiError(int statusCode, String message) {
    String userMessage;
    Color backgroundColor;

    switch (statusCode) {
      case 401:
        userMessage = 'Authentication failed. Please login again.';
        backgroundColor = Colors.red;
        break;
      case 403:
        userMessage = 'Access denied. Check your permissions.';
        backgroundColor = Colors.red;
        break;
      case 404:
        userMessage = 'Service not found. Please try again later.';
        backgroundColor = Colors.orange;
        break;
      case 500:
        userMessage = 'Server error. Please try again later.';
        backgroundColor = Colors.red;
        break;
      default:
        userMessage = 'An error occurred: $message';
        backgroundColor = Colors.red;
    }

    Get.snackbar(
      'Error',
      userMessage,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void handleLocationError(String error) {
    Get.snackbar(
      'Location Error',
      error,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}