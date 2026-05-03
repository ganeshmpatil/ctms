import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'glass.dart';

/// Captures a photo from camera or gallery and returns base64-encoded bytes.
/// Returns null on cancel.
Future<String?> capturePhotoBase64(BuildContext context,
    {bool cameraOnly = false}) async {
  ImageSource? source;
  if (cameraOnly) {
    source = ImageSource.camera;
  } else {
    source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          tint: AppColors.bg2.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('Take photo',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('Pick from gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
  if (source == null) return null;

  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 70,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}

/// Round avatar that shows a photo (base64) or a fallback initials gradient.
class PhotoAvatar extends StatelessWidget {
  final String? base64;
  final String fallbackInitials;
  final double radius;

  const PhotoAvatar({
    super.key,
    required this.base64,
    required this.fallbackInitials,
    this.radius = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (base64 != null && base64!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64!);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // fall through to initials
      }
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        fallbackInitials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.66,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
