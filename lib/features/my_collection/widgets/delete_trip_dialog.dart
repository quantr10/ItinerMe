import 'package:flutter/material.dart';
import 'package:itinerme/core/theme/app_theme.dart';

Future<bool?> showDeleteTripDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),
        insetPadding: AppTheme.largePadding,
        content: const Text(
          'Are you sure you want to permanently delete this trip?',
          style: TextStyle(fontSize: AppTheme.defaultFontSize),
        ),
        actions: [
          AppTheme.dialogCancelButton(dialogContext),
          AppTheme.dialogPrimaryButton(
            context: dialogContext,
            label: 'Delete',
            onPressed: () => Navigator.pop(dialogContext, true),
            isPrimary: false,
          ),
        ],
      );
    },
  );
}
