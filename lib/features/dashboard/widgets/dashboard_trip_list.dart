import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../state/dashboard_state.dart';
import 'dashboard_trip_card.dart';
import 'empty_dashboard_state.dart';

class DashboardTripList extends StatelessWidget {
  final DashboardState state;
  final DashboardController controller;
  final DateFormat formatter;

  const DashboardTripList({
    super.key,
    required this.state,
    required this.controller,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
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
              await controller.toggleSaveTrip(trip.id);
              isSaved
                  ? AppTheme.error('Trip removed from saved')
                  : AppTheme.success('Trip saved');
            } catch (_) {
              AppTheme.error('Save failed');
            }
          },
        );
      },
    );
  }
}
