import 'booking_screen.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'single_hotel_map_screen.dart';

class HotelDetailScreen extends StatelessWidget {
  final String hotelId;
  final Map<String, dynamic> hotel;

  const HotelDetailScreen({
    super.key,
    required this.hotelId,
    required this.hotel,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  List<String> _getAmenitiesList(dynamic value) {
    if (value == null) {
      return [
        'Room Service',
        'Restaurant',
        'Free WiFi',
        'Air Conditioning',
        'Parking',
      ];
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [
      'Room Service',
      'Restaurant',
      'Free WiFi',
      'Air Conditioning',
      'Parking',
    ];
  }

  IconData _getAmenityIcon(String amenity) {
    final text = amenity.toLowerCase();

    if (text.contains('wifi') || text.contains('internet')) {
      return Icons.wifi_rounded;
    }

    if (text.contains('parking')) {
      return Icons.local_parking_rounded;
    }

    if (text.contains('restaurant') ||
        text.contains('food') ||
        text.contains('breakfast')) {
      return Icons.restaurant_rounded;
    }

    if (text.contains('air') ||
        text.contains('ac') ||
        text.contains('conditioning')) {
      return Icons.ac_unit_rounded;
    }

    if (text.contains('pool') || text.contains('swimming')) {
      return Icons.pool_rounded;
    }

    if (text.contains('spa')) {
      return Icons.spa_rounded;
    }

    if (text.contains('room service')) {
      return Icons.room_service_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = hotel['imageUrl'] ?? '';
    final String name = hotel['name'] ?? 'Unknown Hotel';
    final String city = hotel['city'] ?? 'Unknown City';
    final String address = hotel['address'] ?? 'Address not available';
    final String description =
        hotel['description'] ?? 'No description available.';
    final double price = _toDouble(hotel['pricePerNight']);
    final double rating = _toDouble(hotel['rating']);

    final List<String> amenities = _getAmenitiesList(hotel['amenities']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                cacheExtent: 700,
                slivers: [
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _buildImageHeader(
                        context: context,
                        imageUrl: imageUrl,
                        rating: rating,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHotelTitle(
                            context: context,
                            name: name,
                            city: city,
                            price: price,
                          ),
                          const SizedBox(height: 18),
                          _buildInfoCard(
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.location_on_outlined,
                                  title: 'Address',
                                  value: address,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  context: context,
                                  icon: Icons.location_city_outlined,
                                  title: 'City',
                                  value: city,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionTitle(context, 'Description'),
                          const SizedBox(height: 10),
                          _buildInfoCard(
                            context: context,
                            child: Text(
                              description,
                              style: TextStyle(
                                color: AppColors.adaptiveTextSecondary(context),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionTitle(context, 'Location'),
                          const SizedBox(height: 10),
                          _buildMapPreview(context),
                          const SizedBox(height: 20),
                          _buildSectionTitle(context, 'Amenities'),
                          const SizedBox(height: 10),
                          _buildFacilities(context, amenities),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBookingBar(context: context, price: price),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader({
    required BuildContext context,
    required String imageUrl,
    required double rating,
  }) {
    final bool isDark = _isDark(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: Image.network(
            imageUrl,
            height: 330,
            width: double.infinity,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 330,
                width: double.infinity,
                color: AppColors.adaptiveSurface(context),
                child: Icon(
                  Icons.hotel_rounded,
                  size: 80,
                  color: AppColors.adaptiveTextTertiary(context),
                ),
              );
            },
          ),
        ),
        Container(
          height: 330,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: isDark ? 0.45 : 0.28),
                Colors.transparent,
                Colors.black.withValues(alpha: isDark ? 0.75 : 0.55),
              ],
            ),
          ),
        ),
        Positioned(
          top: 18,
          left: 18,
          child: _circleButton(
            context: context,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ),
        Positioned(
          bottom: 22,
          right: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHotelTitle({
    required BuildContext context,
    required String name,
    required String city,
    required double price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      city,
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${price.toInt()}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '/ night',
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark(context) ? 0.20 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.adaptiveTextPrimary(context),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return _buildInfoCard(
      context: context,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.adaptiveSurface(context),
          border: Border.all(color: AppColors.adaptiveBorder(context)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.map_outlined,
                size: 72,
                color: AppColors.adaptiveTextTertiary(context),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SingleHotelMapScreen(hotel: hotel),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'View on Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilities(BuildContext context, List<String> amenities) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: amenities
          .map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.adaptiveSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.adaptiveBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isDark(context) ? 0.18 : 0.05,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAmenityIcon(amenity),
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amenity,
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildBottomBookingBar({
    required BuildContext context,
    required double price,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Rs. ${price.toInt()}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '\nTotal per night',
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingScreen(hotelId: hotelId, hotel: hotel),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
