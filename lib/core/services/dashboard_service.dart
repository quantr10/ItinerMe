import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';

class DashboardService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DashboardService({required this.firestore, required this.auth});

  // LOAD DASHBOARD TRIPS
  Future<({List<Trip> trips, Set<String> savedTripIds})> loadTrips() async {
    final user = auth.currentUser;
    if (user == null) {
      return (trips: <Trip>[], savedTripIds: <String>{});
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final savedIds = Set<String>.from(userDoc['savedTripIds'] ?? []);
    final createdIds = Set<String>.from(userDoc['createdTripIds'] ?? []);

    final snap = await firestore.collection('trips').get();

    final trips =
        snap.docs
            .map((d) => Trip.fromJson({...d.data(), 'id': d.id}))
            // Dashboard only shows trips NOT created by user
            .where((t) => !createdIds.contains(t.id))
            .toList();

    return (trips: trips, savedTripIds: savedIds);
  }

  // TOGGLE SAVE TRIP
  Future<Set<String>> toggleSaveTrip({required String tripId}) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final ref = firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    final current = Set<String>.from(doc['savedTripIds'] ?? []);
    final isSaved = current.contains(tripId);

    if (isSaved) {
      await ref.update({
        'savedTripIds': FieldValue.arrayRemove([tripId]),
      });
      current.remove(tripId);
    } else {
      await ref.update({
        'savedTripIds': FieldValue.arrayUnion([tripId]),
      });
      current.add(tripId);
    }

    return current;
  }
}
