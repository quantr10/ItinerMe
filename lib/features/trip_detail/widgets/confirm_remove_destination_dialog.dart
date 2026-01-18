import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// CONFIRM REMOVE DESTINATION DIALOG
Future<bool?> showConfirmRemoveDestinationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,

        // ===== TITLE =====
        title: const Text(
          'Remove destination',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),

        // ===== MESSAGE =====
        content: const Text(
          'Are you sure you want to remove this destination?',
          style: TextStyle(fontSize: AppTheme.defaultFontSize),
        ),

        // ===== ACTIONS =====
        actions: [
          AppTheme.dialogCancelButton(dialogContext),

          AppTheme.dialogPrimaryButton(
            context: dialogContext,
            label: 'Remove',
            onPressed: () => Navigator.pop(dialogContext, true),
            isPrimary: false,
          ),
        ],
      );
    },
  );
}
