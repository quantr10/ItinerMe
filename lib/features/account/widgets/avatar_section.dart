import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AvatarSection extends StatelessWidget {
  final ImageProvider? avatar;
  final bool isUploading;
  final VoidCallback onPickImage;

  const AvatarSection({
    super.key,
    required this.avatar,
    required this.isUploading,
    required this.onPickImage,
  });

  // AVATAR SECTION UI
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ================= AVATAR CIRCLE =================
          CircleAvatar(
            radius: 60,
            backgroundImage: avatar,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
            child:
                avatar == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
          ),

          // ================= CAMERA BUTTON =================
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: isUploading ? null : onPickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
