import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  String _selectedTab = 'All';

  final List<String> _tabs = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int pending = 0, approved = 0, cancelled = 0, completed = 0;
    for (var doc in docs) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      if (status == 'pending') pending++;
      if (status == 'approved') approved++;
      if (status == 'cancelled') cancelled++;
      if (status == 'completed') completed++;
    }
    return {
      'Total': docs.length,
      'Pending': pending,
      'Approved': approved,
      'Cancelled': cancelled,
      'Completed': completed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Premium Background
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
                    size: 250,
                    top:
                        -50 +
                        (math.sin(_floatingController.value * math.pi) * 30),
                    left: -50,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  _buildFloatingCircle(
                    size: 300,
                    bottom:
                        100 +
                        (math.cos(_floatingController.value * math.pi) * 40),
                    right: -100,
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ],
              );
            },
          ),

          // 3. Main Content
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    "Error loading bookings",
                    "Please check your connection.",
                    Icons.error_outline,
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final stats = _calculateStats(docs);

                final filteredDocs = _selectedTab == 'All'
                    ? docs
                    : docs
                          .where(
                            (d) =>
                                ((d.data() as Map)['status'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                _selectedTab.toLowerCase(),
                          )
                          .toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildAppBar()),
                    if (docs.isNotEmpty)
                      SliverToBoxAdapter(child: _buildSummaryCards(stats)),
                    SliverToBoxAdapter(child: _buildTabs()),
                    if (docs.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(
                          "No bookings yet",
                          "Start exploring luxury hotels.",
                          Icons.flight_takeoff,
                        ),
                      )
                    else if (filteredDocs.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(
                          "No $_selectedTab bookings",
                          "You don't have any $_selectedTab reservations.",
                          Icons.search_off,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                          left: 20,
                          right: 20,
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
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _PremiumBookingCard(
                                bookingData: data,
                                bookingId: filteredDocs[index].id,
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Bookings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage your hotel reservations",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _circleGlassButton(Icons.search),
              const SizedBox(width: 12),
              _circleGlassButton(Icons.filter_list),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> stats) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildStatCard("Total", stats['Total']!, AppColors.primary),
          _buildStatCard("Pending", stats['Pending']!, const Color(0xFFFF9800)),
          _buildStatCard(
            "Approved",
            stats['Approved']!,
            const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _circleGlassButton(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              /* Navigate to Home Tab */
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.backgroundDark1,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Explore Hotels",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE PREMIUM BOOKING CARD
// -----------------------------------------------------------------------------
class _PremiumBookingCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const _PremiumBookingCard({
    required this.bookingData,
    required this.bookingId,
  });

  @override
  State<_PremiumBookingCard> createState() => _PremiumBookingCardState();
}

class _PremiumBookingCardState extends State<_PremiumBookingCard> {
  bool _isExpanded = false;
  bool _isCancelling = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50); // Success
      case 'pending':
        return const Color(0xFFFF9800); // Pending
      case 'cancelled':
        return const Color(0xFFF44336); // Cancelled
      case 'completed':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  Future<void> _cancelBooking() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking request?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Booking',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'status': 'cancelled'});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status =
        widget.bookingData['status']?.toString().toUpperCase() ?? 'PENDING';
    final statusColor = _getStatusColor(widget.bookingData['status'] ?? '');
    final hotelName = widget.bookingData['hotelName'] ?? 'Luxury Hotel';
    final price = widget.bookingData['totalPrice'] ?? 0;
    final nights = widget.bookingData['totalNights'] ?? 1;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isExpanded
                    ? statusColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                // Top Main Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Image Placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.hotel,
                          color: Colors.white54,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hotelName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${_formatDate(widget.bookingData['checkInDate'])} - ${_formatDate(widget.bookingData['checkOutDate'])}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Rs. ${price.toInt()} • $nights night(s)",
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Expandable Extra Details & Buttons
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          height: 24,
                        ),
                        _buildDetailRow("Booking ID", widget.bookingId),
                        _buildDetailRow(
                          "Guest Name",
                          widget.bookingData['customerName'] ?? 'N/A',
                        ),
                        _buildDetailRow("Payment Status", "Pay at Hotel"),
                        const SizedBox(height: 16),
                        _buildActionButtons(status.toLowerCase()),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isCancelling ? null : _cancelBooking,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isCancelling ? Colors.grey : Colors.redAccent,
            ),
            foregroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isCancelling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.redAccent,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Cancel Request"),
        ),
      );
    } else if (status == 'approved') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Get Directions",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.backgroundDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "View Details",
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Book Again"),
        ),
      );
    }
  }
}
