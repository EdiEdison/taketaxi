import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 150),
              Image.asset('assets/images/logo.png', width: 150, height: 50),
              const SizedBox(height: 20),
              Text(
                'What’s your phone number ?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send you a confirmation code',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 50),
              IntlPhoneField(
                style: TextStyle(color: AppColors.white),
                dropdownTextStyle: TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  fillColor: AppColors.inputBackground,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                ),
                initialCountryCode: 'CM',
                onChanged: (phone) {
                  setState(() {
                    phoneNumber = phone.completeNumber;
                  });
                },
              ),
              const SizedBox(height: 50),
              Container(
                width: 300,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: Colors.black),
                    children: const [
                      TextSpan(text: 'By Continuing, you agree to our '),
                      TextSpan(
                        text: 'Privacy Policies',
                        style: TextStyle(color: Color(0xFFFDBB2D)),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Terms of Conditions',
                        style: TextStyle(color: Color(0xFFFDBB2D)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),

              SizedBox(
                width: double.infinity,
                child: CustomRoundedButton(
                  text: 'Send Code',
                  onPressed: () {
                    // Validate and navigate
                    if (phoneNumber != null) {
                      print('Phone: $phoneNumber');
                      // Navigate to OTP screen or handle next step
                      context.go('/verifyphone', extra: phoneNumber);
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
