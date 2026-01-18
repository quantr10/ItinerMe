import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  // DASHBOARD SEARCH BAR
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
