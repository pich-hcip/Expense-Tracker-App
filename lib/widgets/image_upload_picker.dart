import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';

class ImageUploadPicker extends StatefulWidget {
  const ImageUploadPicker({super.key, required this.onUploaded});

  /// Called with the S3 file name (e.g. profile-images/abc.jpg) once upload succeeds.
  /// Save this name with the API; do not show it with Image.network.
  final ValueChanged<String> onUploaded;

  @override
  State<ImageUploadPicker> createState() => _ImageUploadPickerState();
}

class _ImageUploadPickerState extends State<ImageUploadPicker> {
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _uploadService = ImageUploadService();
  File? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isUploading = true;
    });

    try {
      final url = await _uploadService.uploadImage(pickedFile);
      widget.onUploaded(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload image. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_pickedImage!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Color(0xFF0061B7), size: 32),
                  ),
      ),
    );
  }
}