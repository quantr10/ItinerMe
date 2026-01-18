import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TripTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TripTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  // TRIP TAB BUTTON
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppTheme.fieldHeight,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
