import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthGoogleButton({super.key, required this.onPressed});

  // GOOGLE AUTH BUTTON
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTheme.mediumSpacing,

        // ================= DIVIDER =================
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white)),
            Padding(
              padding: AppTheme.horizontalPadding,
              child: const Text('OR', style: TextStyle(color: Colors.white)),
            ),
            const Expanded(child: Divider(color: Colors.white)),
          ],
        ),

        AppTheme.mediumSpacing,

        // ================= GOOGLE BUTTON =================
        AppTheme.elevatedButton(
          label: 'LOGIN WITH GOOGLE',
          onPressed: onPressed,
          isPrimary: false,
        ),
      ],
    );
  }
}
