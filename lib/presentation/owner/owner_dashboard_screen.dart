import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'add_hotel_screen.dart';
import 'owner_bookings_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_hotels_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _entranceController;

  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getCurrentOwnerStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getOwnerBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getOwnerHotelsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('hotels')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots();
  }

  Map<String, dynamic> _computeAnalytics({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> hotelDocs,
  }) {
    double totalRevenue = 0;
    int pending = 0;
    int accepted = 0;
    int rejected = 0;
    int cancelled = 0;

    for (final doc in bookingDocs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase() ?? '';

      final totalPriceValue = data['totalPrice'];
      final double totalPrice = totalPriceValue is num
          ? totalPriceValue.toDouble()
          : double.tryParse(totalPriceValue.toString()) ?? 0.0;

      if (status == 'accepted') {
        totalRevenue += totalPrice;
        accepted++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'rejected') {
        rejected++;
      } else if (status == 'cancelled') {
        cancelled++;
      }
    }

    return {
      'revenue': totalRevenue,
      'pending': pending,
      'accepted': accepted,
      'rejected': rejected,
      'cancelled': cancelled,
      'totalBookings': bookingDocs.length,
      'totalHotels': hotelDocs.length,
    };
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortBookingsByCreatedAt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sortedDocs = [...docs];

    sortedDocs.sort((a, b) {
      final aCreatedAt = a.data()['createdAt'];
      final bCreatedAt = b.data()['createdAt'];

      if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
        return bCreatedAt.compareTo(aCreatedAt);
      }

      return 0;
    });

    return sortedDocs;
  }

  void _openAddHotelScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHotelScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
          ),

          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingCircle(
                    size: 300,
                    top: -100 +
                        (math.sin(_floatingController.value * math.pi) * 40),
                    left: -100,
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                  _buildFloatingCircle(
                    size: 400,
                    bottom: 50 +
                        (math.cos(_floatingController.value * math.pi) * 50),
                    right: -150,
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getOwnerBookingsStream(),
              builder: (context, bookingSnapshot) {
                if (bookingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  );
                }

                if (bookingSnapshot.hasError) {
                  return _buildFullScreenMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load dashboard',
                    subtitle: 'Please check your Firebase setup.',
                  );
                }

                final bookingDocs = bookingSnapshot.data?.docs ?? [];

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _getOwnerHotelsStream(),
                  builder: (context, hotelSnapshot) {
                    final hotelDocs = hotelSnapshot.data?.docs ?? [];

                    final analytics = _computeAnalytics(
                      bookingDocs: bookingDocs,
                      hotelDocs: hotelDocs,
                    );

                    final sortedBookings = _sortBookingsByCreatedAt(
                      bookingDocs,
                    );

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildAppBar()),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),

                        SliverToBoxAdapter(
                          child: _buildHeroCard(analytics),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),

                        SliverToBoxAdapter(
                          child: _buildStatsGrid(analytics),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),

                        SliverToBoxAdapter(
                          child: _buildBookingOverview(analytics),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),

                        SliverToBoxAdapter(
                          child: _buildSectionTitle(
                            title: 'Recent Bookings',
                            action: 'View All',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OwnerBookingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                        if (sortedBookings.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                160,
                              ),
                              child: _buildEmptyRecentBookings(),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 160,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= sortedBookings.length ||
                                      index >= 5) {
                                    return null;
                                  }

                                  final doc = sortedBookings[index];
                                  final bookingData = doc.data();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _OwnerBookingCard(
                                      bookingData: bookingData,
                                      bookingId: doc.id,
                                    ),
                                  );
                                },
                                childCount: math.min(
                                  sortedBookings.length,
                                  5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          Positioned(
            right: 24,
            bottom: 110,
            child: _buildAddHotelFloatingButton(),
          ),

          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _getCurrentOwnerStream(),
      builder: (context, snapshot) {
        final user = FirebaseAuth.instance.currentUser;
        final userData = snapshot.data?.data();

        final String ownerName = userData?['name'] ?? 'Hotel Owner';
        final String email = userData?['email'] ?? user?.email ?? '';
        final String profileImage = userData?['profileImage'] ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back 👋',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Row(
                children: [
                  _glassIconButton(
                    Icons.notifications_none_rounded,
                    showBadge: true,
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    backgroundImage:
                        profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                    child: profileImage.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> analytics) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    final double revenue = analytics['revenue'] ?? 0.0;
    final int pending = analytics['pending'] ?? 0;
    final int accepted = analytics['accepted'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Revenue',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currencyFormat.format(revenue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _buildMiniStat(
                  Icons.check_circle_rounded,
                  '$accepted Accepted',
                ),
                const SizedBox(width: 20),
                _buildMiniStat(
                  Icons.pending_actions_rounded,
                  '$pending Pending',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> analytics) {
    final int totalHotels = analytics['totalHotels'] ?? 0;
    final int totalBookings = analytics['totalBookings'] ?? 0;
    final int pending = analytics['pending'] ?? 0;
    final int accepted = analytics['accepted'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatSquare(
                  'Hotels',
                  totalHotels.toString(),
                  Icons.business_rounded,
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatSquare(
                  'Bookings',
                  totalBookings.toString(),
                  Icons.library_books_rounded,
                  Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatSquare(
                  'Pending',
                  pending.toString(),
                  Icons.pending_actions_rounded,
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatSquare(
                  'Accepted',
                  accepted.toString(),
                  Icons.check_circle_rounded,
                  const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSquare(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverview(Map<String, dynamic> analytics) {
    final int pending = analytics['pending'] ?? 0;
    final int accepted = analytics['accepted'] ?? 0;
    final int rejected = analytics['rejected'] ?? 0;
    final int cancelled = analytics['cancelled'] ?? 0;
    final int total = analytics['totalBookings'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            if (total == 0)
              Text(
                'No booking data available yet.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 14,
                ),
              )
            else ...[
              _buildOverviewRow(
                label: 'Accepted',
                value: accepted,
                total: total,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 14),
              _buildOverviewRow(
                label: 'Pending',
                value: pending,
                total: total,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 14),
              _buildOverviewRow(
                label: 'Rejected',
                value: rejected,
                total: total,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              _buildOverviewRow(
                label: 'Cancelled',
                value: cancelled,
                total: total,
                color: Colors.deepOrangeAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final double percent = total == 0 ? 0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHotelFloatingButton() {
    return GestureDetector(
      onTap: _openAddHotelScreen,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_business_rounded,
              color: AppColors.backgroundDark1,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'Add Hotel',
              style: TextStyle(
                color: AppColors.backgroundDark1,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecentBookings() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.accent,
            size: 60,
          ),
          const SizedBox(height: 14),
          const Text(
            'No recent bookings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Customer booking requests will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavItem(1, Icons.business_rounded, 'Hotels'),
              _buildNavItem(2, Icons.receipt_long_rounded, 'Requests'),
              _buildNavItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerHotelsScreen(),
            ),
          );
          return;
        }

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerBookingsScreen(),
            ),
          );
          return;
        }

        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerProfileScreen(),
            ),
          );
          return;
        }

        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassIconButton(
    IconData icon, {
    bool showBadge = false,
    double size = 46,
    double iconSize = 22,
    bool isGradient = false,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                gradient: isGradient
                    ? const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      )
                    : null,
                color: isGradient ? null : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              height: 10,
              width: 10,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingCircle({
    required double size,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.accent,
                size: 70,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerBookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const _OwnerBookingCard({
    required this.bookingData,
    required this.bookingId,
  });

  @override
  State<_OwnerBookingCard> createState() => _OwnerBookingCardState();
}

class _OwnerBookingCardState extends State<_OwnerBookingCard> {
  bool _isLoading = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'rejected':
        return const Color(0xFFF44336);
      case 'cancelled':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $newStatus successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rawStatus =
        widget.bookingData['status']?.toString().toLowerCase() ?? 'pending';

    final String status = rawStatus.toUpperCase();
    final Color statusColor = _getStatusColor(rawStatus);

    final String customerName = widget.bookingData['customerName'] ?? 'Guest';

    final String hotelName = widget.bookingData['hotelName'] ?? 'Unknown Hotel';

    final num totalPrice = widget.bookingData['totalPrice'] ?? 0;
    final int totalNights = widget.bookingData['totalNights'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hotelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Rs. ${totalPrice.toInt()} • $totalNights nights',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (rawStatus == 'pending') ...[
                const SizedBox(height: 16),
                const Divider(
                  color: Colors.white12,
                  height: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => _updateStatus('rejected'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                          ),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => _updateStatus('accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.backgroundDark1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.backgroundDark1,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Accept',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}