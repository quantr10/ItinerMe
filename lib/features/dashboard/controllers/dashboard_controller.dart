import 'package:flutter/material.dart';
import '../../../core/enums/sort_enums.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/dashboard_service.dart';
import '../state/dashboard_state.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService dashboardService;

  DashboardState _state = const DashboardState();
  DashboardState get state => _state;

  DashboardController({required this.dashboardService}) {
    loadTrips();
  }

  // LOAD DASHBOARD TRIPS
  Future<void> loadTrips() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await dashboardService.loadTrips();
    final sorted = _sort(result.trips, SortOption.name, SortOrder.ascending);

    _state = _state.copyWith(
      allTrips: result.trips,
      displayedTrips: sorted,
      savedTripIds: result.savedTripIds,
      isLoading: false,
    );

    notifyListeners();
  }

  // SEARCH TRIPS
  void search(String query) {
    final lower = query.toLowerCase();

    final filtered =
        _state.allTrips
            .where(
              (t) =>
                  t.name.toLowerCase().contains(lower) ||
                  t.location.toLowerCase().contains(lower),
            )
            .toList();

    _state = _state.copyWith(
      isSearching: query.isNotEmpty,
      displayedTrips: _sort(filtered, _state.sortOption, _state.sortOrder),
    );

    notifyListeners();
  }

  // SORT TRIPS
  void sort(SortOption option, SortOrder order) {
    _state = _state.copyWith(
      sortOption: option,
      sortOrder: order,
      displayedTrips: _sort(_state.displayedTrips, option, order),
    );
    notifyListeners();
  }

  // TOGGLE SAVE / UNSAVE TRIP
  Future<void> toggleSaveTrip(String tripId) async {
    final updated = await dashboardService.toggleSaveTrip(tripId: tripId);
    _state = _state.copyWith(savedTripIds: updated);
    notifyListeners();
  }

  // LOCAL SORT HELPER
  List<Trip> _sort(List<Trip> trips, SortOption option, SortOrder order) {
    final list = List<Trip>.from(trips);

    list.sort((a, b) {
      int cmp;
      switch (option) {
        case SortOption.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortOption.startDate:
          cmp = a.startDate.compareTo(b.startDate);
          break;
        case SortOption.location:
          cmp = a.location.compareTo(b.location);
          break;
      }
      return order == SortOrder.ascending ? cmp : -cmp;
    });

    return list;
  }
}
