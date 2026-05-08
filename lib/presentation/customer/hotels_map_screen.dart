import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'hotel_detail_screen.dart';

class HotelsMapScreen extends StatefulWidget {
  const HotelsMapScreen({super.key});

  @override
  State<HotelsMapScreen> createState() => _HotelsMapScreenState();
}

class _HotelsMapScreenState extends State<HotelsMapScreen> {
  final MapController mapController = MapController();

  bool isLoading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hotelDocs = [];

  final LatLng initialCenter = const LatLng(31.4504, 73.1350);

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _loadHotels() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('hotels').get();

      if (!mounted) return;

      setState(() {
        hotelDocs = snapshot.docs;
        isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 400), _fitAllHotels);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading hotels: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<Marker> _buildMarkers() {
    return hotelDocs.map((doc) {
      final hotel = doc.data();

      final double latitude = _toDouble(hotel['latitude']);
      final double longitude = _toDouble(hotel['longitude']);

      if (latitude == 0.0 || longitude == 0.0) {
        return null;
      }

      return Marker(
        point: LatLng(latitude, longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            _showHotelBottomSheet(
              hotelId: doc.id,
              hotel: hotel,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.backgroundDark1,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.hotel_rounded,
              color: AppColors.backgroundDark1,
              size: 24,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _fitAllHotels() {
    final validPositions = hotelDocs.map((doc) {
      final hotel = doc.data();

      final double latitude = _toDouble(hotel['latitude']);
      final double longitude = _toDouble(hotel['longitude']);

      if (latitude == 0.0 || longitude == 0.0) return null;

      return LatLng(latitude, longitude);
    }).whereType<LatLng>().toList();

    if (validPositions.isEmpty) return;

    if (validPositions.length == 1) {
      mapController.move(validPositions.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(validPositions);

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _showHotelBottomSheet({
    required String hotelId,
    required Map<String, dynamic> hotel,
  }) {
    final String name = hotel['name'] ?? 'Unknown Hotel';
    final String city = hotel['city'] ?? 'Unknown City';
    final String imageUrl = hotel['imageUrl'] ?? '';
    final num price = hotel['pricePerNight'] ?? 0;
    final num rating = hotel['rating'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark1.withOpacity(0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
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
                            color: Colors.white.withOpacity(0.10),
                            child: const Icon(
                              Icons.hotel,
                              color: Colors.white70,
                              size: 42,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

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
                                    color: Colors.white.withOpacity(0.70),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Rs. ${price.toInt()}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HotelDetailScreen(
                                      hotelId: hotelId,
                                      hotel: hotel,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.backgroundDark1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                _buildTopBar(context),

                const SizedBox(height: 18),

                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: 11,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.example.hotelbookingapp',
                            ),
                            MarkerLayer(
                              markers: markers,
                            ),
                          ],
                        ),

                        if (isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.20),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            ),
                          ),

                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Column(
                            children: [
                              _mapButton(
                                icon: Icons.refresh_rounded,
                                onTap: _loadHotels,
                              ),
                              const SizedBox(height: 10),
                              _mapButton(
                                icon: Icons.fit_screen_rounded,
                                onTap: _fitAllHotels,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hotels Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Explore hotels by location',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        _circleGlassButton(
          icon: Icons.my_location_rounded,
          onTap: _fitAllHotels,
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
              color: Colors.white.withOpacity(0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
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

  Widget _mapButton({
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
              color: AppColors.backgroundDark1.withOpacity(0.88),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.accent,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}