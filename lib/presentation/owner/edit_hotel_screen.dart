import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';

class EditHotelScreen extends StatefulWidget {
  final String hotelId;
  final Map<String, dynamic> hotelData;

  const EditHotelScreen({
    super.key,
    required this.hotelId,
    required this.hotelData,
  });

  @override
  State<EditHotelScreen> createState() => _EditHotelScreenState();
}

class _EditHotelScreenState extends State<EditHotelScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  bool _isLoading = false;

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.hotelData['name']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: widget.hotelData['pricePerNight']?.toString() ?? '',
    );

    _descController = TextEditingController(
      text: widget.hotelData['description']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('hotels')
          .doc(widget.hotelId)
          .update({
            'name': _nameController.text.trim(),
            'pricePerNight':
                double.tryParse(_priceController.text.trim()) ?? 0.0,
            'description': _descController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteHotel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete Hotel',
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete this hotel?',
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('hotels')
          .doc(widget.hotelId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotel deleted'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete hotel: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.hotelData['imageUrl']?.toString() ??
        'https://via.placeholder.com/400x200';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.adaptiveSurface(context),
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(
                color: AppColors.adaptiveTextPrimary(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'hotel_image_${widget.hotelId}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.adaptiveSurface(context),
                            child: Icon(
                              Icons.hotel_rounded,
                              color: AppColors.adaptiveTextTertiary(context),
                              size: 80,
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _isDark(context)
                                  ? Colors.black.withValues(alpha: 0.75)
                                  : Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    "Edit Hotel Details",
                    style: TextStyle(
                      color: AppColors.adaptiveTextPrimary(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Update your hotel name, price, and description.",
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          "Hotel Name",
                          _nameController,
                          Icons.business_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Price Per Night (Rs.)",
                          _priceController,
                          Icons.payments_rounded,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Description",
                          _descController,
                          Icons.description_rounded,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.accent.withValues(
                          alpha: 0.55,
                        ),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
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
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _deleteHotel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.3,
                        ),
                        foregroundColor: Colors.redAccent,
                        backgroundColor: Colors.redAccent.withValues(
                          alpha: 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Delete Hotel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.adaptiveBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isDark(context) ? 0.22 : 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      cursorColor: AppColors.accent,
      style: TextStyle(
        color: AppColors.adaptiveTextPrimary(context),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: AppColors.adaptiveSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adaptiveBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adaptiveBorder(context)),
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
}
