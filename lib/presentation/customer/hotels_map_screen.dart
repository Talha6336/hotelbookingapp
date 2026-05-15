import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // <-- ADDED GEOLOCATOR

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'hotel_detail_screen.dart';

class HotelsMapScreen extends StatefulWidget {
  final VoidCallback onBackToHome;
  const HotelsMapScreen({super.key, required this.onBackToHome});

  @override
  State<HotelsMapScreen> createState() => _HotelsMapScreenState();
}

class _HotelsMapScreenState extends State<HotelsMapScreen> {
  final MapController mapController = MapController();

  bool isLoading = true;
  bool isGettingLocation = false; // <-- Tracks GPS loading state
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hotelDocs = [];

  final LatLng initialCenter = const LatLng(31.4504, 73.1350);
  LatLng? currentUserLocation; // <-- Stores the user's actual location

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

  // ===========================================================================
  // NEW: GET CURRENT LOCATION LOGIC
  // ===========================================================================
  Future<void> _getCurrentLocation() async {
    setState(() => isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // --- THE UPGRADE: Interactive Error Message ---
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are turned off.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            // Adds a button right inside the error to open phone settings!
            action: SnackBarAction(
              label: 'TURN ON',
              textColor: Colors.white,
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        setState(() => isGettingLocation = false);
        return;
      }
      // ----------------------------------------------

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar("Location permissions denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar("Location permissions permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        currentUserLocation = newLatLng;
      });

      // Fly the map to the user's location smoothly
      mapController.move(newLatLng, 14.0);
    } catch (e) {
      _showErrorSnackBar("Failed to get location: $e");
    } finally {
      if (mounted) setState(() => isGettingLocation = false);
    }
  }

  Future<void> _loadHotels() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .get();

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

      _showErrorSnackBar('Error loading hotels: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  List<Marker> _buildMarkers() {
    // 1. Build Hotel Markers
    List<Marker> allMarkers = hotelDocs
        .map((doc) {
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
                _showHotelBottomSheet(hotelId: doc.id, hotel: hotel);
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
                      color: Colors.black.withValues(alpha: 0.25),
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
        })
        .whereType<Marker>()
        .toList();

    // 2. Build Current User Marker (Blue Dot) if location is known
    if (currentUserLocation != null) {
      allMarkers.add(
        Marker(
          point: currentUserLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return allMarkers;
  }

  void _fitAllHotels() {
    final validPositions = hotelDocs
        .map((doc) {
          final hotel = doc.data();

          final double latitude = _toDouble(hotel['latitude']);
          final double longitude = _toDouble(hotel['longitude']);

          if (latitude == 0.0 || longitude == 0.0) return null;

          return LatLng(latitude, longitude);
        })
        .whereType<LatLng>()
        .toList();

    if (validPositions.isEmpty) return;

    if (validPositions.length == 1) {
      mapController.move(validPositions.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(validPositions);

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.adaptiveSurface(
                  context,
                ).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.adaptiveBorder(context)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.adaptiveShadow(context),
                    blurRadius: 28,
                    offset: const Offset(0, -10),
                  ),
                ],
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
                            color: AppColors.adaptiveSurfaceMuted(context),
                            child: Icon(
                              Icons.hotel,
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.adaptiveTextPrimary(context),
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
                                    color: AppColors.adaptiveTextSecondary(
                                      context,
                                    ),
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
                                style: TextStyle(
                                  color: AppColors.adaptiveTextPrimary(context),
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
                                foregroundColor: AppColors.isDark(context)
                                    ? AppColors.backgroundDark1
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.adaptiveBorder(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.adaptiveShadow(context),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
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
                                userAgentPackageName:
                                    'com.example.hotelbookingapp',
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),

                          if (isLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.20),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
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
          onTap: () {
            widget.onBackToHome();
          },
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hotels Map',
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Explore hotels by location',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // NEW: Location Button with loading state
        _circleGlassButton(
          context: context,
          icon: Icons.my_location_rounded,
          onTap: _getCurrentLocation,
          isLoading: isGettingLocation,
        ),
      ],
    );
  }

  Widget _circleGlassButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false, // <-- Added loading state support
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.adaptiveGlass(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveGlassBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adaptiveShadow(context),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: AppColors.adaptiveTextPrimary(context),
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    icon,
                    color: AppColors.adaptiveTextPrimary(context),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
