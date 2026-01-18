import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthUsernameField extends StatelessWidget {
  final TextEditingController controller;

  const AuthUsernameField({super.key, required this.controller});

  // USERNAME INPUT FIELDSS
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.fieldHeight,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.black,
          fontSize: AppTheme.defaultFontSize,
        ),
        decoration: AppTheme.inputDecoration(
          'Username',
          onClear: () => controller.clear(),
        ),
      ),
    );
  }
}
