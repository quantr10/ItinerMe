import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itinerme/core/models/trip.dart';

import '../state/dashboard_state.dart';
import '../../../core/enums/sort_enums.dart';

class DashboardController {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DashboardController({required this.firestore, required this.auth});

  Future<DashboardState> loadTrips() async {
    final user = auth.currentUser;
    if (user == null) return const DashboardState(isLoading: false);

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final savedIds = Set<String>.from(userDoc.data()?['savedTripIds'] ?? []);
    final createdIds = Set<String>.from(
      userDoc.data()?['createdTripIds'] ?? [],
    );

    final snap = await firestore.collection('trips').get();
    final trips =
        snap.docs
            .map((d) => Trip.fromJson({...d.data(), 'id': d.id}))
            .where((t) => !createdIds.contains(t.id))
            .toList();

    return DashboardState(
      allTrips: trips,
      displayedTrips: _sort(trips, SortOption.name, SortOrder.ascending),
      savedTripIds: savedIds,
      isLoading: false,
    );
  }

  DashboardState search(DashboardState state, String query) {
    final lower = query.toLowerCase();
    final filtered =
        state.allTrips
            .where(
              (t) =>
                  t.name.toLowerCase().contains(lower) ||
                  t.location.toLowerCase().contains(lower),
            )
            .toList();

    return state.copyWith(
      isSearching: query.isNotEmpty,
      displayedTrips: _sort(filtered, state.sortOption, state.sortOrder),
    );
  }

  DashboardState sort(
    DashboardState state,
    SortOption option,
    SortOrder order,
  ) {
    return state.copyWith(
      sortOption: option,
      sortOrder: order,
      displayedTrips: _sort(state.displayedTrips, option, order),
    );
  }

  Future<Set<String>> saveTrip(Set<String> current, String tripId) async {
    final user = auth.currentUser!;
    final ref = firestore.collection('users').doc(user.uid);

    final updated = Set<String>.from(current);
    final isSaved = updated.contains(tripId);

    isSaved ? updated.remove(tripId) : updated.add(tripId);

    await ref.update({
      'savedTripIds':
          isSaved
              ? FieldValue.arrayRemove([tripId])
              : FieldValue.arrayUnion([tripId]),
    });

    return updated;
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
