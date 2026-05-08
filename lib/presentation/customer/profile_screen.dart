import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotelbookingapp/presentation/customer/customer_bookings_screen.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
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
          builder: (context) => EditProfileScreen(
            userData: userDoc.data() ?? {},
          ),
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
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context),
                      const SizedBox(height: 26),
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your account and booking activity.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
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
                              child: const Text(
                                'Could not load profile data.',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          final userData = snapshot.data?.data() ?? {};

                          final String name =
                              userData['name'] ?? 'Guest User';

                          final String email = userData['email'] ??
                              currentUser.email ??
                              'No email';

                          final String phone =
                              userData['phone'] ?? 'Not added';

                          final String role =
                              userData['role'] ?? 'customer';

                          final String? profileImage =
                              userData['profileImage'];

                          return Column(
                            children: [
                              _buildProfileHeader(
                                name: name,
                                email: email,
                                role: role,
                                profileImage: profileImage,
                              ),
                              const SizedBox(height: 20),
                              _buildStatsCard(),
                              const SizedBox(height: 20),
                              _buildInfoCard(
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
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        _circleGlassButton(
          icon: Icons.edit_outlined,
          onTap: () => _openEditProfile(context),
        ),
      ],
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String email,
    required String role,
    String? profileImage,
  }) {
    return _glassCard(
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
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    )
                  : null,
              image: profileImage != null && profileImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.70),
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

  Widget _buildStatsCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingsStream(),
      builder: (context, snapshot) {
        int totalBookings = 0;
        int pendingBookings = 0;
        int acceptedBookings = 0;

        if (snapshot.hasData) {
          final bookings = snapshot.data!.docs;

          totalBookings = bookings.length;

          pendingBookings = bookings.where((doc) {
            final data = doc.data();
            return data['status'] == 'pending';
          }).length;

          acceptedBookings = bookings.where((doc) {
            final data = doc.data();
            return data['status'] == 'accepted';
          }).length;
        }

        return Row(
          children: [
            Expanded(
              child: _statBox(
                title: 'Total',
                value: totalBookings.toString(),
                icon: Icons.bookmark_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox(
                title: 'Pending',
                value: pendingBookings.toString(),
                icon: Icons.pending_actions_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox(
                title: 'Accepted',
                value: acceptedBookings.toString(),
                icon: Icons.check_circle_rounded,
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
  }) {
    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) {
    return _glassCard(
      child: Column(
        children: [
          _profileInfoRow(
            icon: Icons.person_outline_rounded,
            title: 'Full Name',
            value: name,
          ),
          _divider(),
          _profileInfoRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
          ),
          _divider(),
          _profileInfoRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: phone,
          ),
          _divider(),
          _profileInfoRow(
            icon: Icons.verified_user_outlined,
            title: 'Role',
            value: role,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return _glassCard(
      child: Column(
        children: [
          _actionTile(
            icon: Icons.bookmark_border_rounded,
            title: 'My Bookings',
            subtitle: 'View booking status',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerBookingsScreen(),
                ),
              );
            },
          ),
          _divider(),
          _actionTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Contact hotel booking support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support feature will be added later'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _divider(),
          _actionTile(
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
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
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
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.35),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? Colors.redAccent : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.45),
              size: 16,
            ),
          ],
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
              color: Colors.white.withOpacity(0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withOpacity(0.12),
      height: 1,
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.login_rounded,
                color: AppColors.accent,
                size: 70,
              ),
              const SizedBox(height: 18),
              const Text(
                'Login Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to view your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
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
                  foregroundColor: AppColors.backgroundDark1,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
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