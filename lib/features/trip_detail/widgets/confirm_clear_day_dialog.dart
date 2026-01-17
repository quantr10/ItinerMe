import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

Future<bool?> showConfirmClearDayDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Clear this day',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),
        content: const Text(
          'This will remove all destinations from this day. Continue?',
        ),
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
