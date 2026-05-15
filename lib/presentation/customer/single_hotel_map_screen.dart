import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';

class SingleHotelMapScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final bool showRouteInitially;

  const SingleHotelMapScreen({
    super.key,
    required this.hotel,
    this.showRouteInitially = false,
  });

  @override
  State<SingleHotelMapScreen> createState() => _SingleHotelMapScreenState();
}

class _SingleHotelMapScreenState extends State<SingleHotelMapScreen> {
  final MapController _mapController = MapController();

  late bool _hasLocation;
  late LatLng _hotelPosition;
  LatLng? _userLocation;

  bool _isLoadingRoute = false;
  List<LatLng> _routePoints = [];
  String _routeDistance = '';
  String _routeDuration = '';

  @override
  void initState() {
    super.initState();

    final double latitude = _toDouble(widget.hotel['latitude']);
    final double longitude = _toDouble(widget.hotel['longitude']);

    _hasLocation = latitude != 0.0 && longitude != 0.0;
    _hotelPosition = LatLng(latitude, longitude);

    if (_hasLocation && widget.showRouteInitially) {
      _fetchRoute();
    } else if (_hasLocation) {
      _getUserLocationSilent();
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Gets user location just to show the blue dot, without triggering a route
  Future<void> _getUserLocationSilent() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Fail silently if we are just trying to show the blue dot
    }
  }

  // ===========================================================================
  // ROUTING ENGINE (OSRM API)
  // ===========================================================================
  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      // 1. Get user location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Please enable Location Services to get directions.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final startLat = position.latitude;
      final startLng = position.longitude;
      final endLat = _hotelPosition.latitude;
      final endLng = _hotelPosition.longitude;

      setState(() {
        _userLocation = LatLng(startLat, startLng);
      });

      // 2. Call Free OSRM API
      final url =
          'http://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?geometries=geojson&overview=full';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];

        // Decode coordinates
        final List coords = route['geometry']['coordinates'];
        final List<LatLng> points = coords
            .map((c) => LatLng(c[1], c[0]))
            .toList();

        // Get Distance and Duration
        final double distanceMeters = route['distance'];
        final double durationSeconds = route['duration'];

        setState(() {
          _routePoints = points;
          _routeDistance = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
          _routeDuration = '${(durationSeconds / 60).toStringAsFixed(0)} min';
        });

        // 3. Zoom the camera to fit both the User and the Hotel!
        if (_routePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(
                top: 100,
                bottom: 250,
                left: 60,
                right: 60,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Could not calculate route. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String hotelName = widget.hotel['name'] ?? 'Unknown Hotel';
    final String city = widget.hotel['city'] ?? 'Unknown City';
    final String address = widget.hotel['address'] ?? 'Address not available';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                _buildTopBar(context, hotelName, city),

                const SizedBox(height: 18),

                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _hasLocation
                        ? Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _hotelPosition,
                                  initialZoom: 15,
                                ),
                                children: [
                                  // Map Tiles adapt to Light/Dark mode
                                  TileLayer(
                                    urlTemplate: isDark
                                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                    subdomains: const ['a', 'b', 'c', 'd'],
                                    userAgentPackageName:
                                        'com.example.hotelbookingapp',
                                  ),

                                  // THE ROUTE PATH (Bright Blue Line)
                                  if (_routePoints.isNotEmpty)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _routePoints,
                                          strokeWidth: 5.0,
                                          color: Colors.blueAccent,
                                        ),
                                      ],
                                    ),

                                  // MARKERS (Hotel & User)
                                  MarkerLayer(
                                    markers: [
                                      // Hotel Marker
                                      Marker(
                                        point: _hotelPosition,
                                        width: 52,
                                        height: 52,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.adaptiveSurface(
                                                context,
                                              ),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.hotel_rounded,
                                            color: AppColors.adaptiveSurface(
                                              context,
                                            ),
                                            size: 26,
                                          ),
                                        ),
                                      ),

                                      // User Marker (Blue Dot)
                                      if (_userLocation != null)
                                        Marker(
                                          point: _userLocation!,
                                          width: 30,
                                          height: 30,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              // Bottom Adaptive Info Card
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: _buildHotelInfoCard(
                                  context,
                                  hotelName: hotelName,
                                  city: city,
                                  address: address,
                                ),
                              ),
                            ],
                          )
                        : _buildNoLocationCard(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String hotelName, String city) {
    return Row(
      children: [
        _circleGlassButton(
          context,
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hotel Location',
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$hotelName, $city',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotelInfoCard(
    BuildContext context, {
    required String hotelName,
    required String city,
    required String address,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.adaptiveBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.adaptiveTextPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          city,
                          style: TextStyle(
                            color: AppColors.adaptiveTextSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.adaptiveTextTertiary(context),
                  fontSize: 13,
                ),
              ),

              // Routing Information Panel
              if (_routePoints.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: AppColors.adaptiveBorder(context)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRouteInfoBox(
                      context,
                      Icons.directions_car_rounded,
                      'Drive',
                      _routeDuration,
                    ),
                    _buildRouteInfoBox(
                      context,
                      Icons.straighten_rounded,
                      'Distance',
                      _routeDistance,
                    ),
                  ],
                ),
              ],

              // Get Directions Button
              if (_routePoints.isEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingRoute ? null : _fetchRoute,
                    icon: _isLoadingRoute
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.adaptiveBackground(context),
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.directions_rounded,
                            color: AppColors.adaptiveBackground(context),
                          ),
                    label: Text(
                      _isLoadingRoute ? 'Calculating...' : 'Get Directions',
                      style: TextStyle(
                        color: AppColors.adaptiveBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoBox(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.adaptiveTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNoLocationCard(BuildContext context) {
    return Container(
      color: AppColors.adaptiveBackground(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: AppColors.adaptiveSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.adaptiveBorder(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      color: AppColors.accent,
                      size: 70,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Location not available',
                      style: TextStyle(
                        color: AppColors.adaptiveTextPrimary(context),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This hotel does not have latitude and longitude saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleGlassButton(
    BuildContext context, {
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
              color: AppColors.adaptiveSurface(context).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.adaptiveBorder(context)),
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
}
