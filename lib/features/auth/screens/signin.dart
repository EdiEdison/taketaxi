import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  String? phoneNumber;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void checkField() {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      // Navigate to OTP screen or handle next step
      context.push('/verifyphone', extra: phoneNumber);
      showCustomSnackbar(context, "Code sent successfully", ToastType.success);
    } else {
      showCustomSnackbar(
        context,
        "Please Enter your phone number",
        ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,

          title: Text(
            'Enter your phone number',
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
                  "We'll send you a text with a verification code.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  "Message and data rates may apply.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 32),
                IntlPhoneField(
                  showDropdownIcon: true,
                  dropdownIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black54,
                  ),
                  dropdownTextStyle: const TextStyle(color: AppColors.black),
                  style: const TextStyle(color: AppColors.black),
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  initialCountryCode: 'CM',
                  onChanged: (phone) {
                    setState(() {
                      phoneNumber = phone.completeNumber;
                    });
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomRoundedButton(
                    text: 'Next',
                    backgroundColor:
                        phoneNumber != null && phoneNumber!.isNotEmpty
                            ? AppColors.primary
                            : AppColors.buttonDisabled,
                    onPressed: () {
                      checkField();
                    },
                  ),
                ),
                const SizedBox(
                  height: 400,
                ), // Adjusted space to push consent text to bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        children: const [
                          TextSpan(text: 'By proceeding, you consent to '),
                          TextSpan(
                            text: "TaxeTaxi's terms of conditions",
                            style: TextStyle(
                              color: Color(0xFFFDBB2D),
                              fontWeight: FontWeight.bold,
                            ), // Primary yellow color
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'privacy policy',
                            style: TextStyle(
                              color: Color(0xFFFDBB2D),
                              fontWeight: FontWeight.bold,
                            ), // Primary yellow color
                          ),
                          TextSpan(
                            text:
                                ' and also to get calls, SMS messages, including by automated means, from the app and its affiliates to the number provided.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
