import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String role;
  final String type;
  final String title;
  final String message;
  final String? bookingId;
  final String? hotelId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.role,
    required this.type,
    required this.title,
    required this.message,
    this.bookingId,
    this.hotelId,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AppNotification(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      type: data['type']?.toString() ?? 'general',
      title: data['title']?.toString() ?? 'Notification',
      message: data['message']?.toString() ?? '',
      bookingId: data['bookingId']?.toString(),
      hotelId: data['hotelId']?.toString(),
      isRead: data['isRead'] == true,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}