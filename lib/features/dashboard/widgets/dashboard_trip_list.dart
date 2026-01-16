import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itinerme/core/theme/app_theme.dart';

import '../controllers/dashboard_controller.dart';
import '../state/dashboard_state.dart';
import 'dashboard_trip_card.dart';
import 'empty_dashboard_state.dart';

class DashboardTripList extends StatelessWidget {
  final DashboardState state;
  final DashboardController controller;
  final DateFormat formatter;
  final VoidCallback onStateChanged;
  final Function(DashboardState) updateState;

  const DashboardTripList({
    super.key,
    required this.state,
    required this.controller,
    required this.formatter,
    required this.onStateChanged,
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
      return EmptyDashboardState(isSearching: state.isSearching);
    }

    return ListView.builder(
      itemCount: state.displayedTrips.length,
      itemBuilder: (_, i) {
        final trip = state.displayedTrips[i];
        final isSaved = state.savedTripIds.contains(trip.id);

        return TripCard(
          trip: trip,
          formatter: formatter,
          isSaved: isSaved,
          onToggleSave: () async {
            try {
              final updated = await controller.saveTrip(
                state.savedTripIds,
                trip.id,
              );

              updateState(state.copyWith(savedTripIds: updated));

              if (isSaved) {
                AppTheme.error('Trip removed from saved');
              } else {
                AppTheme.success('Trip saved');
              }

              onStateChanged();
            } catch (_) {
              AppTheme.error('Save failed');
            }
          },
        );
      },
    );
  }
}
