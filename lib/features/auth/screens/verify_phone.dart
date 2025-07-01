import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String _otpCode = "";
  bool _isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _verifyOtp() async {
    if (_otpCode.isEmpty || _otpCode.length < 6) {
      showCustomSnackbar(
        context,
        "Please enter the full 6-digit verification code.",
        ToastType.error,
      );
      return;
    }
    if (widget.phoneNumber == null) {
      showCustomSnackbar(
        context,
        "Phone number not provided. Please go back and re-enter.",
        ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse response = await supabase.auth.verifyOTP(
        phone: widget.phoneNumber!,
        token: _otpCode,
        type: OtpType.sms,
      );

      if (response.session != null && response.user != null) {
        final existingUser =
            await supabase
                .from('users')
                .select('*')
                .eq('id', response.user!.id)
                .limit(1)
                .maybeSingle();

        if (existingUser == null) {
          await supabase.from('users').insert({
            'id': response.user!.id,
            'phone_number': widget.phoneNumber!,
            'is_driver': false,
            'name': response.user!.phone,
          });
        }

        showCustomSnackbar(
          context,
          "Authentication successful!",
          ToastType.success,
        );

        context.go("/complete_profile");
      } else {
        showCustomSnackbar(
          context,
          "Verification failed. Please try again.",
          ToastType.error,
        );
      }
    } on AuthException catch (e) {
      showCustomSnackbar(
        context,
        "Verification failed: ${e.message}",
        ToastType.error,
      );
      print('Supabase Auth Error (Verify OTP): ${e.message}');
    } catch (e) {
      showCustomSnackbar(
        context,
        "An unexpected error occurred. Please try again.",
        ToastType.error,
      );
      print('Generic Error (Verify OTP): $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (widget.phoneNumber == null) {
      showCustomSnackbar(
        context,
        "Phone number not available to resend.",
        ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.signInWithOtp(phone: widget.phoneNumber!);
      showCustomSnackbar(
        context,
        "Verification code resent!",
        ToastType.success,
      );
    } on AuthException catch (e) {
      showCustomSnackbar(
        context,
        "Error resending code: ${e.message}",
        ToastType.error,
      );
      print('Supabase Auth Error (Resend OTP): ${e.message}');
    } catch (e) {
      showCustomSnackbar(
        context,
        "An unexpected error occurred. Please try again.",
        ToastType.error,
      );
      print('Generic Error (Resend OTP): $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 24.0;
    const double fieldOuterPaddingHorizontal = 8.0;
    const int numberOfFields = 6;
    const double fieldHeight = 60.0;

    final double availableWidthForFields =
        screenWidth - (2 * horizontalPadding);
    double calculatedFieldWidth =
        (availableWidthForFields / numberOfFields) -
        (2 * fieldOuterPaddingHorizontal);

    if (calculatedFieldWidth < 30) {
      calculatedFieldWidth = 30;
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.white,
        resizeToAvoidBottomInset: true,
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
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ), // Use the constant
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Enter the 6-digit code we sent to ${widget.phoneNumber ?? 'your phone'}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    PinCodeTextField(
                      keyboardType: TextInputType.number,
                      appContext: context,
                      length: numberOfFields,
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
                        fieldHeight: fieldHeight,
                        fieldWidth: calculatedFieldWidth,
                        activeFillColor: Colors.grey[200],
                        inactiveFillColor: Colors.grey[200],
                        selectedFillColor: Colors.grey[200],
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.transparent,
                        selectedColor: AppColors.primary,
                        fieldOuterPadding: const EdgeInsets.symmetric(
                          horizontal: fieldOuterPaddingHorizontal,
                        ),
                      ),
                      enableActiveFill: true,
                      onChanged: (value) {
                        setState(() {
                          _otpCode = value;
                        });
                      },
                      onCompleted: (value) {
                        setState(() {
                          _otpCode = value;
                        });
                        if (value.length == numberOfFields && !_isLoading) {
                          _verifyOtp();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _isLoading ? null : _resendCode,
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: CustomRoundedButton(
                        text: _isLoading ? "Verifying..." : 'Verify',
                        backgroundColor:
                            _isLoading
                                ? AppColors.buttonDisabled
                                : AppColors.primary,
                        onPressed: _isLoading ? () {} : _verifyOtp,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
