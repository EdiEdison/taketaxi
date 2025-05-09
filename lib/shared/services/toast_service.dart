import 'package:flutter/material.dart';
import 'dart:async';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

void showCustomToast(BuildContext context, String message, ToastType type) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder:
        (context) => Positioned(
          top: 80,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: CustomToast(message: message, type: type),
          ),
        ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), entry.remove);
}
