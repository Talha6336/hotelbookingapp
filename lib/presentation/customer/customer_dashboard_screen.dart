import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';

import '../widgets/hotel_card.dart';
import 'hotel_detail_screen.dart';
import 'customer_bookings_screen.dart';
import 'profile_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCity = 'All';

  late AnimationController _floatingController;

  final List<String> cities = ['All', 'Faisalabad', 'Lahore', 'Islamabad'];

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getHotelsStream() {
    return FirebaseFirestore.instance
        .collection('hotels')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  List<QueryDocumentSnapshot> filterHotels(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final hotel = doc.data() as Map<String, dynamic>;

      final name = hotel['name']?.toString().toLowerCase() ?? '';
      final city = hotel['city']?.toString() ?? '';
      final cityLower = city.toLowerCase();

      final matchesSearch =
          searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          cityLower.contains(searchQuery.toLowerCase());

      final matchesCity = selectedCity == 'All' || city == selectedCity;

      return matchesSearch && matchesCity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
          ),

          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingCircle(
                    size: 260,
                    top: -80 +
                        (math.sin(_floatingController.value * math.pi) * 30),
                    left: -90,
                    color: AppColors.primary.withOpacity(0.35),
                  ),
                  _buildFloatingCircle(
                    size: 320,
                    bottom: -120 +
                        (math.cos(_floatingController.value * math.pi) * 45),
                    right: -80,
                    color: AppColors.secondary.withOpacity(0.25),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBox(),
                _buildCityFilters(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getHotelsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildMessageState(
                          icon: Icons.error_outline,
                          title: 'Something went wrong',
                          subtitle: 'Please check your Firebase setup.',
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildMessageState(
                          icon: Icons.hotel_outlined,
                          title: 'No hotels available',
                          subtitle: 'Seed dummy hotel data first.',
                        );
                      }

                      final hotels = filterHotels(snapshot.data!.docs);

                      if (hotels.isEmpty) {
                        return _buildMessageState(
                          icon: Icons.search_off,
                          title: 'No hotels found',
                          subtitle: 'Try another city or hotel name.',
                        );
                      }

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 90),
                        children: [
                          _buildSectionTitle(
                            title: 'Featured Hotels',
                            actionText: 'View Map',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Map screen will be added next',
                                  ),
                                ),
                              );
                            },
                          ),

                          _buildFeaturedHotels(hotels),

                          const SizedBox(height: 12),

                          _buildSectionTitle(
                            title: 'Recommended',
                            actionText: '${hotels.length} found',
                            onTap: () {},
                          ),

                          ...hotels.map((doc) {
                            final hotel = doc.data() as Map<String, dynamic>;

                            return PremiumHotelCard(
                              imageUrl: hotel['imageUrl'] ?? '',
                              title: hotel['name'] ?? 'Unknown Hotel',
                              location: hotel['city'] ?? 'Unknown City',
                              price: _toDouble(hotel['pricePerNight']),
                              rating: _toDouble(hotel['rating']),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HotelDetailScreen(
                                      hotelId: doc.id,
                                      hotel: hotel,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: getCurrentUserStream(),
    builder: (context, snapshot) {
      final userData = snapshot.data?.data();

      final String name = userData?['name'] ?? 'Guest';

      // IMPORTANT:
      // Your profile screen uses "profileImage", not "profileImageUrl"
      final String profileImage = userData?['profileImage'] ?? '';

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                    image: profileImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImage.isEmpty
                      ? const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Find your perfect stay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.75),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search hotel or city...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityFilters() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final city = cities[index];
          final isSelected = selectedCity == city;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCity = city;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : Colors.white.withOpacity(0.18),
                ),
              ),
              child: Text(
                city,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.backgroundDark1
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedHotels(List<QueryDocumentSnapshot> hotels) {
    final featuredHotels = hotels.take(3).toList();

    return SizedBox(
      height: 190,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: featuredHotels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final hotel = featuredHotels[index].data() as Map<String, dynamic>;

          return _FeaturedGlassHotelCard(
            imageUrl: hotel['imageUrl'] ?? '',
            title: hotel['name'] ?? 'Unknown Hotel',
            city: hotel['city'] ?? 'Unknown City',
            price: _toDouble(hotel['pricePerNight']),
            rating: _toDouble(hotel['rating']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HotelDetailScreen(
                    hotelId: featuredHotels[index].id,
                    hotel: hotel,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.backgroundDark1,
                AppColors.backgroundDark2,
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.16)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () {},
              ),
              _bottomItem(
                icon: Icons.map_outlined,
                label: 'Map',
                selected: false,
                onTap: () {},
              ),
              _bottomItem(
                icon: Icons.bookmark_border_rounded,
                label: 'Bookings',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerBookingsScreen(),
                    ),
                  );
                },
              ),
              _bottomItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.accent : Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 74, color: AppColors.accent),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class _FeaturedGlassHotelCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String city;
  final double price;
  final double rating;
  final VoidCallback onTap;

  const _FeaturedGlassHotelCard({
    required this.imageUrl,
    required this.title,
    required this.city,
    required this.price,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 235,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl,
                height: 190,
                width: 235,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 190,
                    width: 235,
                    color: Colors.white.withOpacity(0.12),
                    child: const Icon(
                      Icons.hotel,
                      color: Colors.white70,
                      size: 60,
                    ),
                  );
                },
              ),
            ),

            Container(
              height: 190,
              width: 235,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Rs. ${price.toInt()} / night',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}