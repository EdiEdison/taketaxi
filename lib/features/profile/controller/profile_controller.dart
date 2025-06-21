import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:taketaxi/shared/widgets/custom_toast.dart';

class ProfileController extends ChangeNotifier {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false; // To control if fields are editable

  // Initial dummy data
  String _userName = "John Doe";
  String _userEmail = "john.doe@example.com";
  String _userPhone = "+237 678 123 456";
  String _userAddress = "123 Main Street, Buea, Cameroon";
  String _userAvatarUrl =
      "assets/images/profile_image.jpg"; // Placeholder image

  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get addressController => _addressController;

  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userAddress => _userAddress;
  String get userAvatarUrl => _userAvatarUrl;

  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;

  ProfileController() {
    _loadProfileData(); // Load initial data when controller is created
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    // In a real app, this would fetch data from a backend or local storage
    _nameController.text = _userName;
    _emailController.text = _userEmail;
    _phoneController.text = _userPhone;
    _addressController.text = _userAddress;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    // When entering edit mode, populate controllers with current data
    if (_isEditing) {
      _nameController.text = _userName;
      _emailController.text = _userEmail;
      _phoneController.text = _userPhone;
      _addressController.text = _userAddress;
    }
    notifyListeners();
  }

  Future<void> saveProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call or data saving
    await Future.delayed(const Duration(seconds: 2));

    // Basic validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      showCustomSnackbar(context, "All fields are required!", ToastType.error);
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Update internal state
    _userName = _nameController.text;
    _userEmail = _emailController.text;
    _userPhone = _phoneController.text;
    _userAddress = _addressController.text;

    _isLoading = false;
    _isEditing = false; // Exit edit mode after saving
    showCustomSnackbar(
      context,
      "Profile saved successfully!",
      ToastType.success,
    );
    notifyListeners();
    log("Profile saved: $_userName, $_userEmail, $_userPhone, $_userAddress");
  }

  // Method to update avatar (for future implementation, currently uses placeholder)
  void updateAvatar(String newUrl) {
    _userAvatarUrl = newUrl;
    notifyListeners();
    // In a real app, this would involve image picking/uploading
  }
}
