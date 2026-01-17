import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

Future<bool?> showConfirmRemoveDestinationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Remove destination',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove this destination?',
        ),
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
