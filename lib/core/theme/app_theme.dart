import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF88A28E);
  static const secondaryColor = Color(0xFFB8C4BB);
  static const accentColor = Color(0xFF6D8B74);
  static const errorColor = Colors.red;
  static const chipBackgroundColor = Color.fromARGB(255, 218, 238, 220);
  static const hintColor = Color(0xFF616161);

  static const borderRadius = 12.0;
  static const largeBorderRadius = 24.0;

  static const borderWidth = 1.0;

  static const smallSpacing = SizedBox(height: 8);
  static const mediumSpacing = SizedBox(height: 16);
  static const largeSpacing = SizedBox(height: 24);
  static const extraLargeSpacing = SizedBox(height: 48);

  static const fieldHeight = 40.0;

  static const largePadding = EdgeInsets.all(24);
  static const defaultPadding = EdgeInsets.all(16);
  static const smallPadding = EdgeInsets.all(8);

  static const horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const largeHorizontalPadding = EdgeInsets.symmetric(horizontal: 24);

  static const titleFontSize = 24.0;
  static const largeFontSize = 18.0;
  static const defaultFontSize = 14.0;
  static const smallFontSize = 12.0;

  static const largeIconFont = 20.0;
  static const mediumIconFont = 18.0;
  static const smallIconFont = 16.0;

  static const animationDuration = Duration(milliseconds: 300);
  static const messageDuration = Duration(seconds: 2);

  static const BoxShadow defaultShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 10,
    offset: Offset(0, 2),
  );

  static InputDecoration inputDecoration(
    String hint, {
    VoidCallback? onClear,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: defaultFontSize),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: borderWidth),
      ),
      prefixIcon: prefixIcon,
      suffixIcon:
          onClear != null
              ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  size: largeIconFont,
                  color: hintColor,
                ),
                onPressed: onClear,
              )
              : null,
      isDense: true,
    );
  }

  static Widget elevatedButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    double height = AppTheme.fieldHeight,
  }) {
    return SizedBox(
      width: double.infinity,
      height: fieldHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : AppTheme.errorColor,
          foregroundColor: isPrimary ? AppTheme.primaryColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          elevation: 2,
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: defaultFontSize,
                  ),
                ),
      ),
    );
  }
}
