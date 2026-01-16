import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TripSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TripSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.defaultShadow],
      ),
      child: SizedBox(
        height: AppTheme.fieldHeight,
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          decoration: AppTheme.inputDecoration(
            'Search trips and locations...',
            onClear: () {
              controller.clear();
              onChanged('');
            },
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          ),
          style: const TextStyle(fontSize: AppTheme.defaultFontSize),
        ),
      ),
    );
  }
}
