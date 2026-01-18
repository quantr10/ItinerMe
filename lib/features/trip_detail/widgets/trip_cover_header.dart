import 'package:flutter/material.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';

// TRIP COVER HEADER
class TripCoverHeader extends StatelessWidget {
  final Trip trip;
  final bool canEdit;
  final VoidCallback onBack;
  final VoidCallback onChangeCover;

  const TripCoverHeader({
    super.key,
    required this.trip,
    required this.canEdit,
    required this.onBack,
    required this.onChangeCover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // COVER IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Image.network(
            trip.coverImageUrl,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Image.asset(
                  'assets/images/place_placeholder.jpg',
                  height: 240,
                  fit: BoxFit.cover,
                ),
          ),
        ),

        // BACK BUTTON
        Positioned(
          top: 8,
          left: 8,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [AppTheme.defaultShadow],
              ),
              child: Icon(
                Icons.keyboard_arrow_left,
                color: AppTheme.primaryColor,
                size: AppTheme.largeIconFont,
              ),
            ),
          ),
        ),

        // CHANGE COVER BUTTON
        if (canEdit)
          Positioned(
            bottom: 8,
            right: 8,
            child: InkWell(
              onTap: onChangeCover,
              borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.defaultShadow],
                ),
                child: Icon(
                  Icons.photo_camera,
                  color: AppTheme.primaryColor,
                  size: AppTheme.largeIconFont,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
