import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';

import '../widgets/hotel_card.dart';
import '../notifications/notification_button.dart';

import 'hotel_detail_screen.dart';
import 'customer_bookings_screen.dart';
import 'profile_screen.dart';
import 'hotels_map_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final TextEditingController searchController = TextEditingController();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _hotelsStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  Timer? _searchDebounce;

  String searchQuery = '';
  String selectedCity = 'All';

  final List<String> cities = const [
    'All',
    'Faisalabad',
    'Lahore',
    'Islamabad',
  ];

  @override
  void initState() {
    super.initState();

    _hotelsStream = FirebaseFirestore.instance
        .collection('hotels')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    _userStream = uid == null
        ? const Stream.empty()
        : FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterHotels(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = searchQuery.trim().toLowerCase();

    return docs.where((doc) {
      final hotel = doc.data();

      final name = hotel['name']?.toString().toLowerCase() ?? '';
      final city = hotel['city']?.toString() ?? '';
      final cityLower = city.toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || cityLower.contains(query);

      final matchesCity = selectedCity == 'All' || city == selectedCity;

      return matchesSearch && matchesCity;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark1,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
            child: SizedBox.expand(),
          ),

          const _StaticGlowBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBox(),
                _buildCityFilters(),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _hotelsStream,
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

                      final allDocs = snapshot.data?.docs ?? [];

                      if (allDocs.isEmpty) {
                        return _buildMessageState(
                          icon: Icons.hotel_outlined,
                          title: 'No hotels available',
                          subtitle: 'Seed dummy hotel data first.',
                        );
                      }

                      final hotels = filterHotels(allDocs);

                      if (hotels.isEmpty) {
                        return _buildMessageState(
                          icon: Icons.search_off,
                          title: 'No hotels found',
                          subtitle: 'Try another city or hotel name.',
                        );
                      }

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: 700,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildSectionTitle(
                              title: 'Featured Hotels',
                              actionText: 'View Map',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HotelsMapScreen(),
                                  ),
                                );
                              },
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: _buildFeaturedHotels(hotels),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 12),
                          ),

                          SliverToBoxAdapter(
                            child: _buildSectionTitle(
                              title: 'Recommended',
                              actionText: '${hotels.length} found',
                              onTap: () {},
                            ),
                          ),

                          SliverList.builder(
                            itemCount: hotels.length,
                            itemBuilder: (context, index) {
                              final doc = hotels[index];
                              final hotel = doc.data();

                              return RepaintBoundary(
                                child: PremiumHotelCard(
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
                                ),
                              );
                            },
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 90),
                          ),
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
      stream: _userStream,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();

        final String name = userData?['name'] ?? 'Guest';
        final String profileImage = userData?['profileImage'] ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: profileImage.isNotEmpty
                    ? Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.white,
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

              const NotificationButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  _searchDebounce?.cancel();

                  _searchDebounce = Timer(
                    const Duration(milliseconds: 250),
                    () {
                      if (!mounted) return;

                      setState(() {
                        searchQuery = value;
                      });
                    },
                  );
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
                  _searchDebounce?.cancel();
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
              if (selectedCity == city) return;

              setState(() {
                selectedCity = city;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
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
                  color:
                      isSelected ? AppColors.backgroundDark1 : Colors.white,
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

  Widget _buildFeaturedHotels(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> hotels,
  ) {
    final featuredHotels = hotels.take(3).toList(growable: false);

    return SizedBox(
      height: 190,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        cacheExtent: 600,
        itemCount: featuredHotels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final doc = featuredHotels[index];
          final hotel = doc.data();

          return RepaintBoundary(
            child: _FeaturedGlassHotelCard(
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
                      hotelId: doc.id,
                      hotel: hotel,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HotelsMapScreen(),
                ),
              );
            },
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

class _StaticGlowBackground extends StatelessWidget {
  const _StaticGlowBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.18),
              ),
            ),
          ),
        ],
      ),
    );
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
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              height: 190,
              width: 235,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
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

            Container(
              height: 190,
              width: 235,
              decoration: BoxDecoration(
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
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