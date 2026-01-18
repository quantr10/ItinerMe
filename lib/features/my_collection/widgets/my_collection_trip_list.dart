import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'delete_trip_dialog.dart';
import 'copy_trip_dialog.dart';

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

  const MyCollectionTripList({
    super.key,
    required this.state,
    required this.controller,
    required this.formatter,
  });

  // MY COLLECTION TRIP LIST
  @override
  Widget build(BuildContext context) {
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

          // ===== DELETE (My Trips tab) =====
          onDelete:
              state.currentTab == CollectionTab.myTrips
                  ? () async {
                    final confirmed = await showDeleteTripDialog(context);
                    if (confirmed != true) return;

                    try {
                      await controller.deleteTrip(trip.id);
                      AppTheme.success('Trip deleted');
                    } catch (_) {
                      AppTheme.error('Delete failed');
                    }
                  }
                  : null,

          // ===== UNSAVE (Saved tab) =====
          onRemove:
              state.currentTab == CollectionTab.saved
                  ? () async {
                    try {
                      await controller.unsaveTrip(trip.id);
                      AppTheme.success('Trip removed from saved');
                    } catch (_) {
                      AppTheme.error('Unsave failed');
                    }
                  }
                  : null,

          // ===== COPY (Saved tab) =====
          onCopy:
              state.currentTab == CollectionTab.saved
                  ? () async {
                    final newTripName = await showCopyTripDialog(
                      context,
                      trip.name,
                    );
                    if (newTripName == null) return;

                    try {
                      await controller.copyTrip(trip, newTripName);
                      AppTheme.success('Trip copied');
                    } catch (_) {
                      AppTheme.error('Copy failed');
                    }
                  }
                  : null,
        );
      },
    );
  }
}
