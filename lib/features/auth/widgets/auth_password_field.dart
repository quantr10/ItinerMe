import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  // PASSWORD INPUT FIELD
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.fieldHeight,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.black,
          fontSize: AppTheme.defaultFontSize,
        ),
        decoration: AppTheme.inputDecoration(
          'Password',
          onClear: () => controller.clear(),
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.primaryColor,
              size: AppTheme.largeIconFont,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
