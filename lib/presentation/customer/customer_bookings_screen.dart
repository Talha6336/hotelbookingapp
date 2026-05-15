import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'booking_screen.dart';
import 'hotel_detail_screen.dart';
import 'single_hotel_map_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CustomerBookingsScreen({super.key, this.onBackToHome});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _selectedTab = 'All';
  String _searchQuery = '';

  Stream<QuerySnapshot>? _bookingsStream;

  final List<String> _tabs = [
    'All',
    'Pending',
    'Approved',
    'Accepted',
    'Completed',
    'Cancelled',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _bookingsStream = _getBookingsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _normalizeStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? '';

    if (status == 'accepted') return 'approved';

    return status;
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int pending = 0;
    int approved = 0;
    int cancelled = 0;
    int completed = 0;
    int rejected = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _normalizeStatus(data['status']);

      if (status == 'pending') pending++;
      if (status == 'approved') approved++;
      if (status == 'cancelled') cancelled++;
      if (status == 'completed') completed++;
      if (status == 'rejected') rejected++;
    }

    return {
      'Total': docs.length,
      'Pending': pending,
      'Approved': approved,
      'Cancelled': cancelled,
      'Completed': completed,
      'Rejected': rejected,
    };
  }

  List<QueryDocumentSnapshot> _filterBookings(
    List<QueryDocumentSnapshot> docs,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final selectedTab = _selectedTab.toLowerCase();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _normalizeStatus(data['status']);

      final matchesTab =
          selectedTab == 'all' ||
          status == selectedTab ||
          (selectedTab == 'accepted' && status == 'approved');

      if (!matchesTab) return false;

      if (query.isEmpty) return true;

      final hotelName = (data['hotelName'] ?? '').toString().toLowerCase();
      final customerName = (data['customerName'] ?? '')
          .toString()
          .toLowerCase();
      final totalPrice = (data['totalPrice'] ?? '').toString().toLowerCase();
      final totalNights = (data['totalNights'] ?? '').toString().toLowerCase();
      final bookingStatus = (data['status'] ?? '').toString().toLowerCase();
      final bookingId = doc.id.toLowerCase();

      return hotelName.contains(query) ||
          customerName.contains(query) ||
          totalPrice.contains(query) ||
          totalNights.contains(query) ||
          bookingStatus.contains(query) ||
          bookingId.contains(query);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _hideKeyboard,
        behavior: HitTestBehavior.translucent,
<<<<<<< Updated upstream
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppColors.darkGradient),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSearchAndFilter(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _bookingsStream ?? _getBookingsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingState();
                        }

                        if (snapshot.hasError) {
                          return _buildKeyboardSafeEmptyState(
                            title: 'Error loading bookings',
                            subtitle: 'Please check your connection.',
                            icon: Icons.error_outline,
                            showButton: false,
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final stats = _calculateStats(docs);
                        final filteredDocs = _filterBookings(docs);

                        return ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom:
                                120 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          children: [
                            if (docs.isNotEmpty) _buildSummaryCards(stats),
                            _buildTabs(),
                            if (docs.isEmpty)
                              _buildKeyboardSafeEmptyState(
                                title: 'No bookings yet',
                                subtitle: 'Start exploring luxury hotels.',
                                icon: Icons.flight_takeoff,
                              )
                            else if (filteredDocs.isEmpty)
                              _buildKeyboardSafeEmptyState(
                                title: _searchQuery.isNotEmpty
                                    ? 'No matching bookings'
                                    : 'No $_selectedTab bookings',
                                subtitle: _searchQuery.isNotEmpty
                                    ? 'Try searching another hotel name, status, price, or booking ID.'
                                    : "You don't have any $_selectedTab reservations.",
                                icon: Icons.search_off,
                                showButton: false,
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: filteredDocs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _PremiumBookingCard(
                                        bookingData: data,
                                        bookingId: doc.id,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
=======
        child: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchAndFilter(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _bookingsStream ?? _getBookingsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (snapshot.hasError) {
                        return _buildKeyboardSafeEmptyState(
                          title: 'Error loading bookings',
                          subtitle: 'Please check your connection.',
                          icon: Icons.error_outline,
                          showButton: false,
>>>>>>> Stashed changes
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final stats = _calculateStats(docs);
                      final filteredDocs = _filterBookings(docs);

                      return ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom:
                              120 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        children: [
                          if (docs.isNotEmpty) _buildSummaryCards(stats),
                          _buildTabs(),
                          if (docs.isEmpty)
                            _buildKeyboardSafeEmptyState(
                              title: 'No bookings yet',
                              subtitle: 'Start exploring luxury hotels.',
                              icon: Icons.flight_takeoff,
                            )
                          else if (filteredDocs.isEmpty)
                            _buildKeyboardSafeEmptyState(
                              title: _searchQuery.isNotEmpty
                                  ? 'No matching bookings'
                                  : 'No $_selectedTab bookings',
                              subtitle: _searchQuery.isNotEmpty
                                  ? 'Try searching another hotel name, status, price, or booking ID.'
                                  : "You don't have any $_selectedTab reservations.",
                              icon: Icons.search_off,
                              showButton: false,
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: filteredDocs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _PremiumBookingCard(
                                      bookingData: data,
                                      bookingId: doc.id,
                                    ),
                                  );
                                }).toList(),
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
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
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
                  _hideKeyboard();

                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bookings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your hotel reservations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _glassSearchCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search your bookings...',
<<<<<<< Updated upstream
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
=======
            hintStyle: TextStyle(
              color: AppColors.adaptiveTextTertiary(context),
            ),
>>>>>>> Stashed changes
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
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _glassSearchCard({
    required Widget child,
    required EdgeInsets padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(16),
<<<<<<< Updated upstream
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
=======
            border: Border.all(color: AppColors.adaptiveBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.adaptiveShadow(context),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
>>>>>>> Stashed changes
          ),
          child: child,
        ),
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
          _buildStatCard('Total', stats['Total'] ?? 0, const Color(0xFF2196F3)),
          _buildStatCard(
            'Pending',
            stats['Pending'] ?? 0,
            const Color(0xFFFF9800),
          ),
          _buildStatCard(
            'Approved',
            stats['Approved'] ?? 0,
            const Color(0xFF4CAF50),
          ),
          _buildStatCard(
            'Cancelled',
            stats['Cancelled'] ?? 0,
            const Color(0xFFF44336),
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
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.adaptiveShadow(context),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
                color: AppColors.adaptiveTextSecondary(context),
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
            onTap: () {
              _hideKeyboard();

              setState(() {
                _selectedTab = tab;
              });
            },
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
                color: isSelected ? null : AppColors.adaptiveSurface(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.adaptiveBorder(context),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
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
                        : AppColors.adaptiveTextSecondary(context),
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

  Widget _buildKeyboardSafeEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    bool showButton = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 45, 26, 45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
<<<<<<< Updated upstream
            Icon(icon, size: 70, color: Colors.white.withValues(alpha: 0.2)),
=======
            Icon(
              icon,
              size: 70,
              color: AppColors.adaptiveTextTertiary(
                context,
              ).withValues(alpha: 0.45),
            ),
>>>>>>> Stashed changes
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 14,
              ),
            ),
            if (showButton) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  _hideKeyboard();

                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.isDark(context)
                      ? AppColors.backgroundDark1
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Explore Hotels',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurfaceMuted(context),
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}

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
  bool _isOpening = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFF44336);
      case 'completed':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';

    if (value is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(value.toDate());
    }

    return value.toString();
  }

  String _getHotelId() {
    return widget.bookingData['hotelId']?.toString() ??
        widget.bookingData['hotel_id']?.toString() ??
        '';
  }

  Map<String, dynamic> _buildFallbackHotelData() {
    return {
      'name': widget.bookingData['hotelName'] ?? 'Unknown Hotel',
      'imageUrl':
          widget.bookingData['hotelImage'] ??
          widget.bookingData['imageUrl'] ??
          '',
      'pricePerNight':
          widget.bookingData['pricePerNight'] ??
          widget.bookingData['roomPrice'] ??
          0,
      'city': widget.bookingData['city'] ?? 'Unknown City',
      'address': widget.bookingData['address'] ?? 'Address not available',
      'latitude': widget.bookingData['latitude'],
      'longitude': widget.bookingData['longitude'],
      'ownerId': widget.bookingData['ownerId'],
      'description':
          widget.bookingData['description'] ?? 'No description available.',
      'rating': widget.bookingData['rating'] ?? 0,
      'amenities': widget.bookingData['amenities'],
    };
  }

  Future<Map<String, dynamic>?> _loadHotelData() async {
    final hotelId = _getHotelId();

    if (hotelId.isEmpty) {
      _showActionSnackBar('Hotel information is missing.');
      return null;
    }

    setState(() {
      _isOpening = true;
    });

    try {
      final fallbackData = _buildFallbackHotelData();

      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .get();

      if (!hotelDoc.exists || hotelDoc.data() == null) {
        return fallbackData;
      }

      return {...fallbackData, ...hotelDoc.data()!};
    } catch (e) {
      _showActionSnackBar('Unable to load hotel details.');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  void _showActionSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openBookingAgain() async {
    final hotelId = _getHotelId();
    final hotelData = await _loadHotelData();

    if (!mounted || hotelData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(hotelId: hotelId, hotel: hotelData),
      ),
    );
  }

  Future<void> _openDirections() async {
    final hotelData = await _loadHotelData();

    if (!mounted || hotelData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
<<<<<<< Updated upstream
        builder: (context) =>
            SingleHotelMapScreen(hotel: hotelData, showRouteInitially: true),
=======
        builder: (context) => SingleHotelMapScreen(hotel: hotelData),
>>>>>>> Stashed changes
      ),
    );
  }

  Future<void> _openHotelDetails() async {
    final hotelId = _getHotelId();
    final hotelData = await _loadHotelData();

    if (!mounted || hotelData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HotelDetailScreen(hotelId: hotelId, hotel: hotelData),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel Booking',
            style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
          ),
          content: Text(
            'Are you sure you want to cancel this booking request?',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Keep Booking',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
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
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

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
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurfaceMuted(context),
        borderRadius: BorderRadius.circular(16),
      ),
<<<<<<< Updated upstream
      child: const Icon(Icons.hotel, color: Colors.white54, size: 32),
=======
      child: Icon(
        Icons.hotel,
        color: AppColors.adaptiveTextTertiary(context),
        size: 32,
      ),
>>>>>>> Stashed changes
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rawStatus =
        widget.bookingData['status']?.toString().toLowerCase() ?? 'pending';

    final String status = rawStatus.toUpperCase();
    final Color statusColor = _getStatusColor(rawStatus);

    final String hotelName = widget.bookingData['hotelName'] ?? 'Luxury Hotel';

    final String hotelImage =
        widget.bookingData['hotelImage'] ??
        widget.bookingData['imageUrl'] ??
        '';

    final num price = widget.bookingData['totalPrice'] ?? 0;
    final int nights = widget.bookingData['totalNights'] ?? 1;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();

        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.adaptiveSurface(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isExpanded
                    ? statusColor.withValues(alpha: 0.5)
                    : AppColors.adaptiveBorder(context),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adaptiveShadow(context),
                  blurRadius: AppColors.isDark(context) ? 24 : 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: hotelImage.toString().isNotEmpty
                            ? Image.network(
                                hotelImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(context);
                                },
                              )
                            : _buildImagePlaceholder(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hotelName,
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextPrimary(
                                        context,
                                      ),
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
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
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
                                '${_formatDate(widget.bookingData['checkInDate'])} - ${_formatDate(widget.bookingData['checkOutDate'])}',
                                style: TextStyle(
                                  color: AppColors.adaptiveTextSecondary(
                                    context,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs. ${price.toInt()} • $nights night(s)',
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
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Divider(
                          color: AppColors.adaptiveBorder(context),
                          height: 24,
                        ),
                        _buildDetailRow('Booking ID', widget.bookingId),
                        _buildDetailRow(
                          'Guest Name',
                          widget.bookingData['customerName'] ?? 'N/A',
                        ),
                        _buildDetailRow('Payment Status', 'Pay at Hotel'),
                        const SizedBox(height: 16),
                        _buildActionButtons(rawStatus),
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
              color: AppColors.adaptiveTextSecondary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
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
    if (_isOpening) {
      return SizedBox(
        height: 42,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: AppColors.adaptiveSurfaceMuted(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

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
              : const Text('Cancel Request'),
        ),
      );
    } else if (status == 'approved' || status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openDirections,
              style: OutlinedButton.styleFrom(
<<<<<<< Updated upstream
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                foregroundColor: Colors.white,
=======
                side: BorderSide(color: AppColors.adaptiveBorder(context)),
                foregroundColor: AppColors.adaptiveTextPrimary(context),
>>>>>>> Stashed changes
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Directions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _openHotelDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.isDark(context)
                    ? AppColors.backgroundDark1
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Details',
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
          onPressed: _openBookingAgain,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.adaptiveSurfaceMuted(context),
            foregroundColor: AppColors.adaptiveTextPrimary(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Book Again'),
        ),
      );
    }
  }
}
