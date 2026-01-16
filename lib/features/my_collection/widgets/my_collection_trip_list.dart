import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/tab_enum.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';

import '../controllers/my_collection_controller.dart';
import '../state/my_collection_state.dart';
import 'my_collection_trip_card.dart';
import 'empty_trip_state.dart';

class MyCollectionTripList extends StatelessWidget {
  final MyCollectionState state;
  final MyCollectionController controller;
  final DateFormat formatter;
  final Function(MyCollectionState) updateState;

  const MyCollectionTripList({
    super.key,
    required this.state,
    required this.controller,
    required this.formatter,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (state.displayedTrips.isEmpty) {
      return EmptyTripState(
        showingMyTrips: state.currentTab == CollectionTab.myTrips,
        isSearching: state.isSearching,
      );
    }

    return ListView.builder(
      itemCount: state.displayedTrips.length,
      itemBuilder: (context, index) {
        final Trip trip = state.displayedTrips[index];

        return TripCard(
          trip: trip,
          formatter: formatter,
          mode:
              state.currentTab == CollectionTab.myTrips
                  ? TripCardMode.myTrips
                  : TripCardMode.saved,
          // ===== DELETE (MY TRIPS) =====
          onDelete:
              state.currentTab == CollectionTab.myTrips
                  ? () async {
                    final confirmed = await showDialog<bool>(
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
                          content: const Text(
                            'Are you sure you want to permanently delete this trip?',
                          ),
                          actions: [
                            TextButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius,
                                  ),
                                ),
                              ),
                              onPressed:
                                  () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius,
                                  ),
                                ),
                              ),
                              onPressed:
                                  () => Navigator.pop(dialogContext, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true) return;

                    updateState(
                      state.copyWith(
                        isLoading: true,
                        createdTrips:
                            state.createdTrips
                                .where((t) => t.id != trip.id)
                                .toList(),
                        displayedTrips:
                            state.displayedTrips
                                .where((t) => t.id != trip.id)
                                .toList(),
                      ),
                    );

                    try {
                      await controller.deleteTrip(trip.id);
                      AppTheme.error('Trip deleted');
                    } catch (_) {
                      AppTheme.error('Delete failed');
                    } finally {
                      updateState(state.copyWith(isLoading: false));
                    }
                  }
                  : null,

          // ===== UNSAVE (SAVED TAB) =====
          onRemove:
              !(state.currentTab == CollectionTab.myTrips)
                  ? () async {
                    updateState(
                      state.copyWith(
                        savedTrips:
                            state.savedTrips
                                .where((t) => t.id != trip.id)
                                .toList(),
                        displayedTrips:
                            state.displayedTrips
                                .where((t) => t.id != trip.id)
                                .toList(),
                      ),
                    );

                    try {
                      await controller.unsaveTrip(trip.id);
                      AppTheme.error('Trip removed from saved');
                    } catch (_) {
                      AppTheme.error('Unsave failed');
                    }
                  }
                  : null,

          // ===== COPY (SAVED TAB) =====
          onCopy:
              !(state.currentTab == CollectionTab.myTrips)
                  ? () async {
                    final newTripName = await _askCopyName(context, trip.name);
                    if (newTripName == null) return;

                    updateState(state.copyWith(isLoading: true));

                    try {
                      final newTrip = await controller.copyTrip(
                        trip,
                        customName: newTripName,
                      );

                      updateState(
                        state.copyWith(
                          createdTrips: [...state.createdTrips, newTrip],
                          isLoading: false,
                        ),
                      );

                      AppTheme.success('Trip copied');
                    } catch (_) {
                      updateState(state.copyWith(isLoading: false));
                      AppTheme.error('Copy failed');
                    }
                  }
                  : null,
        );
      },
    );
  }

  // ===== dialog helper =====
  Future<String?> _askCopyName(BuildContext context, String baseName) {
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.primaryColor,
                      size: AppTheme.largeFontSize,
                    ),
                  ),
                  style: const TextStyle(fontSize: AppTheme.defaultFontSize),
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  onPressed:
                      valid
                          ? () => Navigator.pop(
                            dialogContext,
                            textController.text.trim(),
                          )
                          : null,
                  child: const Text('Create Copy'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
