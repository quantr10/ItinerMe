import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';
import 'google_cover_picker_dialog.dart';

Future<void> showCoverOptionDialog(
  BuildContext context,
  TripDetailController controller,
) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Choose Cover Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.largeFontSize,
          ),
        ),
        insetPadding: AppTheme.largePadding,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_search),
              title: const Text('Choose from Google'),
              onTap: () async {
                Navigator.pop(dialogContext);
                await showGoogleCoverPickerDialog(context, controller);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from device'),
              onTap: () async {
                Navigator.pop(dialogContext);
                final ok = await controller.updateCoverFromDevice();
                if (ok) {
                  AppTheme.success('Cover updated');
                } else {
                  AppTheme.error('Failed');
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
