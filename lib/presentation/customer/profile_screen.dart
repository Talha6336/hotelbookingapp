import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotelbookingapp/core/theme/theme_provider.dart';
import 'package:hotelbookingapp/presentation/customer/customer_bookings_screen.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback? onOpenBookings;

  const ProfileScreen({super.key, this.onBackToHome, this.onOpenBookings});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EditProfileScreen(userData: userDoc.data() ?? {}),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open edit profile: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: currentUser == null
              ? _buildLoginRequired(context)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  // THE FIX: Increased bottom padding to 130 to clear the floating bottom navigation bar
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context),
                      const SizedBox(height: 26),
                      Text(
                        'My Profile',
                        style: TextStyle(
                          color: AppColors.adaptiveTextPrimary(context),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your account and booking activity.',
                        style: TextStyle(
                          color: AppColors.adaptiveTextSecondary(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _userStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 60),
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return _glassCard(
                              context: context,
                              child: Text(
                                'Could not load profile data.',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                ),
                              ),
                            );
                          }

                          final userData = snapshot.data?.data() ?? {};
                          final String name = userData['name'] ?? 'Guest User';
                          final String email =
                              userData['email'] ??
                              currentUser.email ??
                              'No email';
                          final String phone = userData['phone'] ?? 'Not added';
                          final String role = userData['role'] ?? 'customer';
                          final String? profileImage = userData['profileImage'];

                          return Column(
                            children: [
                              _buildProfileHeader(
                                context: context,
                                name: name,
                                email: email,
                                role: role,
                                profileImage: profileImage,
                              ),
                              const SizedBox(height: 20),
                              _buildStatsCard(context),
                              const SizedBox(height: 20),
                              _buildInfoCard(
                                context: context,
                                name: name,
                                email: email,
                                phone: phone,
                                role: role,
                              ),
                              const SizedBox(height: 20),
                              _buildActionCard(context),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _circleGlassButton(
          context: context,
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            if (onBackToHome != null) {
              onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        const Spacer(),
        _circleGlassButton(
          context: context,
          icon: Icons.edit_outlined,
          onTap: () => _openEditProfile(context),
        ),
      ],
    );
  }

  Widget _buildProfileHeader({
    required BuildContext context,
    required String name,
    required String email,
    required String role,
    String? profileImage,
  }) {
    return _glassCard(
      context: context,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            height: 92,
            width: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: profileImage == null || profileImage.isEmpty
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
              image: profileImage != null && profileImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(profileImage),
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
            child: profileImage == null || profileImage.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 46,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.adaptiveTextSecondary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.70),
              ),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingsStream(),
      builder: (context, snapshot) {
        int totalBookings = 0;
        int pendingBookings = 0;
        int acceptedBookings = 0;

        if (snapshot.hasData) {
          final bookings = snapshot.data!.docs;
          totalBookings = bookings.length;
          pendingBookings = bookings
              .where((doc) => doc.data()['status'] == 'pending')
              .length;
          acceptedBookings = bookings
              .where(
                (doc) =>
                    doc.data()['status'] == 'accepted' ||
                    doc.data()['status'] == 'approved',
              )
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _statBox(
                title: 'Total',
                value: totalBookings.toString(),
                icon: Icons.bookmark_rounded,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox(
                title: 'Pending',
                value: pendingBookings.toString(),
                icon: Icons.pending_actions_rounded,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox(
                title: 'Accepted',
                value: acceptedBookings.toString(),
                icon: Icons.check_circle_rounded,
                context: context,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox({
    required String title,
    required String value,
    required IconData icon,
    required BuildContext context,
  }) {
    return _glassCard(
      context: context,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: AppColors.adaptiveTextSecondary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) {
    return _glassCard(
      context: context,
      child: Column(
        children: [
          _profileInfoRow(
            context: context,
            icon: Icons.person_outline_rounded,
            title: 'Full Name',
            value: name,
          ),
          _divider(context),
          _profileInfoRow(
            context: context,
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
          ),
          _divider(context),
          _profileInfoRow(
            context: context,
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: phone,
          ),
          _divider(context),
          _profileInfoRow(
            context: context,
            icon: Icons.verified_user_outlined,
            title: 'Role',
            value: role,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Detect if the app is currently in dark mode to update the switch

    final bool isDarkMode =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    return _glassCard(
      context: context,
      child: Column(
        children: [
          _actionTile(
            context: context,
            icon: Icons.bookmark_border_rounded,
            title: 'My Bookings',
            subtitle: 'View booking status',
            onTap: () {
              if (onOpenBookings != null) {
                onOpenBookings!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerBookingsScreen(),
                  ),
                );
              }
            },
          ),
          _divider(context),
          _actionTile(
            context: context,
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Contact hotel booking support',
            onTap: () => _showSupportDialog(context),
          ),
          _divider(context),

          // NEW: Dark Mode Toggle
          _actionTile(
            context: context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Toggle app visual theme',
            trailing: Switch(
              value: isDarkMode,
              activeColor: AppColors.primary,
              onChanged: (value) {
                // To make this switch work, call your Theme Provider here!
                themeProvider.toggleTheme(value);
              },
            ),
            onTap: () {}, // Let the switch handle the tap
          ),

          _divider(context),
          _actionTile(
            context: context,
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            isDanger: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modified to accept an optional 'trailing' widget for the Switch
  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
    Widget? trailing,
  }) {
    final color = isDanger ? Colors.redAccent : AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger
                          ? Colors.redAccent
                          : AppColors.adaptiveTextPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.adaptiveTextTertiary(context),
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  Widget _circleGlassButton({
    required BuildContext context,
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
    required BuildContext context,
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

  Widget _divider(BuildContext context) {
    return Divider(color: AppColors.adaptiveBorder(context), height: 1);
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassCard(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.login_rounded,
                color: AppColors.accent,
                size: 70,
              ),
              const SizedBox(height: 18),
              Text(
                'Login Required',
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to view your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.adaptiveTextPrimary(context),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'Help & Support',
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For support, please contact the developers:',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              _developerRow(context, 'Muhammad Talha'),
              const SizedBox(height: 12),
              _developerRow(context, 'Muhammad Zain Ul Abidin'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _developerRow(BuildContext context, String name) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.code_rounded,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
