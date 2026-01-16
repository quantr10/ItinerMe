import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/enums/tab_enum.dart';
import '../../../core/models/trip.dart';
import '../state/my_collection_state.dart';

class MyCollectionController {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MyCollectionController({required this.firestore, required this.auth});

  Future<MyCollectionState> loadTrips() async {
    final user = auth.currentUser;
    if (user == null) return const MyCollectionState(isLoading: false);

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final createdIds = List<String>.from(
      userDoc.data()?['createdTripIds'] ?? [],
    );
    final savedIds = List<String>.from(userDoc.data()?['savedTripIds'] ?? []);

    final snap = await firestore.collection('trips').get();
    final trips =
        snap.docs.map((d) => Trip.fromJson({...d.data(), 'id': d.id})).toList();

    final createdTrips = trips.where((t) => createdIds.contains(t.id)).toList();
    final savedTrips = trips.where((t) => savedIds.contains(t.id)).toList();

    return MyCollectionState(
      createdTrips: createdTrips,
      savedTrips: savedTrips,
      displayedTrips: createdTrips,
      isLoading: false,
    );
  }

  MyCollectionState toggleTab(MyCollectionState state, CollectionTab tab) {
    final showingMyTrips = tab == CollectionTab.myTrips;

    return state.copyWith(
      currentTab: tab,
      displayedTrips: showingMyTrips ? state.createdTrips : state.savedTrips,
    );
  }

  MyCollectionState search(MyCollectionState state, String query) {
    final base =
        state.currentTab == CollectionTab.myTrips
            ? state.createdTrips
            : state.savedTrips;

    final lower = query.toLowerCase();

    final filtered =
        base
            .where(
              (t) =>
                  t.name.toLowerCase().contains(lower) ||
                  t.location.toLowerCase().contains(lower),
            )
            .toList();

    return state.copyWith(
      isSearching: query.isNotEmpty,
      displayedTrips: filtered,
    );
  }

  Future<void> deleteTrip(String tripId) async {
    final user = auth.currentUser!;
    await firestore.collection('trips').doc(tripId).delete();

    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayRemove([tripId]),
    });

    // remove from all users' saved lists
    final users = await firestore.collection('users').get();
    for (final u in users.docs) {
      await u.reference.update({
        'savedTripIds': FieldValue.arrayRemove([tripId]),
      });
    }
  }

  Future<void> unsaveTrip(String tripId) async {
    final user = auth.currentUser!;
    await firestore.collection('users').doc(user.uid).update({
      'savedTripIds': FieldValue.arrayRemove([tripId]),
    });
  }

  Future<Trip> copyTrip(Trip original, {required String customName}) async {
    final user = auth.currentUser!;
    final doc = firestore.collection('trips').doc();

    final newTrip = Trip(
      id: doc.id,
      name: customName,
      location: original.location,
      coverImageUrl: original.coverImageUrl,
      budget: original.budget,
      startDate: original.startDate,
      endDate: original.endDate,
      transportation: original.transportation,
      interests: List.from(original.interests),
      mustVisitPlaces: List.from(original.mustVisitPlaces),
      itinerary: List.from(original.itinerary),
    );

    await doc.set(newTrip.toJson());

    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayUnion([doc.id]),
    });

    return newTrip;
  }
}
