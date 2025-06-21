import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';

class EnterCodeScreen extends StatefulWidget {
  final String? phoneNumber;

  const EnterCodeScreen({super.key, this.phoneNumber});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  String code = "";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              }
            },
          ),
          title: Text(
            'Verification',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  "Enter the 6-digit code we sent to ${widget.phoneNumber ?? '+237 677 123 456'}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 32),
                PinCodeTextField(
                  keyboardType: TextInputType.number,
                  appContext: context,
                  length: 4,
                  obscureText: false,
                  autoFocus: true,
                  animationType: AnimationType.fade,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 60,
                    fieldWidth: 60,
                    activeFillColor: Colors.grey[200],
                    inactiveFillColor: Colors.grey[200],
                    selectedFillColor: Colors.grey[200],
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.transparent,
                    selectedColor: AppColors.primary,
                    fieldOuterPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                  ),
                  enableActiveFill: true,
                  onChanged: (value) {
                    setState(() {
                      code = value;
                    });
                  },
                  onCompleted: (value) {
                    setState(() {
                      code = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      // resend code logic here
                    },
                    child: Text(
                      "Resend code",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                SizedBox(
                  width: double.infinity,
                  child: CustomRoundedButton(
                    text: 'Continue',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      context.go('/complete_profile');
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
