import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../notifications/notification_service.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _ownerBookingsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortBookingsNewestFirst(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sortedBookings = [...docs];

    sortedBookings.sort((a, b) {
      final aCreatedAt = a.data()['createdAt'];
      final bCreatedAt = b.data()['createdAt'];

      if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
        return bCreatedAt.compareTo(aCreatedAt);
      }

      if (aCreatedAt == null && bCreatedAt != null) {
        return 1;
      }

      if (aCreatedAt != null && bCreatedAt == null) {
        return -1;
      }

      return 0;
    });

    return sortedBookings;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'cancelled':
        return Colors.orangeAccent;
      default:
        return AppColors.accent;
    }
  }

  Future<void> _updateBookingStatus({
    required BuildContext context,
    required String bookingId,
    required String status,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final bookingRef = firestore.collection('bookings').doc(bookingId);
      final bookingSnapshot = await bookingRef.get();

      if (!bookingSnapshot.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingSnapshot.data();

      if (bookingData == null) {
        throw Exception('Booking data is empty');
      }

      final String customerId =
          bookingData['customerId']?.toString() ??
          bookingData['userId']?.toString() ??
          '';

      final String hotelId = bookingData['hotelId']?.toString() ?? '';
      final String hotelName =
          bookingData['hotelName']?.toString() ?? 'Unknown Hotel';

      if (customerId.isEmpty) {
        throw Exception('Customer ID is missing in booking');
      }

      await bookingRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'accepted') {
        await NotificationService.notifyCustomerBookingApproved(
          customerId: customerId,
          bookingId: bookingId,
          hotelId: hotelId,
          hotelName: hotelName,
        );
      } else if (status == 'rejected') {
        await NotificationService.notifyCustomerBookingRejected(
          customerId: customerId,
          bookingId: bookingId,
          hotelId: hotelId,
          hotelName: hotelName,
          reason: null,
        );
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmAction({
    required BuildContext context,
    required String bookingId,
    required String status,
  }) async {
    final bool isAccept = status == 'accepted';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isAccept ? 'Accept Booking?' : 'Reject Booking?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isAccept
                ? 'Are you sure you want to accept this booking request?'
                : 'Are you sure you want to reject this booking request?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
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
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _updateBookingStatus(
                  context: context,
                  bookingId: bookingId,
                  status: status,
                );
              },
              child: Text(
                isAccept ? 'Accept' : 'Reject',
                style: TextStyle(
                  color: isAccept ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),

                const SizedBox(height: 26),

                const Text(
                  'Booking Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Accept or reject customer booking requests.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: currentUser == null
                      ? _buildMessageState(
                          icon: Icons.login_rounded,
                          title: 'Login required',
                          subtitle: 'Please login as owner first.',
                        )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _ownerBookingsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              debugPrint(
                                'Owner bookings error: ${snapshot.error}',
                              );

                              return _buildMessageState(
                                icon: Icons.error_outline,
                                title: 'Something went wrong',
                                subtitle:
                                    'Could not load booking requests right now.',
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return _buildMessageState(
                                icon: Icons.event_busy_rounded,
                                title: 'No booking requests',
                                subtitle:
                                    'Customer booking requests will appear here.',
                              );
                            }

                            final bookings = _sortBookingsNewestFirst(
                              snapshot.data!.docs,
                            );

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final doc = bookings[index];
                                final booking = doc.data();

                                return _buildBookingCard(
                                  context: context,
                                  bookingId: doc.id,
                                  booking: booking,
                                );
                              },
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _circleGlassButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        _circleGlassButton(
          icon: Icons.refresh_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required String bookingId,
    required Map<String, dynamic> booking,
  }) {
    final String hotelName = booking['hotelName'] ?? 'Unknown Hotel';
    final String customerName = booking['customerName'] ?? 'Unknown Customer';
    final String status = booking['status'] ?? 'pending';
    final int totalNights = booking['totalNights'] ?? 0;
    final num totalPrice = booking['totalPrice'] ?? 0;

    return _glassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hotel_rounded,
                color: AppColors.accent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hotelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(status),
            ],
          ),

          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.person_outline_rounded,
            title: 'Customer',
            value: customerName,
          ),

          const SizedBox(height: 10),

          _infoRow(
            icon: Icons.login_rounded,
            title: 'Check-in',
            value: _formatDate(booking['checkInDate']),
          ),

          const SizedBox(height: 10),

          _infoRow(
            icon: Icons.logout_rounded,
            title: 'Check-out',
            value: _formatDate(booking['checkOutDate']),
          ),

          const SizedBox(height: 10),

          _infoRow(
            icon: Icons.night_shelter_rounded,
            title: 'Total nights',
            value: '$totalNights',
          ),

          const SizedBox(height: 10),

          _infoRow(
            icon: Icons.payments_rounded,
            title: 'Total price',
            value: 'Rs. ${totalPrice.toInt()}',
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _confirmAction(
                        context: context,
                        bookingId: bookingId,
                        status: 'rejected',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmAction(
                        context: context,
                        bookingId: bookingId,
                        status: 'accepted',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.backgroundDark1,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
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
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.75),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
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
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
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
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}