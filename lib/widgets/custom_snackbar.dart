import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show(BuildContext context, String message, {Color backgroundColor = Colors.black87}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
  
  static void showInfo(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Colors.blue.shade700,
    );
  }

  static void showWarning(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Colors.amber.shade700,
    );
  }
}
