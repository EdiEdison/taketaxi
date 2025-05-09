import 'package:flutter/material.dart';

enum ToastType { success, error }

class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;

  const CustomToast({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final bgColor = type == ToastType.success ? Colors.green : Colors.red;
    final icon =
        type == ToastType.success ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
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
    );
  }
}
