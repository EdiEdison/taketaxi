import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/features/profile/controller/profile_controller.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        ImageProvider? avatarImageProvider;
        if (controller.userAvatarUrl.startsWith('assets/')) {
          avatarImageProvider = AssetImage(controller.userAvatarUrl);
        } else if (controller.userAvatarUrl.isNotEmpty) {
          avatarImageProvider = NetworkImage(controller.userAvatarUrl);
        }
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              controller.isEditing ? "Edit Profile" : "Profile",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            backgroundColor: AppColors.white,
            elevation: 0.5,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.inputBackground,
                          backgroundImage: avatarImageProvider,
                          child:
                              controller.userAvatarUrl.isEmpty
                                  ? Image.asset(controller.userAvatarUrl)
                                  : null,
                        ),
                        if (controller.isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                // TODO: Implement image picker logic here
                                controller.updateAvatar(
                                  "assets/images/profile_image.jpg",
                                ); // Simulate change
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildProfileField(
                      context,
                      label: "Full Name",
                      controller: controller.nameController,
                      enabled: controller.isEditing,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      context,
                      label: "Email Address",
                      controller: controller.emailController,
                      enabled: controller.isEditing,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      context,
                      label: "Phone Number",
                      controller: controller.phoneController,
                      enabled: controller.isEditing,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      context,
                      label: "Address",
                      controller: controller.addressController,
                      enabled: controller.isEditing,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 32),
                    if (controller.isEditing)
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: CustomRoundedButton(
                          text:
                              controller.isLoading
                                  ? "Saving..."
                                  : "Save changes",
                          backgroundColor:
                              controller.nameController.text.isEmpty ||
                                      controller.emailController.text.isEmpty ||
                                      controller.phoneController.text.isEmpty ||
                                      controller.addressController.text.isEmpty
                                  ? AppColors.buttonDisabled
                                  : AppColors.primary,
                          onPressed:
                              controller.isLoading
                                  ? null
                                  : () => controller.saveProfile(context),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.isLoading &&
                  controller.isEditing) // Show global loading if saving
                Positioned.fill(
                  child: Container(
                    color: AppColors.black.withOpacity(0.4),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => controller.toggleEditMode(),
            backgroundColor:
                controller.isEditing ? AppColors.secondary : AppColors.primary,
            child: Icon(
              controller.isEditing ? Icons.close : Icons.edit,
              color: AppColors.white,
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildProfileField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.inputBackground : AppColors.grey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.white),
              hintText: label,
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
