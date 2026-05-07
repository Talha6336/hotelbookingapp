import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _entranceController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Background Floating Animation
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    // Staggered Entrance Animation
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

  // Real-time stream for the logged-in owner's bookings
  Stream<QuerySnapshot> _getOwnerBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Compute live analytics from the stream
  Map<String, dynamic> _computeAnalytics(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0;
    int pending = 0;
    int active = 0;
    int completed = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      
      if (status == 'approved' || status == 'completed') {
        totalRevenue += (data['totalPrice'] ?? 0).toDouble();
      }
      
      if (status == 'pending') pending++;
      if (status == 'approved') active++;
      if (status == 'completed') completed++;
    }

    return {
      'revenue': totalRevenue,
      'pending': pending,
      'active': active,
      'completed': completed,
      'total': docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Luxury Dark Gradient Background
          Container(decoration: const BoxDecoration(gradient: AppColors.darkGradient)),

          // 2. Animated Floating Orbs
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingCircle(
                    size: 300,
                    top: -100 + (math.sin(_floatingController.value * math.pi) * 40),
                    left: -100,
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                  _buildFloatingCircle(
                    size: 400,
                    bottom: 50 + (math.cos(_floatingController.value * math.pi) * 50),
                    right: -150,
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ],
              );
            },
          ),

          // 3. Main Scrollable Dashboard
          SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOwnerBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                final docs = snapshot.data?.docs ?? [];
                final analytics = _computeAnalytics(docs);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildAppBar()),
                    SliverToBoxAdapter(child: const SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildHeroCard(analytics)),
                    SliverToBoxAdapter(child: const SizedBox(height: 24)),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: const SizedBox(height: 24)),
                    SliverToBoxAdapter(child: _buildStatsGrid(analytics)),
                    SliverToBoxAdapter(child: const SizedBox(height: 24)),
                    SliverToBoxAdapter(child: _buildChartPlaceholder()),
                    SliverToBoxAdapter(child: const SizedBox(height: 24)),
                    SliverToBoxAdapter(child: _buildSectionTitle("Recent Bookings", "View All")),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120), // Bottom padding for nav bar
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= docs.length || index > 5) return null; // Show only top 5 recent
                            final bookingData = docs[index].data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _OwnerBookingCard(bookingData: bookingData, bookingId: docs[index].id),
                            );
                          },
                          childCount: math.min(docs.length, 5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 4. Floating Bottom Navigation Bar
          Positioned(bottom: 24, left: 24, right: 24, child: _buildFloatingNavBar()),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome Back 👋", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              const SizedBox(height: 4),
              const Text("Hotel Manager", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              _glassIconButton(Icons.notifications_none_rounded, showBadge: true),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=60'), // Manager placeholder
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> analytics) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Revenue", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: Color(0xFF4CAF50), size: 14),
                      SizedBox(width: 4),
                      Text("+12.5%", style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currencyFormat.format(analytics['revenue'] ?? 0),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildMiniStat(Icons.book_online, "${analytics['active']} Active Stays"),
                const SizedBox(width: 20),
                _buildMiniStat(Icons.pending_actions, "${analytics['pending']} Pending Req."),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {"icon": Icons.add_business_rounded, "label": "Add Hotel"},
      {"icon": Icons.meeting_room_rounded, "label": "Rooms"},
      {"icon": Icons.receipt_long_rounded, "label": "Requests"},
      {"icon": Icons.analytics_rounded, "label": "Analytics"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          return Column(
            children: [
              _glassIconButton(a["icon"] as IconData, size: 56, iconSize: 26, isGradient: true),
              const SizedBox(height: 8),
              Text(a["label"] as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatSquare("Total Bookings", analytics['total'].toString(), Icons.library_books_rounded, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatSquare("Completed", analytics['completed'].toString(), Icons.check_circle_rounded, const Color(0xFF4CAF50))),
        ],
      ),
    );
  }

  Widget _buildStatSquare(String title, String value, IconData icon, Color color) {
    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Revenue Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartBar(0.4, "Jan"), _buildChartBar(0.6, "Feb"),
                  _buildChartBar(0.5, "Mar"), _buildChartBar(0.9, "Apr"),
                  _buildChartBar(0.7, "May"), _buildChartBar(1.0, "Jun"), // Jun is peak
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          height: 120 * heightFactor,
          width: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, AppColors.accent.withOpacity(0.3)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(action, style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION & HELPERS
  // ===========================================================================

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
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, "Dashboard"),
              _buildNavItem(1, Icons.business_rounded, "Hotels"),
              _buildNavItem(2, Icons.receipt_long_rounded, "Requests"),
              _buildNavItem(3, Icons.person_rounded, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary]) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white.withOpacity(0.5), size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
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
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassIconButton(IconData icon, {bool showBadge = false, double size = 46, double iconSize = 22, bool isGradient = false}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: size, width: size,
              decoration: BoxDecoration(
                gradient: isGradient ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary]) : null,
                color: isGradient ? null : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 4, top: 4,
            child: Container(
              height: 10, width: 10,
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ),
          )
      ],
    );
  }

  Widget _buildFloatingCircle({required double size, double? top, double? bottom, double? left, double? right, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      ),
    );
  }
}

// ===========================================================================
// REUSABLE BOOKING CARD FOR OWNERS
// ===========================================================================
class _OwnerBookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const _OwnerBookingCard({required this.bookingData, required this.bookingId});

  @override
  State<_OwnerBookingCard> createState() => _OwnerBookingCardState();
}

class _OwnerBookingCardState extends State<_OwnerBookingCard> {
  bool _isLoading = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'pending': return const Color(0xFFFF9800);
      case 'cancelled': return const Color(0xFFF44336);
      case 'completed': return AppColors.primary;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $newStatus successfully'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update booking'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bookingData['status']?.toString().toUpperCase() ?? 'PENDING';
    final statusColor = _getStatusColor(widget.bookingData['status'] ?? '');
    final customerName = widget.bookingData['customerName'] ?? 'Guest';
    final hotelName = widget.bookingData['hotelName'] ?? 'Unknown Hotel';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text(customerName[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(hotelName, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              if (status == 'PENDING') ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _updateStatus('cancelled'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _updateStatus('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.backgroundDark1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: AppColors.backgroundDark1, strokeWidth: 2))
                            : const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}