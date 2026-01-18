import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// CONFIRM CLEAR DAY DIALOG
Future<bool?> showConfirmClearDayDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,

        // ===== TITLE =====
        title: const Text(
          'Clear this day',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),

        // ===== MESSAGE =====
        content: const Text(
          'This will remove all destinations from this day. Continue?',
          style: TextStyle(fontSize: AppTheme.defaultFontSize),
        ),

        // ===== ACTIONS =====
        actions: [
          AppTheme.dialogCancelButton(dialogContext),

          AppTheme.dialogPrimaryButton(
            context: dialogContext,
            label: 'Clear',
            onPressed: () => Navigator.pop(dialogContext, true),
            isPrimary: false,
          ),
        ],
      );
    },
  );
}
