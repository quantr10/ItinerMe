import 'package:flutter/material.dart';

class AppTheme {
  // COLORS
  static const primaryColor = Color(0xFF88A28E);
  static const secondaryColor = Color(0xFFB8C4BB);
  static const accentColor = Color(0xFF6D8B74);
  static const errorColor = Colors.red;
  static const hintColor = Color(0xFF616161);

  // RADIUS & BORDERS
  static const borderRadius = 12.0;
  static const largeBorderRadius = 24.0;
  static const borderWidth = 1.0;

  // SPACING
  static const smallSpacing = SizedBox(height: 8);
  static const mediumSpacing = SizedBox(height: 16);
  static const largeSpacing = SizedBox(height: 24);
  static const extraLargeSpacing = SizedBox(height: 48);

  // SIZING & PADDING
  static const fieldHeight = 40.0;

  static const largePadding = EdgeInsets.all(24);
  static const defaultPadding = EdgeInsets.all(16);
  static const smallPadding = EdgeInsets.all(8);

  static const horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const largeHorizontalPadding = EdgeInsets.symmetric(horizontal: 24);

  // FONT SIZES
  static const titleFontSize = 24.0;
  static const largeFontSize = 18.0;
  static const defaultFontSize = 14.0;
  static const smallFontSize = 12.0;

  // ICON SIZES
  static const largeIconFont = 20.0;
  static const mediumIconFont = 18.0;
  static const smallIconFont = 16.0;

  // ANIMATION DURATIONS
  static const animationDuration = Duration(milliseconds: 300);
  static const messageDuration = Duration(seconds: 2);

  // SHADOW
  static const BoxShadow defaultShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 10,
    offset: Offset(0, 2),
  );

  // GLOBAL SNACKBAR KEY
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  // INPUT DECORATION
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

  // STANDARD ELEVATED BUTTON
  static Widget elevatedButton({
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : errorColor,
          foregroundColor: isPrimary ? primaryColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: defaultFontSize,
          ),
        ),
      ),
    );
  }

  // SNACKBAR HELPERS
  static void success(String message) {
    _showSnack(message, accentColor);
  }

  static void error(String message) {
    _showSnack(message, errorColor);
  }

  static void _showSnack(String message, Color color) {
    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: messageDuration,
        ),
      );
  }

  // LOADING SCREEN
  static Widget loadingScreen({bool overlay = false}) {
    return Container(
      color:
          overlay ? Colors.black.withValues(alpha: 0.25) : Colors.transparent,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );
  }

  // DIALOG BUTTONS
  static Widget dialogCancelButton(BuildContext context) {
    return TextButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    );
  }

  static Widget dialogPrimaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = true,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryColor : errorColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
