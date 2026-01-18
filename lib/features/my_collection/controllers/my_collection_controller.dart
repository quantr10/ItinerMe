import 'package:flutter/material.dart';

import '../state/my_collection_state.dart';
import '../../../core/enums/tab_enum.dart';
import '../../../core/repositories/trip_repository.dart';
import '../../../core/models/trip.dart';

class MyCollectionController extends ChangeNotifier {
  final TripRepository tripRepository;

  MyCollectionState _state = const MyCollectionState();
  MyCollectionState get state => _state;

  MyCollectionController({required this.tripRepository}) {
    loadTrips();
  }

  // ================= LOAD USER TRIPS =================

  Future<void> loadTrips() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await tripRepository.loadUserTrips();

    _state = _state.copyWith(
      createdTrips: result.$1,
      savedTrips: result.$2,
      displayedTrips: result.$1,
      isLoading: false,
    );

    notifyListeners();
  }

  // ================= TAB TOGGLE =================

  void toggleTab(CollectionTab tab) {
    final showingMyTrips = tab == CollectionTab.myTrips;

    _state = _state.copyWith(
      currentTab: tab,
      displayedTrips: showingMyTrips ? _state.createdTrips : _state.savedTrips,
      isSearching: false,
    );
    notifyListeners();
  }

  // ================= SEARCH =================

  void search(String query) {
    final base =
        _state.currentTab == CollectionTab.myTrips
            ? _state.createdTrips
            : _state.savedTrips;

    final lower = query.toLowerCase();

    final filtered =
        base
            .where(
              (t) =>
                  t.name.toLowerCase().contains(lower) ||
                  t.location.toLowerCase().contains(lower),
            )
            .toList();

    _state = _state.copyWith(
      isSearching: query.isNotEmpty,
      displayedTrips: filtered,
    );
    notifyListeners();
  }

  // ================= DELETE TRIP =================

  Future<void> deleteTrip(String tripId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    await tripRepository.deleteTrip(tripId);

    final updated = _state.createdTrips.where((t) => t.id != tripId).toList();

    _state = _state.copyWith(
      createdTrips: updated,
      displayedTrips: updated,
      isLoading: false,
    );

    notifyListeners();
  }

  // ================= UNSAVE TRIP =================

  Future<void> unsaveTrip(String tripId) async {
    await tripRepository.unsaveTrip(tripId);

    final updated = _state.savedTrips.where((t) => t.id != tripId).toList();

    _state = _state.copyWith(savedTrips: updated, displayedTrips: updated);
    notifyListeners();
  }

  // ================= COPY TRIP =================

  Future<void> copyTrip(Trip original, String customName) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final newTrip = await tripRepository.copyTrip(original, customName);

    _state = _state.copyWith(
      createdTrips: [..._state.createdTrips, newTrip],
      isLoading: false,
    );

    notifyListeners();
  }
}
