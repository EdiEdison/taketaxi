import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/services/toast_service.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';

class EnterCodeScreen extends StatelessWidget {
  const EnterCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String code = "";

    return Scaffold(
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
                "What’s the code ?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the code sent to +237653603453",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 4,
                obscureText: false,
                autoFocus: true,
                animationType: AnimationType.fade,
                textStyle: const TextStyle(fontSize: 30),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.underline,
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeColor: AppColors.inputBackground,
                  inactiveColor: AppColors.inputBackground,
                ),
                onChanged: (value) => code = value,
                onCompleted: (value) => code = value,
              ),
              const SizedBox(height: 50),
              const Text("You will be able to resend in 30s "),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Resend",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                child: CustomRoundedButton(
                  text: 'Verify',
                  onPressed: () {
                    if (code == "5555") {
                      showCustomToast(
                        context,
                        "Code verified successfully",
                        ToastType.success,
                      );
                    } else {
                      showCustomToast(context, "Invalid code", ToastType.error);
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
