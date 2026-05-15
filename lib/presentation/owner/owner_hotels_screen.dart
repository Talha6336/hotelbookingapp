import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import 'add_hotel_screen.dart';
import 'edit_hotel_screen.dart';

class OwnerHotelsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const OwnerHotelsScreen({super.key, this.onBackToHome});

  @override
  State<OwnerHotelsScreen> createState() => _OwnerHotelsScreenState();
}

class _OwnerHotelsScreenState extends State<OwnerHotelsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // THE FIX: Cache the stream so it doesn't reset on every keystroke
  late Stream<QuerySnapshot> _hotelsStream;

  @override
  void initState() {
    super.initState();

    // Initialize the stream only ONCE when the screen loads
    _hotelsStream = _getMyHotelsStream();
  }

  @override
  void dispose() {
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
    double totalRevenue = 0;
    int totalRooms = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'Disabled') active++;
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Luxury Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.adaptiveBackgroundGradient(context),
            ),
          ),

          // 3. Main Content
          SafeArea(
            bottom: false,
            // THE FIX: Move App Bar and Search OUTSIDE the StreamBuilder
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchAndFilter(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _hotelsStream, // Uses the cached stream
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading hotels",
                            style: TextStyle(
                              color: AppColors.adaptiveTextPrimary(context),
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final analytics = _computeAnalytics(docs);

                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final query = _searchQuery.trim().toLowerCase();

                        if (query.isEmpty) return true;

                        final name = (data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final city = (data['city'] ?? '')
                            .toString()
                            .toLowerCase();
                        final address = (data['address'] ?? '')
                            .toString()
                            .toLowerCase();
                        final category = (data['category'] ?? '')
                            .toString()
                            .toLowerCase();
                        final price = (data['pricePerNight'] ?? '')
                            .toString()
                            .toLowerCase();

                        return name.contains(query) ||
                            city.contains(query) ||
                            address.contains(query) ||
                            category.contains(query) ||
                            price.contains(query);
                      }).toList();

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          if (docs.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildTopAnalytics(analytics),
                            ),

                          if (docs.isEmpty)
                            SliverFillRemaining(child: _buildEmptyState())
                          else if (filteredDocs.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  "No hotels match your search.",
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextSecondary(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 120,
                              ),
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
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHotelScreen()),
          ),
          backgroundColor: AppColors.accent,
          icon: Icon(
            Icons.add_business_rounded,
            color: AppColors.adaptiveTextPrimary(context),
          ),
          label: Text(
            "Add Hotel",
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
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
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 5,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.adaptiveTextPrimary(context),
                  size: 18,
                ),
                onPressed: () {
                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Hotels",
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Manage your hotel properties",
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
                // Removed the buggy FocusNode completely
                style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search your hotels...",
                  hintStyle: TextStyle(
                    color: AppColors.adaptiveTextTertiary(context),
                  ),
                  icon: Icon(
                    Icons.search,
                    color: AppColors.adaptiveTextTertiary(context),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.adaptiveTextTertiary(context),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
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
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
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
                SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
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
            color: AppColors.adaptiveTextTertiary(context),
          ),
          SizedBox(height: 20),
          Text(
            "No Hotels Added Yet",
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Start building your hotel business today.",
            style: TextStyle(
              color: AppColors.adaptiveTextSecondary(context),
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
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.adaptiveBorder(context)),
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
          child: Icon(
            icon,
            color: AppColors.adaptiveTextPrimary(context),
            size: 22,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
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
    final String status = hotelData['status'] ?? 'Active';

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
              color: AppColors.adaptiveSurface(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.adaptiveBorder(context)),
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
                          child: Icon(
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
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                                : const Color(
                                    0xFFFF9800,
                                  ).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: AppColors.adaptiveTextPrimary(context),
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
                              style: TextStyle(
                                color: AppColors.adaptiveTextPrimary(context),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.adaptiveTextTertiary(context),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            city,
                            style: TextStyle(
                              color: AppColors.adaptiveTextTertiary(context),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Rs. ${price.toInt()} / night",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Divider(
                        color: AppColors.adaptiveBorder(context),
                        height: 1,
                      ),
                      SizedBox(height: 16),

                      // Mini Performance Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                            context,
                            Icons.book_online,
                            "12 Bookings",
                          ),
                          _buildMiniStat(
                            context,
                            Icons.meeting_room,
                            "4/10 Rooms",
                          ),
                          _buildMiniStat(
                            context,
                            Icons.visibility,
                            "1.2k Views",
                          ),
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

  Widget _buildMiniStat(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.adaptiveTextTertiary(context), size: 14),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.adaptiveTextSecondary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
