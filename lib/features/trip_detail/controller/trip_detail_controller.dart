import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_place/google_place.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/enums/transportation_enums.dart';
import '../../../core/models/trip.dart';
import '../../../core/models/destination.dart';
import '../../../core/models/itinerary_day.dart';
import '../../../core/services/place_image_cache_service.dart';
import '../state/trip_detail_state.dart';

class TripDetailController extends ChangeNotifier {
  final GooglePlace googlePlace;
  final Trip trip;
  final Map<String, Map<String, String>> _travelCache = {};

  TripDetailState _state = const TripDetailState();
  TripDetailState get state => _state;

  TripDetailController(this.trip)
    : googlePlace = GooglePlace(dotenv.env['GOOGLE_MAPS_API_KEY']!) {
    checkEditPermission();
  }

  Future<void> checkEditPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final createdIds = List<String>.from(doc.data()?['createdTripIds'] ?? []);

    _state = _state.copyWith(canEdit: createdIds.contains(trip.id));
    notifyListeners();
  }

  void toggleExpand(String placeId) {
    final updated = Set<String>.from(_state.expandedDestinations);
    if (updated.contains(placeId)) {
      updated.remove(placeId);
    } else {
      updated.add(placeId);
    }
    _state = _state.copyWith(expandedDestinations: updated);
    notifyListeners();
  }

  Future<bool> removeDestination(int dayIndex, int destIndex) async {
    try {
      final removed = trip.itinerary[dayIndex].destinations.removeAt(destIndex);

      final updated = Set<String>.from(_state.expandedDestinations)
        ..remove(removed.name);

      _state = _state.copyWith(expandedDestinations: updated);
      notifyListeners();

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'itinerary': trip.itinerary.map((e) => e.toJson()).toList(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDay(int dayIndex) async {
    try {
      trip.itinerary[dayIndex].destinations.clear();
      _state = _state.copyWith(expandedDestinations: {});
      notifyListeners();

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'itinerary': trip.itinerary.map((e) => e.toJson()).toList(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildTravelKey({
    required double oLat,
    required double oLng,
    required double dLat,
    required double dLng,
    required TransportationType mode,
  }) {
    return '$oLat,$oLng->$dLat,$dLng:${mode.name}';
  }

  Future<Map<String, String>?> getTravelInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required TransportationType preferredTransport,
  }) async {
    final key = _buildTravelKey(
      oLat: originLat,
      oLng: originLng,
      dLat: destLat,
      dLng: destLng,
      mode: preferredTransport,
    );

    // ===== RETURN CACHE IF EXISTS =====
    if (_travelCache.containsKey(key)) {
      return _travelCache[key];
    }

    final mode = preferredTransport.googleMode;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&mode=$mode'
      '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body);
      if (data['status'] != 'OK') return null;

      final leg = data['routes'][0]['legs'][0];
      final Map<String, String> result = {
        'distance': leg['distance']['text'].toString(),
        'duration': leg['duration']['text'].toString(),
        'mode': mode.toString(),
      };

      // ===== SAVE TO CACHE =====
      _travelCache[key] = result;

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<bool> generateSingleDay(int dayIndex) async {
    try {
      final prompt = '''
You are a professional travel planner. Your task is to generate a precise list of tourist attractions in ${trip.location} for one day.

Each day should have 3-5 destinations and **fully utilized** with realistic visit durations.
Prioritize must-visit places but **reorder them for optimal routing**.
Use **precise place names**, avoiding nicknames or abbreviations.
Make each day's destinations **geographically logical**. Cluster nearby locations together and do not split adjacent spots into different days.

Return a valid JSON array only, no explanation or markdown:
[
  {
    "name": "Place Name",
    "description": "Detail description",
    "durationMinutes": 90,
  }
]

''';

      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      final content =
          jsonDecode(
                utf8.decode(res.bodyBytes),
              )['choices'][0]['message']['content']
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

      final List<dynamic> places = jsonDecode(content);

      final List<Destination> newDest = [];
      final existingNames =
          trip.itinerary
              .expand((d) => d.destinations)
              .map((d) => d.name.toLowerCase().trim())
              .toSet();

      for (final p in places) {
        final normalized = p['name'].toString().toLowerCase().trim();
        if (existingNames.contains(normalized)) continue;
        final search = await googlePlace.search.getTextSearch(
          '${p['name']}, ${trip.location}',
        );
        final match = search?.results?.first;
        if (match == null) continue;

        final detail = await googlePlace.details.get(match.placeId!);
        final result = detail?.result;
        if (result == null) continue;

        String? imageUrl;
        if (result.photos?.isNotEmpty == true) {
          imageUrl = await PlaceImageCacheService.cachePlacePhoto(
            photoReference: result.photos!.first.photoReference!,
            path: 'destinations/${trip.id}/${result.placeId}.jpg',
          );
        }
        final exists = trip.itinerary
            .expand((d) => d.destinations)
            .any((d) => d.placeId == result.placeId);

        if (exists) continue;
        existingNames.add(normalized);

        newDest.add(
          Destination(
            placeId: result.placeId!,
            name: result.name!,
            description: p['description'],
            durationMinutes: p['durationMinutes'],
            latitude: result.geometry!.location!.lat!,
            longitude: result.geometry!.location!.lng!,
            address: result.formattedAddress ?? '',
            imageUrl: imageUrl,
          ),
        );
      }

      trip.itinerary[dayIndex].destinations.addAll(newDest);

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'itinerary': trip.itinerary.map((e) => e.toJson()).toList(),
      });
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCoverFromDevice() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return false;

      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child(
        'trip_covers/${trip.id}.jpg',
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      trip.coverImageUrl = url;

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'coverImageUrl': url,
      });

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openDirections(
    double oLat,
    double oLng,
    double dLat,
    double dLng,
    String mode,
  ) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$oLat,$oLng&destination=$dLat,$dLng&travelmode=$mode',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> addDestinationFromSearch(
    int dayIndex,
    AutocompletePrediction prediction,
  ) async {
    final placeId = prediction.placeId!;
    final details = await googlePlace.details.get(placeId);
    final result = details?.result;
    if (result == null) return false;
    final exists = trip.itinerary
        .expand((d) => d.destinations)
        .any((d) => d.placeId == result.placeId);
    if (exists) return false;
    // ==== AI call ====
    final aiResponse = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'user',
            'content':
                'You are a travel planner. Provide a short description and estimated visit duration for: ${result.name}, ${result.formattedAddress}. Return JSON: {"description":"...","durationMinutes":60}',
          },
        ],
        'temperature': 0.7,
      }),
    );

    final aiText = utf8.decode(aiResponse.bodyBytes);
    final content =
        jsonDecode(aiText)['choices'][0]['message']['content']
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

    final aiData = jsonDecode(content);

    // ==== Image ====
    String? imageUrl;
    if (result.photos?.isNotEmpty == true) {
      imageUrl = await PlaceImageCacheService.cachePlacePhoto(
        photoReference: result.photos!.first.photoReference!,
        path: 'destinations/${trip.id}/${result.placeId}.jpg',
      );
    }

    // ==== Build Destination ====
    final newDest = Destination(
      placeId: result.placeId ?? '',
      name: result.name ?? 'Unnamed',
      address: result.formattedAddress ?? '',
      description: aiData['description'],
      durationMinutes: aiData['durationMinutes'],
      latitude: result.geometry?.location?.lat ?? 0.0,
      longitude: result.geometry?.location?.lng ?? 0.0,
      imageUrl: imageUrl,
      rating: result.rating,
      userRatingsTotal: result.userRatingsTotal,
      website: result.website,
      openingHours: result.openingHours?.weekdayText,
      types: result.types,
      url: result.url,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(
        Duration(minutes: aiData['durationMinutes'] ?? 60),
      ),
    );

    // ==== Save ====
    trip.itinerary[dayIndex].destinations.add(newDest);

    await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
      'itinerary': trip.itinerary.map((e) => e.toJson()).toList(),
    });
    notifyListeners();
    return true;
  }

  Future<bool> updateCoverFromGooglePhoto(String photoReference) async {
    try {
      final firebaseUrl = await PlaceImageCacheService.cachePlacePhoto(
        photoReference: photoReference,
        path: 'trip_covers/${trip.id}.jpg',
      );

      if (firebaseUrl == null) return false;

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'coverImageUrl': firebaseUrl,
      });

      trip.coverImageUrl = firebaseUrl;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LatLon?> getTripCoordinates() async {
    final geocode = await googlePlace.search.getTextSearch(trip.location);
    if (geocode?.results?.isNotEmpty ?? false) {
      final loc = geocode!.results!.first.geometry!.location!;
      return LatLon(loc.lat!, loc.lng!);
    }
    return null;
  }

  Future<List<AutocompletePrediction>> searchDestinationInTrip(
    String query,
  ) async {
    final coords = await getTripCoordinates();
    if (coords == null) return [];

    final res = await googlePlace.autocomplete.get(
      query,
      location: coords,
      radius: 100000,
      strictbounds: true,
    );
    return res?.predictions ?? [];
  }

  Future<List<String>> getTripPhotoReferences() async {
    final search = await googlePlace.search.getTextSearch(trip.location);
    if (search?.results?.isEmpty ?? true) return [];

    final placeId = search!.results!.first.placeId!;
    final detail = await googlePlace.details.get(placeId);
    final photos = detail?.result?.photos;

    if (photos == null || photos.isEmpty) return [];

    return photos.map((p) => p.photoReference!).toList();
  }

  Future<bool> changeDateRange(DateTime start, DateTime end) async {
    try {
      final oldDays = trip.itinerary;
      final oldLength = oldDays.length;
      final newLength = end.difference(start).inDays + 1;

      final newItinerary = List.generate(newLength, (i) {
        final date = start.add(Duration(days: i));
        if (i < oldLength) {
          return ItineraryDay(
            date: date,
            destinations: oldDays[i].destinations,
          );
        }
        return ItineraryDay(date: date, destinations: []);
      });

      trip.startDate = start;
      trip.endDate = end;
      trip.itinerary = newItinerary;

      await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'itinerary': newItinerary.map((e) => e.toJson()).toList(),
      });

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
