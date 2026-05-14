import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _ref {
    return _firestore.collection('notifications');
  }

  static Stream<List<AppNotification>> getUserNotifications({
    required String userId,
  }) {
    return _ref.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        return AppNotification.fromDoc(doc);
      }).toList();

      notifications.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return notifications;
    });
  }

  static Stream<int> getUnreadCount({
    required String userId,
  }) {
    return _ref.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] == false;
      }).length;
    });
  }

  static Future<void> markAsRead(String notificationId) async {
    await _ref.doc(notificationId).update({
      'isRead': true,
    });
  }

  static Future<void> markAllAsRead({
    required String userId,
  }) async {
    final snapshot = await _ref.where('userId', isEqualTo: userId).get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['isRead'] == false) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }
    }

    await batch.commit();
  }

  static Future<void> createNotification({
    required String userId,
    required String role,
    required String type,
    required String title,
    required String message,
    String? bookingId,
    String? hotelId,
  }) async {
    await _ref.add({
      'userId': userId,
      'role': role,
      'type': type,
      'title': title,
      'message': message,
      'bookingId': bookingId,
      'hotelId': hotelId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifyOwnerNewBooking({
    required String ownerId,
    required String bookingId,
    required String hotelId,
    required String hotelName,
    required String customerName,
  }) async {
    await createNotification(
      userId: ownerId,
      role: 'owner',
      type: 'booking_pending',
      title: 'New Booking Request',
      message: '$customerName booked $hotelName. Please approve or reject it.',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  static Future<void> notifyCustomerBookingApproved({
    required String customerId,
    required String bookingId,
    required String hotelId,
    required String hotelName,
  }) async {
    await createNotification(
      userId: customerId,
      role: 'customer',
      type: 'booking_approved',
      title: 'Booking Approved',
      message: 'Your booking for $hotelName has been accepted.',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }

  static Future<void> notifyCustomerBookingRejected({
    required String customerId,
    required String bookingId,
    required String hotelId,
    required String hotelName,
    String? reason,
  }) async {
    await createNotification(
      userId: customerId,
      role: 'customer',
      type: 'booking_rejected',
      title: 'Booking Rejected',
      message: reason == null || reason.trim().isEmpty
          ? 'Your booking for $hotelName has been rejected.'
          : 'Your booking for $hotelName has been rejected. Reason: $reason',
      bookingId: bookingId,
      hotelId: hotelId,
    );
  }
}