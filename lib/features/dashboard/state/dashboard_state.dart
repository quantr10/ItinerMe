import 'package:itinerme/core/models/trip.dart';
import '../../../core/enums/sort_enums.dart';

class DashboardState {
  final List<Trip> allTrips;
  final List<Trip> displayedTrips;
  final Set<String> savedTripIds;
  final bool isLoading;
  final bool isSearching;
  final SortOption sortOption;
  final SortOrder sortOrder;

  const DashboardState({
    this.allTrips = const [],
    this.displayedTrips = const [],
    this.savedTripIds = const {},
    this.isLoading = true,
    this.isSearching = false,
    this.sortOption = SortOption.name,
    this.sortOrder = SortOrder.ascending,
  });

  DashboardState copyWith({
    List<Trip>? allTrips,
    List<Trip>? displayedTrips,
    Set<String>? savedTripIds,
    bool? isLoading,
    bool? isSearching,
    SortOption? sortOption,
    SortOrder? sortOrder,
  }) {
    return DashboardState(
      allTrips: allTrips ?? this.allTrips,
      displayedTrips: displayedTrips ?? this.displayedTrips,
      savedTripIds: savedTripIds ?? this.savedTripIds,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      sortOption: sortOption ?? this.sortOption,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
