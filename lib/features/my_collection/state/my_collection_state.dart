import 'package:itinerme/core/models/trip.dart';
import '../../../core/enums/tab_enum.dart';

class MyCollectionState {
  final List<Trip> createdTrips;
  final List<Trip> savedTrips;
  final List<Trip> displayedTrips;
  final bool isLoading;
  final bool isSearching;
  final CollectionTab currentTab;

  const MyCollectionState({
    this.createdTrips = const [],
    this.savedTrips = const [],
    this.displayedTrips = const [],
    this.isLoading = true,
    this.isSearching = false,
    this.currentTab = CollectionTab.myTrips,
  });

  MyCollectionState copyWith({
    List<Trip>? createdTrips,
    List<Trip>? savedTrips,
    List<Trip>? displayedTrips,
    bool? isLoading,
    bool? isSearching,
    CollectionTab? currentTab,
  }) {
    return MyCollectionState(
      createdTrips: createdTrips ?? this.createdTrips,
      savedTrips: savedTrips ?? this.savedTrips,
      displayedTrips: displayedTrips ?? this.displayedTrips,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      currentTab: currentTab ?? this.currentTab,
    );
  }
}
