import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:itinerme/core/enums/tab_enum.dart';
import 'package:itinerme/core/models/trip.dart';
import 'package:itinerme/features/my_collection/state/my_collection_state.dart';

class MyCollectionController extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MyCollectionState _state = const MyCollectionState();
  MyCollectionState get state => _state;

  MyCollectionController({required this.firestore, required this.auth}) {
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
    final createdIds = List<String>.from(userDoc['createdTripIds'] ?? []);
    final savedIds = List<String>.from(userDoc['savedTripIds'] ?? []);

    final snap = await firestore.collection('trips').get();
    final trips =
        snap.docs.map((d) => Trip.fromJson({...d.data(), 'id': d.id})).toList();

    final createdTrips = trips.where((t) => createdIds.contains(t.id)).toList();
    final savedTrips = trips.where((t) => savedIds.contains(t.id)).toList();

    _state = _state.copyWith(
      createdTrips: createdTrips,
      savedTrips: savedTrips,
      displayedTrips: createdTrips,
      isLoading: false,
    );
    notifyListeners();
  }

  void toggleTab(CollectionTab tab) {
    final showingMyTrips = tab == CollectionTab.myTrips;

    _state = _state.copyWith(
      currentTab: tab,
      displayedTrips: showingMyTrips ? _state.createdTrips : _state.savedTrips,
      isSearching: false,
    );
    notifyListeners();
  }

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

  Future<void> deleteTrip(String tripId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final user = auth.currentUser!;
    await firestore.collection('trips').doc(tripId).delete();
    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayRemove([tripId]),
    });

    final updatedCreated =
        _state.createdTrips.where((t) => t.id != tripId).toList();

    _state = _state.copyWith(
      createdTrips: updatedCreated,
      displayedTrips: updatedCreated,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<void> unsaveTrip(String tripId) async {
    final user = auth.currentUser!;
    await firestore.collection('users').doc(user.uid).update({
      'savedTripIds': FieldValue.arrayRemove([tripId]),
    });

    final updatedSaved =
        _state.savedTrips.where((t) => t.id != tripId).toList();

    _state = _state.copyWith(
      savedTrips: updatedSaved,
      displayedTrips: updatedSaved,
    );
    notifyListeners();
  }

  Future<void> copyTrip(Trip original, String customName) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

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

    _state = _state.copyWith(
      createdTrips: [..._state.createdTrips, newTrip],
      isLoading: false,
    );
    notifyListeners();
  }
}
