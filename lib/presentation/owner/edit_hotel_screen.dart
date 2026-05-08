import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hotelData['name']);
    _priceController = TextEditingController(
      text: widget.hotelData['pricePerNight']?.toString(),
    );
    _descController = TextEditingController(
      text: widget.hotelData['description'],
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
    setState(() => _isLoading = true);
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
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHotel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.backgroundDark1,
        title: const Text(
          'Delete Hotel',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this hotel?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
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
        ),
      );
      Navigator.pop(context); // Go back to list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete hotel'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.hotelData['imageUrl'] ?? 'https://via.placeholder.com/400x200';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark1,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.backgroundDark1,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'hotel_image_${widget.hotelId}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundDark1.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  "Edit Hotel Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField("Hotel Name", _nameController, Icons.business),
                const SizedBox(height: 16),
                _buildTextField(
                  "Price Per Night (Rs.)",
                  _priceController,
                  Icons.payments,
                  isNumber: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  "Description",
                  _descController,
                  Icons.description,
                  maxLines: 4,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.backgroundDark1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.backgroundDark1,
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
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
