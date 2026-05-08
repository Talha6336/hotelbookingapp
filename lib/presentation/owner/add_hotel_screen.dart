import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your custom image picker
import ''; // Update this path to match your actual folder structure!
import '../../core/theme/app_theme.dart';
import '../widgets/app_image_picker.dart';

class AddHotelScreen extends StatefulWidget {
  const AddHotelScreen({super.key});

  @override
  State<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _checkInController = TextEditingController(text: "14:00");
  final _checkOutController = TextEditingController(text: "11:00");

  // State Variables
  bool _isLoading = false;
  String _selectedCategory = 'Luxury';
  List<String> _uploadedImageUrls = [];
  Set<String> _selectedAmenities = {};

  // Animations
  late AnimationController _floatingController;

  // Data Sources
  final List<String> _categories = [
    'Luxury',
    'Budget',
    'Resort',
    'Business',
    'Boutique',
    'Family',
    'Beach',
  ];

  final List<Map<String, dynamic>> _amenitiesList = [
    {'name': 'Free WiFi', 'icon': Icons.wifi_rounded},
    {'name': 'Swimming Pool', 'icon': Icons.pool_rounded},
    {'name': 'Parking', 'icon': Icons.local_parking_rounded},
    {'name': 'Air Conditioning', 'icon': Icons.ac_unit_rounded},
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded},
    {'name': 'Spa', 'icon': Icons.spa_rounded},
    {'name': 'Room Service', 'icon': Icons.room_service_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill in all required fields.", isError: true);
      return;
    }

    if (_uploadedImageUrls.isEmpty) {
      _showSnackBar(
        "Please upload at least one image of your hotel.",
        isError: true,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("You must be logged in to add a hotel.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('hotels').add({
        'ownerId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pricePerNight': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'phone': _phoneController.text.trim(),
        'checkInTime': _checkInController.text.trim(),
        'checkOutTime': _checkOutController.text.trim(),
        'category': _selectedCategory,
        'amenities': _selectedAmenities.toList(),
        'images': _uploadedImageUrls,
        'imageUrl': _uploadedImageUrls.first, // Primary display image
        'rating': 0.0, // Default for new hotels
        'latitude': 31.4187, // Placeholder for Google Maps
        'longitude': 73.0791, // Placeholder for Google Maps
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnackBar("Hotel added successfully!", isError: false);
      Navigator.pop(context); // Go back to dashboard
    } catch (e) {
      _showSnackBar("Failed to save hotel: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Luxury Dark Gradient Background
          Container(
            decoration: const BoxDecoration(gradient: AppColors.darkGradient),
          ),

          // 2. Animated Floating Orbs
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildFloatingCircle(
                    size: 300,
                    top: -100,
                    left: -100,
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                  _buildFloatingCircle(
                    size: 400,
                    bottom: -50,
                    right: -150,
                    color: AppColors.secondary.withOpacity(0.15),
                  ),
                ],
              );
            },
          ),

          // 3. Main Scrollable Form
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Hotel Images"),
                          _buildImageUploadSection(),
                          const SizedBox(height: 24),

                          _buildSectionTitle("Basic Information"),
                          _buildDetailsForm(),
                          const SizedBox(height: 24),

                          _buildSectionTitle("Category"),
                          _buildCategorySelection(),
                          const SizedBox(height: 24),

                          _buildSectionTitle("Amenities"),
                          _buildAmenitiesSelection(),
                          const SizedBox(height: 24),

                          _buildSectionTitle("Location (Google Maps)"),
                          _buildMapPlaceholder(),
                          const SizedBox(height: 32),

                          _buildSaveButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add New Hotel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Create and manage your luxury property",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.help_outline_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Display already uploaded images
          if (_uploadedImageUrls.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadedImageUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_uploadedImageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _uploadedImageUrls.removeAt(index),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Your custom Cloudinary Image Picker component
          AppImagePicker(
            buttonText: _uploadedImageUrls.isEmpty
                ? "Upload Cover Image"
                : "Upload Additional Image",
            onImageUploaded: (imageUrl) {
              setState(() {
                _uploadedImageUrls.add(imageUrl);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            "Hotel Name",
            Icons.business_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _descController,
            "Description",
            Icons.description_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _cityController,
                  "City",
                  Icons.location_city_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _priceController,
                  "Price/Night",
                  Icons.payments_rounded,
                  isNumber: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _addressController,
            "Full Address",
            Icons.map_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _phoneController,
            "Contact Number",
            Icons.phone_rounded,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _checkInController,
                  "Check-in",
                  Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _checkOutController,
                  "Check-out",
                  Icons.logout_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (value) => value!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmenitiesSelection() {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _amenitiesList.map((amenity) {
          final isSelected = _selectedAmenities.contains(amenity['name']);
          return GestureDetector(
            onTap: () {
              setState(() {
                isSelected
                    ? _selectedAmenities.remove(amenity['name'])
                    : _selectedAmenities.add(amenity['name']);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    amenity['icon'],
                    color: isSelected ? AppColors.accent : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amenity['name'],
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return _glassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark1.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: AppColors.accent),
                SizedBox(width: 8),
                Text(
                  "Pin Location on Map",
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveHotel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "Save & Publish Hotel",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
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
}
