import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

import '../../../core/theme/app_theme.dart';
import '../controller/trip_detail_controller.dart';

Future<void> showAddDestinationDialog(
  BuildContext context,
  TripDetailController controller,
  int dayIndex,
) async {
  String query = '';
  List<AutocompletePrediction> results = [];
  AutocompletePrediction? selectedPrediction;
  final searchController = TextEditingController();

  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Add Destination',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.largeFontSize,
              ),
            ),
            insetPadding: AppTheme.largePadding,
            content: SizedBox(
              height: 250,
              width: 350,
              child: Column(
                children: [
                  SizedBox(
                    height: AppTheme.fieldHeight,
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (value) async {
                        query = value.trim();
                        if (query.isEmpty) {
                          setModalState(() => results = []);
                          return;
                        }
                        final list = await controller.searchDestinationInTrip(
                          query,
                        );
                        setModalState(() => results = list);
                      },
                      decoration: AppTheme.inputDecoration(
                        'Type a place',
                        prefixIcon: const Icon(Icons.search),
                        onClear: () => searchController.clear(),
                      ),
                    ),
                  ),
                  AppTheme.smallSpacing,
                  if (results.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, index) {
                          final prediction = results[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.place,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(prediction.description ?? ''),
                            onTap: () {
                              setModalState(() {
                                selectedPrediction = prediction;
                                searchController.text =
                                    prediction.description ?? '';
                                results = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              AppTheme.dialogCancelButton(dialogContext),
              AppTheme.dialogPrimaryButton(
                context: dialogContext,
                label: 'Add',
                onPressed:
                    selectedPrediction == null
                        ? null
                        : () async {
                          final success = await controller
                              .addDestinationFromSearch(
                                dayIndex,
                                selectedPrediction!,
                              );
                          Navigator.pop(dialogContext, success);
                        },
              ),
            ],
          );
        },
      );
    },
  );

  if (ok == true) {
    AppTheme.success('Destination added');
  } else if (ok == false) {
    AppTheme.error('Destination already exists');
  }
}
