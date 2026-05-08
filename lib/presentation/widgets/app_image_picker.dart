import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';

class AppImagePicker extends StatefulWidget {
  final String buttonText;
  final Function(String imageUrl) onImageUploaded;

  const AppImagePicker({
    super.key,
    required this.buttonText,
    required this.onImageUploaded,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  File? selectedImage;
  bool isUploading = false;

  Future<void> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        selectedImage = File(pickedFile.path);
        isUploading = true;
      });

      final imageUrl = await CloudinaryService.uploadImage(selectedImage!);

      setState(() {
        isUploading = false;
      });

      if (imageUrl != null) {
        widget.onImageUploaded(imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image uploaded successfully"),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image upload failed"),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isUploading ? null : pickAndUploadImage,
            child: isUploading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.buttonText),
          ),
        ),
      ],
    );
  }
}