import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../notifications/notification_service.dart';

class BookingScreen extends StatefulWidget {
  final String hotelId;
  final Map<String, dynamic> hotel;

  const BookingScreen({super.key, required this.hotelId, required this.hotel});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  bool isLoading = false;

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  int get totalNights {
    if (checkInDate == null || checkOutDate == null) return 0;

    final nights = checkOutDate!.difference(checkInDate!).inDays;

    if (nights <= 0) return 0;

    return nights;
  }

  double get totalPrice {
    final pricePerNight = _toDouble(widget.hotel['pricePerNight']);
    return pricePerNight * totalNights;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickCheckInDate() async {
    final today = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: checkInDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 1),
      builder: _datePickerTheme,
    );

    if (pickedDate != null) {
      setState(() {
        checkInDate = pickedDate;

        if (checkOutDate != null && !checkOutDate!.isAfter(checkInDate!)) {
          checkOutDate = null;
        }
      });
    }
  }

  Future<void> _pickCheckOutDate() async {
    if (checkInDate == null) {
      _showSnackBar('Please select check-in date first.');
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: checkOutDate ?? checkInDate!.add(const Duration(days: 1)),
      firstDate: checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime(checkInDate!.year + 1),
      builder: _datePickerTheme,
    );

    if (pickedDate != null) {
      setState(() {
        checkOutDate = pickedDate;
      });
    }
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    final isDark = _isDark(context);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: isDark
            ? const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.backgroundDark1,
                onSurface: Colors.white,
              )
            : const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
      ),
      child: child!,
    );
  }

  Future<void> _confirmBooking() async {
    if (checkInDate == null || checkOutDate == null) {
      _showSnackBar('Please select check-in and check-out dates.');
      return;
    }

    if (totalNights <= 0) {
      _showSnackBar('Check-out date must be after check-in date.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('Please login first.');
      return;
    }

    final String ownerId = widget.hotel['ownerId']?.toString() ?? '';

    if (ownerId.isEmpty) {
      _showSnackBar('Hotel owner information is missing.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String customerName = 'Customer';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        customerName = userData?['name'] ?? 'Customer';
      }

      final String hotelName = widget.hotel['name'] ?? 'Unknown Hotel';

      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'userId': currentUser.uid,
            'customerId': currentUser.uid,
            'ownerId': ownerId,
            'hotelId': widget.hotelId,
            'hotelName': hotelName,
            'hotelImage': widget.hotel['imageUrl'] ?? '',
            'customerName': customerName,
            'checkInDate': Timestamp.fromDate(checkInDate!),
            'checkOutDate': Timestamp.fromDate(checkOutDate!),
            'totalNights': totalNights,
            'totalPrice': totalPrice,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      await NotificationService.notifyOwnerNewBooking(
        ownerId: ownerId,
        bookingId: bookingRef.id,
        hotelId: widget.hotelId,
        hotelName: hotelName,
        customerName: customerName,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      _showSnackBar('Booking failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Booking Requested',
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Your booking request has been sent to the hotel owner. Status: pending.',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String hotelName = widget.hotel['name'] ?? 'Unknown Hotel';
    final String city = widget.hotel['city'] ?? 'Unknown City';
    final String imageUrl = widget.hotel['imageUrl'] ?? '';
    final double pricePerNight = _toDouble(widget.hotel['pricePerNight']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 22),
                    Text(
                      'Confirm Booking',
                      style: TextStyle(
                        color: AppColors.adaptiveTextPrimary(context),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your stay dates and send request to hotel owner.',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildHotelSummaryCard(
                      context: context,
                      imageUrl: imageUrl,
                      hotelName: hotelName,
                      city: city,
                      pricePerNight: pricePerNight,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Stay Dates'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateCard(
                            context: context,
                            title: 'Check-in',
                            value: _formatDate(checkInDate),
                            icon: Icons.login_rounded,
                            onTap: _pickCheckInDate,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildDateCard(
                            context: context,
                            title: 'Check-out',
                            value: _formatDate(checkOutDate),
                            icon: Icons.logout_rounded,
                            onTap: _pickCheckOutDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Payment Summary'),
                    const SizedBox(height: 12),
                    _buildPriceSummary(
                      context: context,
                      pricePerNight: pricePerNight,
                      nights: totalNights,
                      total: totalPrice,
                    ),
                    const SizedBox(height: 24),
                    _buildNoteBox(context),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
          ],
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
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        _circleGlassButton(
          context: context,
          icon: Icons.bookmark_border_rounded,
          onTap: () {},
        ),
      ],
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
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.adaptiveSurface(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDark(context) ? 0.22 : 0.06,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
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

  Widget _buildHotelSummaryCard({
    required BuildContext context,
    required String imageUrl,
    required String hotelName,
    required String city,
    required double pricePerNight,
  }) {
    return _glassCard(
      context: context,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              imageUrl,
              height: 105,
              width: 105,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 105,
                  width: 105,
                  color: AppColors.adaptiveSurface(context),
                  child: Icon(
                    Icons.hotel_rounded,
                    color: AppColors.adaptiveTextTertiary(context),
                    size: 42,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city,
                        style: TextStyle(
                          color: AppColors.adaptiveTextSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Rs. ${pricePerNight.toInt()} / night',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.adaptiveTextPrimary(context),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildDateCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _glassCard(
        context: context,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 26),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary({
    required BuildContext context,
    required double pricePerNight,
    required int nights,
    required double total,
  }) {
    return _glassCard(
      context: context,
      child: Column(
        children: [
          _summaryRow(
            context: context,
            title: 'Price per night',
            value: 'Rs. ${pricePerNight.toInt()}',
          ),
          const SizedBox(height: 14),
          _summaryRow(
            context: context,
            title: 'Total nights',
            value: '$nights',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.adaptiveBorder(context)),
          ),
          _summaryRow(
            context: context,
            title: 'Total amount',
            value: 'Rs. ${total.toInt()}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required BuildContext context,
    required String title,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isTotal
                  ? AppColors.adaptiveTextPrimary(context)
                  : AppColors.adaptiveTextSecondary(context),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal
                ? AppColors.accent
                : AppColors.adaptiveTextPrimary(context),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBox(BuildContext context) {
    return _glassCard(
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a booking request. The hotel owner will accept or reject your request.',
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isDark(context) ? 0.22 : 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
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
              color: AppColors.adaptiveSurface(context),
              border: Border(
                top: BorderSide(color: AppColors.adaptiveBorder(context)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDark(context) ? 0.35 : 0.10,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: 0.55,
                  ),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
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
