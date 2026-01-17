import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../state/dashboard_state.dart';
import '../../../core/models/trip.dart';
import '../../../core/enums/sort_enums.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DashboardState _state = const DashboardState();
  DashboardState get state => _state;

  DashboardController({required this.firestore, required this.auth}) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final user = auth.currentUser;
    if (user == null) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final savedIds = Set<String>.from(userDoc['savedTripIds'] ?? []);
    final createdIds = Set<String>.from(userDoc['createdTripIds'] ?? []);

    final snap = await firestore.collection('trips').get();
    final trips =
        snap.docs
            .map((d) => Trip.fromJson({...d.data(), 'id': d.id}))
            .where((t) => !createdIds.contains(t.id))
            .toList();

    final sorted = _sort(trips, SortOption.name, SortOrder.ascending);

    _state = _state.copyWith(
      allTrips: trips,
      displayedTrips: sorted,
      savedTripIds: savedIds,
      isLoading: false,
    );
    notifyListeners();
  }

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

  void sort(SortOption option, SortOrder order) {
    _state = _state.copyWith(
      sortOption: option,
      sortOrder: order,
      displayedTrips: _sort(_state.displayedTrips, option, order),
    );
    notifyListeners();
  }

  Future<void> toggleSaveTrip(String tripId) async {
    final user = auth.currentUser!;
    final ref = firestore.collection('users').doc(user.uid);

    final updated = Set<String>.from(_state.savedTripIds);
    final isSaved = updated.contains(tripId);

    isSaved ? updated.remove(tripId) : updated.add(tripId);

    await ref.update({
      'savedTripIds':
          isSaved
              ? FieldValue.arrayRemove([tripId])
              : FieldValue.arrayUnion([tripId]),
    });

    _state = _state.copyWith(savedTripIds: updated);
    notifyListeners();
  }

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
