import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

Future<String?> showCopyTripDialog(BuildContext context, String baseName) {
  final textController = TextEditingController(text: '$baseName Copy');
  bool valid = textController.text.trim().isNotEmpty;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Duplicate Trip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.largeFontSize,
              ),
            ),
            insetPadding: AppTheme.largePadding,
            content: SizedBox(
              height: AppTheme.fieldHeight,
              child: TextField(
                controller: textController,
                autofocus: true,
                onChanged: (v) => setLocal(() => valid = v.trim().isNotEmpty),
                decoration: AppTheme.inputDecoration(
                  'New Trip Name',
                  onClear: () => textController.clear(),
                ),
                style: const TextStyle(fontSize: AppTheme.defaultFontSize),
              ),
            ),
            actions: [
              AppTheme.dialogCancelButton(dialogContext),
              AppTheme.dialogPrimaryButton(
                context: dialogContext,
                label: 'Create Copy',
                onPressed:
                    valid
                        ? () => Navigator.pop(
                          dialogContext,
                          textController.text.trim(),
                        )
                        : null,
                isPrimary: true,
              ),
            ],
          );
        },
      );
    },
  );
}
