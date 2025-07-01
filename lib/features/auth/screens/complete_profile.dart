import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();

  File? _profileImage;
  File? _idCardImage;

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
        } else {
          _idCardImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitProfile() async {
    final String fullName = _fullNameController.text.trim();
    final String? userId = _supabase.auth.currentUser?.id;

    if (fullName.isEmpty) {
      showCustomSnackbar(
        context,
        "Please enter your full name.",
        ToastType.error,
      );
      return;
    }

    if (userId == null) {
      showCustomSnackbar(
        context,
        "User not logged in. Please re-authenticate.",
        ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profilePicUrl;

      if (_profileImage != null) {
        final String imageFileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String imagePath = '$userId/$imageFileName';

        final String storageResponse = await _supabase.storage
            .from('profilepictures')
            .upload(
              imagePath,
              _profileImage!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        profilePicUrl = _supabase.storage
            .from('profilepictures')
            .getPublicUrl(imagePath);
      }

      final Map<String, dynamic> updateData = {'name': fullName};
      if (profilePicUrl != null) {
        updateData['profile_pic_url'] = profilePicUrl;
      }

      await _supabase.from('users').update(updateData).eq('id', userId);

      showCustomSnackbar(
        context,
        "Profile updated successfully!",
        ToastType.success,
      );

      context.go("/main/home");
    } on StorageException catch (e) {
      showCustomSnackbar(
        context,
        "Error uploading image: ${e.message}",
        ToastType.error,
      );
      print('Storage Error: ${e.message}');
    } catch (e) {
      showCustomSnackbar(
        context,
        "Error updating profile: $e",
        ToastType.error,
      );
      print('Profile update error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImageUploadSection({
    required String title,
    required String description,
    required File? imageFile,
    required bool isProfile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        DottedBorder(
          options: RectDottedBorderOptions(
            dashPattern: const [6, 6],
            strokeWidth: 1,
            padding: EdgeInsets.all(15),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  imageFile != null
                      ? 'Selected: ${imageFile.path.split('/').last}'
                      : 'No file chosen',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 150, // Fixed width for the choose photo button
                  child: CustomRoundedButton(
                    text: 'Choose Photo',
                    backgroundColor: AppColors.uploadImageColor,
                    textColor: AppColors.uploadImageTextColor,
                    onPressed: () => _pickImage(ImageSource.gallery, isProfile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

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
              context.pop();
            },
          ),
          title: Text(
            'Complete your profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'To ensure the safety of our community, please\nprovide the following information.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _fullNameController,
                keyboardType: TextInputType.name,
                style: GoogleFonts.poppins(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
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
              ),
              const SizedBox(height: 32),
              _buildImageUploadSection(
                title: 'Upload your profile picture',
                description:
                    'Upload Photo\nTap to upload a clear photo of yourself.',
                imageFile: _profileImage,
                isProfile: true,
              ),
              const SizedBox(height: 32),
              _buildImageUploadSection(
                title: 'Upload your ID card',
                description:
                    'Upload ID\nTap to upload a clear photo of your ID card.',
                imageFile: _idCardImage,
                isProfile: false,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: CustomRoundedButton(
                  text: _isLoading ? 'Submitting...' : 'Submit',
                  backgroundColor:
                      _isLoading ? AppColors.buttonDisabled : AppColors.primary,
                  onPressed: _isLoading ? null : _submitProfile,
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ), // Show spinner
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
