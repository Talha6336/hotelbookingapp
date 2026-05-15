import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotelbookingapp/presentation/owner/owner_bookings_screen.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../customer/edit_profile_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  final VoidCallback onBackToHome;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onMyHotels;
  const OwnerProfileScreen({
    super.key,
    required this.onBackToHome,
    this.onOpenBookings,
    this.onMyHotels,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ownerHotelsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('hotels')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ownerBookingsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: uid)
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
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context),

                      const SizedBox(height: 26),

                      Text(
                        'Owner Profile',
                        style: TextStyle(
                          color: AppColors.adaptiveTextPrimary(context),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Manage your hotel owner account.',
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
                              child: Text(
                                'Could not load profile data.',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                ),
                              ),
                            );
                          }

                          final userData = snapshot.data?.data() ?? {};

                          final String name = userData['name'] ?? 'Hotel Owner';

                          final String email =
                              userData['email'] ??
                              currentUser.email ??
                              'No email';

                          final String phone = userData['phone'] ?? 'Not added';

                          final String role = userData['role'] ?? 'owner';

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

                              _buildOwnerStats(context),

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
            if (this.onBackToHome != null) {
              this.onBackToHome();
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
                ? Icon(Icons.person_rounded, color: Colors.white, size: 46)
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
              style: TextStyle(
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

  Widget _buildOwnerStats(BuildContext parentContext) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _ownerHotelsStream(),
      builder: (context, hotelSnapshot) {
        final totalHotels = hotelSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ownerBookingsStream(),
          builder: (context, bookingSnapshot) {
            int totalRequests = 0;
            int pendingRequests = 0;
            int acceptedRequests = 0;

            if (bookingSnapshot.hasData) {
              final bookings = bookingSnapshot.data!.docs;

              totalRequests = bookings.length;

              pendingRequests = bookings.where((doc) {
                final data = doc.data();
                return data['status'] == 'pending';
              }).length;

              acceptedRequests = bookings.where((doc) {
                final data = doc.data();
                return data['status'] == 'accepted';
              }).length;
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        title: 'Hotels',
                        value: totalHotels.toString(),
                        icon: Icons.business_rounded,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statBox(
                        title: 'Requests',
                        value: totalRequests.toString(),
                        icon: Icons.receipt_long_rounded,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        title: 'Pending',
                        value: pendingRequests.toString(),
                        icon: Icons.pending_actions_rounded,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statBox(
                        title: 'Accepted',
                        value: acceptedRequests.toString(),
                        icon: Icons.check_circle_rounded,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
    return _glassCard(
      child: Column(
        children: [
          _actionTile(
            context: context,
            icon: Icons.business_rounded,
            title: 'My Hotels',
            subtitle: 'View and manage your hotels',
            onTap: () {
              if (onMyHotels != null) {
                onMyHotels!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerBookingsScreen(),
                  ),
                );
              }
            },
          ),
          _divider(context),
          _actionTile(
            context: context,
            icon: Icons.receipt_long_rounded,
            title: 'Booking Requests',
            subtitle: 'Accept or reject booking requests',
            onTap: () {
              if (onOpenBookings != null) {
                onOpenBookings!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerBookingsScreen(),
                  ),
                );
              }
            },
          ),
<<<<<<< Updated upstream
          _divider(),
=======
          _divider(context),
>>>>>>> Stashed changes
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

  Widget _actionTile({
    required BuildContext context,
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
<<<<<<< Updated upstream
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
=======
              border: Border.all(color: AppColors.adaptiveBorder(context)),
            ),
            child: Icon(
              icon,
              color: AppColors.adaptiveTextPrimary(context),
              size: 20,
>>>>>>> Stashed changes
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
<<<<<<< Updated upstream
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
=======
    return Builder(
      builder: (context) => ClipRRect(
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
>>>>>>> Stashed changes
          ),
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _divider() {
    return Divider(color: Colors.white.withValues(alpha: 0.12), height: 1);
=======
  Widget _divider(BuildContext context) {
    return Divider(color: AppColors.adaptiveBorder(context), height: 1);
>>>>>>> Stashed changes
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login_rounded, color: AppColors.accent, size: 70),
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
                'Please login to view your owner profile.',
                textAlign: TextAlign.center,
<<<<<<< Updated upstream
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
=======
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
>>>>>>> Stashed changes
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
                child: Text('Go to Login'),
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
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Logout',
<<<<<<< Updated upstream
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
=======
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
>>>>>>> Stashed changes
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
<<<<<<< Updated upstream
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
=======
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
>>>>>>> Stashed changes
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout(context);
              },
              child: Text(
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
