import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

void showCustomSnackbar(BuildContext context, String message, ToastType type) {
  final bgColor =
      type == ToastType.success
          ? Colors.green
          : type == ToastType.error
          ? Colors.red
          : type == ToastType.warning
          ? Colors.amberAccent
          : Colors.blueAccent;
  final icon =
      type == ToastType.success ? Icons.check_circle : Icons.error_outline;

  final snackBar = SnackBar(
    elevation: 0,
    backgroundColor: Colors.transparent,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(top: 30, left: 16, right: 16),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
