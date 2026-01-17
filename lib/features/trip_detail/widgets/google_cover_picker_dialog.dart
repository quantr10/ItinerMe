import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';

Future<void> showGoogleCoverPickerDialog(
  BuildContext context,
  TripDetailController controller,
) async {
  final photos = await controller.getTripPhotoReferences();
  if (photos.isEmpty) {
    AppTheme.error('No photos available');
    return;
  }

  String? selected;

  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Choose Cover Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.largeFontSize,
              ),
            ),
            backgroundColor: Colors.white,
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) {
                  final ref = photos[index];
                  final url =
                      'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$ref&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}';

                  final isSelected = selected == ref;

                  return GestureDetector(
                    onTap: () => setState(() => selected = ref),
                    child: Stack(
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: Positioned.fill(
                                child: AppTheme.loadingScreen(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              AppTheme.dialogCancelButton(dialogContext),
              AppTheme.dialogPrimaryButton(
                context: dialogContext,
                label: 'Select',
                onPressed:
                    selected == null
                        ? null
                        : () async {
                          final ok = await controller
                              .updateCoverFromGooglePhoto(selected!);
                          Navigator.pop(dialogContext, ok);
                        },
              ),
            ],
          );
        },
      );
    },
  );

  if (ok == true) {
    AppTheme.success('Cover updated');
  } else if (ok == false) {
    AppTheme.error('Failed to update cover');
  }
}
