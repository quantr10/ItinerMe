import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';
import '../models/itinerary_day.dart';
import '../models/must_visit_place.dart';
import '../enums/transportation_enums.dart';
import '../services/place_image_cache_service.dart';

class TripRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  TripRepository({required this.firestore, required this.auth});

  // CREATE TRIP
  Future<Trip> createTrip({
    required String tripName,
    required int budget,
    required String locationName,
    required DateTime startDate,
    required DateTime endDate,
    required TransportationType transportation,
    required List<String> interests,
    required List<MustVisitPlace> mustVisitPlaces,
    required String? coverPhotoReference,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final tripRef = firestore.collection('trips').doc();

    // Default cover
    String coverUrl =
        'https://images.unsplash.com/photo-1542038784456-1ea8e935640e';

    // Cover from Google Place
    if (coverPhotoReference != null) {
      final cached = await PlaceImageCacheService.cachePlacePhoto(
        photoReference: coverPhotoReference,
        path: 'trip_covers/${tripRef.id}.jpg',
      );
      if (cached != null) coverUrl = cached;
    }

    final trip = Trip(
      id: tripRef.id,
      name: tripName,
      location: locationName,
      coverImageUrl: coverUrl,
      budget: budget,
      startDate: startDate,
      endDate: endDate,
      transportation: transportation,
      interests: interests,
      mustVisitPlaces: mustVisitPlaces,
      itinerary: const [],
    );

    await tripRef.set(trip.toJson());

    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayUnion([tripRef.id]),
    });

    return trip;
  }

  // ATTACH ITINERARY
  Future<void> attachItinerary(String tripId, List<ItineraryDay> days) async {
    await firestore.collection('trips').doc(tripId).update({
      'itinerary': days.map((e) => e.toJson()).toList(),
    });
  }

  // LOAD USER TRIPS
  Future<(List<Trip> created, List<Trip> saved)> loadUserTrips() async {
    final user = auth.currentUser;
    if (user == null) return (<Trip>[], <Trip>[]);

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final createdIds = List<String>.from(userDoc['createdTripIds'] ?? []);
    final savedIds = List<String>.from(userDoc['savedTripIds'] ?? []);

    final snap = await firestore.collection('trips').get();
    final trips =
        snap.docs.map((d) => Trip.fromJson({...d.data(), 'id': d.id})).toList();

    return (
      trips.where((t) => createdIds.contains(t.id)).toList(),
      trips.where((t) => savedIds.contains(t.id)).toList(),
    );
  }

  // DELETE TRIP
  Future<void> deleteTrip(String tripId) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await firestore.collection('trips').doc(tripId).delete();
    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayRemove([tripId]),
    });
  }

  // UNSAVE TRIP
  Future<void> unsaveTrip(String tripId) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await firestore.collection('users').doc(user.uid).update({
      'savedTripIds': FieldValue.arrayRemove([tripId]),
    });
  }

  // COPY TRIP
  Future<Trip> copyTrip(Trip original, String newName) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = firestore.collection('trips').doc();
    final newTrip = original.copyWith(id: doc.id, name: newName);

    await doc.set(newTrip.toJson());

    await firestore.collection('users').doc(user.uid).update({
      'createdTripIds': FieldValue.arrayUnion([doc.id]),
    });

    return newTrip;
  }

  // GET CREATED TRIP IDS
  Future<List<String>> getCreatedTripIds() async {
    final user = auth.currentUser;
    if (user == null) return [];
    final doc = await firestore.collection('users').doc(user.uid).get();
    return List<String>.from(doc['createdTripIds'] ?? []);
  }

  // UPDATE ITINERARY
  Future<void> updateItinerary(String tripId, List<ItineraryDay> days) async {
    await firestore.collection('trips').doc(tripId).update({
      'itinerary': days.map((e) => e.toJson()).toList(),
    });
  }

  // UPDATE COVER IMAGE
  Future<void> updateCover(String tripId, String url) async {
    await firestore.collection('trips').doc(tripId).update({
      'coverImageUrl': url,
    });
  }

  // UPDATE DATE RANGE
  Future<void> updateDates(
    String tripId,
    DateTime start,
    DateTime end,
    List<ItineraryDay> days,
  ) async {
    await firestore.collection('trips').doc(tripId).update({
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'itinerary': days.map((e) => e.toJson()).toList(),
    });
  }
}
