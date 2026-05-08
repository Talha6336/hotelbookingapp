import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'add_hotel_screen.dart'; // Make sure this path is correct
import 'edit_hotel_screen.dart'; // We will create this next

class OwnerHotelsScreen extends StatefulWidget {
  const OwnerHotelsScreen({super.key});

  @override
  State<OwnerHotelsScreen> createState() => _OwnerHotelsScreenState();
}

class _OwnerHotelsScreenState extends State<OwnerHotelsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getMyHotelsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('hotels')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Map<String, dynamic> _computeAnalytics(List<QueryDocumentSnapshot> docs) {
    int active = 0;
    double totalRevenue =
        0; // In a real app, this would be aggregated from bookings
    int totalRooms = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'Disabled') active++;
      // Placeholder logic for rooms and revenue
      totalRooms += (data['rooms'] as List?)?.length ?? 10;
      totalRevenue += (data['revenue'] ?? 0).toDouble();
    }

    return {
      'total': docs.length,
      'active': active,
      'rooms': totalRooms,
      'revenue': totalRevenue,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Ensures bottom nav background shows through
      body: Stack(
        children: [
          // 1. Luxury Gradient Background
          Container(
            decoration: const BoxDecoration(gradient: AppColors.darkGradient),
          ),

          // 2. Animated Floating Circles
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingCircle(
                    size: 300,
                    top: -100,
                    left: -50,
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                  _buildFloatingCircle(
                    size: 400,
                    bottom: 100,
                    right: -150,
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ],
              );
            },
          ),

          // 3. Main Content
          SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMyHotelsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading hotels",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final analytics = _computeAnalytics(docs);

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildAppBar()),
                    SliverToBoxAdapter(child: _buildSearchAndFilter()),
                    if (docs.isNotEmpty)
                      SliverToBoxAdapter(child: _buildTopAnalytics(analytics)),

                    if (docs.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else if (filteredDocs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "No hotels match your search.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 120,
                        ), // Padding for bottom nav
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final data =
                                filteredDocs[index].data()
                                    as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _PremiumOwnerHotelCard(
                                hotelData: data,
                                hotelId: filteredDocs[index].id,
                              ),
                            );
                          }, childCount: filteredDocs.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 80,
        ), // Sit above the bottom nav bar
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHotelScreen()),
          ),
          backgroundColor: AppColors.accent,
          icon: const Icon(
            Icons.add_business_rounded,
            color: AppColors.backgroundDark1,
          ),
          label: const Text(
            "Add Hotel",
            style: TextStyle(
              color: AppColors.backgroundDark1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Hotels",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Manage your hotel properties",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          _glassIconButton(Icons.notifications_none_rounded, showBadge: true),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _glassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search your hotels...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  icon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _glassIconButton(Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildTopAnalytics(Map<String, dynamic> analytics) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildAnalyticCard(
            "Total Hotels",
            analytics['total'].toString(),
            Icons.domain_rounded,
            const Color(0xFF2196F3),
          ),
          _buildAnalyticCard(
            "Active",
            analytics['active'].toString(),
            Icons.check_circle_outline,
            const Color(0xFF4CAF50),
          ),
          _buildAnalyticCard(
            "Total Rooms",
            analytics['rooms'].toString(),
            Icons.meeting_room_rounded,
            const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      // THE FIX: Wrap the Column in a FittedBox
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Replaced Spacer with a fixed SizedBox
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.domain_disabled_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Hotels Added Yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start building your hotel business today.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassIconButton(IconData icon, {bool showBadge = false}) {
    return Stack(
      children: [
        _glassCard(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (showBadge)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 8,
              width: 8,
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// REUSABLE OWNER HOTEL CARD
// ===========================================================================
class _PremiumOwnerHotelCard extends StatelessWidget {
  final Map<String, dynamic> hotelData;
  final String hotelId;

  const _PremiumOwnerHotelCard({
    required this.hotelData,
    required this.hotelId,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        hotelData['imageUrl'] ?? 'https://via.placeholder.com/400x200';
    final String name = hotelData['name'] ?? 'Unknown Hotel';
    final String city = hotelData['city'] ?? 'Unknown City';
    final double price = (hotelData['pricePerNight'] ?? 0).toDouble();
    final double rating = (hotelData['rating'] ?? 0).toDouble();
    final String status =
        hotelData['status'] ?? 'Active'; // Assume 'Active' if not set

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EditHotelScreen(hotelId: hotelId, hotelData: hotelData),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Banner with Hero
                Hero(
                  tag: 'hotel_image_$hotelId',
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 160,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white30,
                            size: 50,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? const Color(0xFF4CAF50).withOpacity(0.9)
                                : const Color(0xFFFF9800).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Rs. ${price.toInt()} / night",
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 16),

                      // Mini Performance Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(Icons.book_online, "12 Bookings"),
                          _buildMiniStat(Icons.meeting_room, "4/10 Rooms"),
                          _buildMiniStat(Icons.visibility, "1.2k Views"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
