import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../services/cloudinary_service.dart';
import '../widgets/app_background.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool showPasswordSection = false;

  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;

  File? selectedImage;
  String? profileImageUrl;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;

    nameController.text = widget.userData['name'] ?? '';
    emailController.text = widget.userData['email'] ?? currentUser?.email ?? '';
    phoneController.text = widget.userData['phone'] ?? '';

    profileImageUrl = widget.userData['profileImage'];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('User not logged in.');
      return;
    }

    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        selectedImage = File(pickedFile.path);
        isUploadingImage = true;
      });

      final imageUrl = await CloudinaryService.uploadImage(selectedImage!);

      if (imageUrl == null) {
        _showSnackBar('Image upload failed.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'profileImage': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        profileImageUrl = imageUrl;
      });

      _showSnackBar('Profile picture updated.');
    } catch (e) {
      _showSnackBar('Image error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('User not logged in.');
      return;
    }

    if (nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        updatedData['profileImage'] = profileImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updatedData);

      if (showPasswordSection) {
        await _changePassword(currentUser);
      }

      if (!mounted) return;

      _showSnackBar('Profile updated successfully.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Firebase auth error.');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword(User currentUser) async {
    final email = currentUser.email;

    if (email == null) {
      throw Exception('User email not found.');
    }

    if (currentPasswordController.text.trim().isEmpty ||
        newPasswordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      throw Exception('Please fill all password fields.');
    }

    if (newPasswordController.text.trim().length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      throw Exception('New passwords do not match.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPasswordController.text.trim(),
    );

    await currentUser.reauthenticateWithCredential(credential);

    await currentUser.updatePassword(newPasswordController.text.trim());
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 26),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppColors.adaptiveTextPrimary(context),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update your personal information and password.',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    _glassCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: emailController,
                            hintText: 'Email Address',
                            icon: Icons.email_outlined,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: phoneController,
                            hintText: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordToggle(),
                    if (showPasswordSection) ...[
                      const SizedBox(height: 16),
                      _buildPasswordSection(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _circleGlassButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildAvatar() {
    final bool hasImage =
        profileImageUrl != null && profileImageUrl!.isNotEmpty;

    return Center(
      child: Stack(
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: AppColors.adaptiveBorder(context),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: hasImage
                ? null
                : Icon(
                    Icons.person_rounded,
                    color: AppColors.adaptiveTextPrimary(context),
                    size: 48,
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: isUploadingImage ? null : _pickAndUploadProfileImage,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.adaptiveTextPrimary(context),
                    width: 2,
                  ),
                ),
                child: isUploadingImage
                    ? Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: AppColors.adaptiveTextPrimary(context),
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.adaptiveTextPrimary(context),
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordToggle() {
    return _glassCard(
      child: InkWell(
        onTap: () {
          setState(() {
            showPasswordSection = !showPasswordSection;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Update your login password',
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              showPasswordSection
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.adaptiveTextSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return _glassCard(
      child: Column(
        children: [
          _buildTextField(
            controller: currentPasswordController,
            hintText: 'Current Password',
            icon: Icons.lock_outline_rounded,
            obscureText: !currentPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  currentPasswordVisible = !currentPasswordVisible;
                });
              },
              icon: Icon(
                currentPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: newPasswordController,
            hintText: 'New Password',
            icon: Icons.lock_reset_rounded,
            obscureText: !newPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  newPasswordVisible = !newPasswordVisible;
                });
              },
              icon: Icon(
                newPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm New Password',
            icon: Icons.verified_user_outlined,
            obscureText: !confirmPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  confirmPasswordVisible = !confirmPasswordVisible;
                });
              },
              icon: Icon(
                confirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.adaptiveTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: enabled
            ? AppColors.adaptiveTextPrimary(context)
            : AppColors.adaptiveTextTertiary(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.adaptiveTextTertiary(context)),
        prefixIcon: Icon(icon, color: AppColors.adaptiveTextSecondary(context)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled
            ? AppColors.adaptiveSurface(context)
            : AppColors.adaptiveSurfaceMuted(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adaptiveSurface(context)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 14,
        ),
      ),
    );
  }

  Widget _circleGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.adaptiveSurface(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveBorder(context)),
            ),
            child: Icon(
              icon,
              color: AppColors.adaptiveTextPrimary(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.adaptiveBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomSaveButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            decoration: BoxDecoration(
              color: AppColors.adaptiveSurface(context).withValues(alpha: 0.96),
              border: Border(
                top: BorderSide(color: AppColors.adaptiveBorder(context)),
              ),
            ),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || isUploadingImage ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.adaptiveTextPrimary(context),
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: 0.55,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          color: AppColors.adaptiveTextPrimary(context),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
