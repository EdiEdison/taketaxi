import 'package:flutter/material.dart';
import 'package:taketaxi/core/constants/colors.dart';

class CustomRoundedButton extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final Color? textColor;

  const CustomRoundedButton({
    super.key,
    required this.text,
    this.backgroundColor,
    this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        backgroundColor: backgroundColor ?? AppColors.black,
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
