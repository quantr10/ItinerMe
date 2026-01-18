import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;

  const AuthEmailField({super.key, required this.controller});

  // EMAIL INPUT FIELD
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.fieldHeight,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: Colors.black,
          fontSize: AppTheme.defaultFontSize,
        ),
        decoration: AppTheme.inputDecoration(
          'Email',
          onClear: () => controller.clear(),
        ),
      ),
    );
  }
}
