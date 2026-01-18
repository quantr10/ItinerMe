import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  // AUTH HEADER
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTheme.extraLargeSpacing,
        const Icon(Icons.travel_explore, size: 60, color: Colors.white),
        AppTheme.mediumSpacing,
        const Text(
          'ItinerMe',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.titleFontSize,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
