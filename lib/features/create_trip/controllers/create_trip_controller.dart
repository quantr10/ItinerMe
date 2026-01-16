import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itinerme/core/enums/transportation_enums.dart';
import 'package:itinerme/core/theme/app_theme.dart';
import 'package:itinerme/core/enums/interest_tag_enums.dart';

import '../../../core/models/trip.dart';
import '../../../core/models/must_visit_place.dart';
import '../../../core/services/place_image_cache_service.dart';
import '../state/create_trip_state.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itinerme/core/models/destination.dart';
import 'package:itinerme/core/models/itinerary_day.dart';

class CreateTripController extends ChangeNotifier {
  CreateTripState _state = const CreateTripState();
  CreateTripState get state => _state;

  static final GooglePlace googlePlace = GooglePlace(
    dotenv.env['GOOGLE_MAPS_API_KEY']!,
  );

  // ---------------- DESTINATION ----------------

  Future<void> searchDestination(String value) async {
    if (value.isEmpty) {
      _state = _state.copyWith(destinationPredictions: []);
      notifyListeners();
      return;
    }

    final result = await googlePlace.autocomplete.get(
      value,
      types: '(regions)',
    );

    _state = _state.copyWith(destinationPredictions: result?.predictions ?? []);
    notifyListeners();
  }

  Future<void> selectDestination(AutocompletePrediction prediction) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final details = await googlePlace.details.get(prediction.placeId ?? '');
    final result = details?.result;
    if (result == null) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      selectedDestinationName: result.name,
      selectedDestinationCoordinates: LatLon(
        result.geometry!.location!.lat!,
        result.geometry!.location!.lng!,
      ),
      destinationPredictions: [],
      mustVisitPlaces: [],
      mustVisitPredictions: [],
      coverPhotoReference:
          result.photos?.isNotEmpty == true
              ? result.photos!.first.photoReference
              : null,
      isLoading: false,
    );
    notifyListeners();
  }

  // ---------------- MUST VISIT ----------------

  Future<void> searchMustVisit(String value) async {
    if (value.isEmpty || _state.selectedDestinationCoordinates == null) {
      _state = _state.copyWith(mustVisitPredictions: []);
      notifyListeners();
      return;
    }

    final result = await googlePlace.autocomplete.get(
      value,
      location: _state.selectedDestinationCoordinates!,
      radius: 100000,
      strictbounds: true,
    );

    _state = _state.copyWith(mustVisitPredictions: result?.predictions ?? []);
    notifyListeners();
  }

  Future<void> selectMustVisit(AutocompletePrediction prediction) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final details = await googlePlace.details.get(prediction.placeId ?? '');
    final name = details?.result?.name;
    if (name == null) return;

    final updated = List<MustVisitPlace>.from(_state.mustVisitPlaces)
      ..add(MustVisitPlace(name: name, placeId: prediction.placeId!));

    _state = _state.copyWith(
      mustVisitPlaces: updated,
      mustVisitPredictions: [],
      isLoading: false,
    );
    notifyListeners();
  }

  void removeMustVisit(MustVisitPlace place) {
    final updated = List<MustVisitPlace>.from(_state.mustVisitPlaces)
      ..remove(place);
    _state = _state.copyWith(mustVisitPlaces: updated);
    notifyListeners();
  }

  // ---------------- INTERESTS ----------------

  void searchInterests(String value, List<InterestTag> availableTags) {
    final lower = value.toLowerCase();

    final predictions =
        value.isEmpty
            ? <InterestTag>[]
            : availableTags
                .where((t) => t.label.toLowerCase().contains(lower))
                .toList();

    _state = _state.copyWith(interestPredictions: predictions);
    notifyListeners();
  }

  void addInterest(InterestTag tag) {
    final updated = List<InterestTag>.from(_state.interests);
    if (!updated.contains(tag)) updated.add(tag);

    _state = _state.copyWith(interests: updated, interestPredictions: []);
    notifyListeners();
  }

  void removeInterest(InterestTag tag) {
    final updated = List<InterestTag>.from(_state.interests)..remove(tag);
    _state = _state.copyWith(interests: updated);
    notifyListeners();
  }

  // ---------------- DATE ----------------

  void setDateRange(DateTime start, DateTime end) {
    _state = _state.copyWith(startDate: start, endDate: end);
    notifyListeners();
  }

  // ---------------- TRANSPORT ----------------

  void setTransportation(TransportationType value) {
    _state = _state.copyWith(transportation: value);
    notifyListeners();
  }

  // ---------------- SUBMIT ----------------

  Future<void> submitTrip({
    required String tripName,
    required int budget,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final tripRef = FirebaseFirestore.instance.collection('trips').doc();

      String coverUrl =
          'https://images.unsplash.com/photo-1542038784456-1ea8e935640e';

      if (_state.coverPhotoReference != null) {
        final cached = await PlaceImageCacheService.cachePlacePhoto(
          photoReference: _state.coverPhotoReference!,
          path: 'trip_covers/${tripRef.id}.jpg',
        );
        if (cached != null) coverUrl = cached;
      }

      final trip = Trip(
        id: tripRef.id,
        name: tripName,
        location: _state.selectedDestinationName!,
        coverImageUrl: coverUrl,
        budget: budget,
        startDate: _state.startDate!,
        endDate: _state.endDate!,
        transportation: _state.transportation!,
        interests: _state.interests.map((e) => e.label).toList(),
        mustVisitPlaces: _state.mustVisitPlaces,
        itinerary: [],
      );

      await tripRef.set(trip.toJson());

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'createdTripIds': FieldValue.arrayUnion([tripRef.id]),
        },
      );

      final itinerary = await generateItinerary(trip);

      await tripRef.update({
        'itinerary': itinerary.map((e) => e.toJson()).toList(),
      });

      _state = const CreateTripState(submitSuccess: true);
      notifyListeners();

      AppTheme.success('Trip created successfully!');
    } catch (e) {
      AppTheme.error('Failed to create trip');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void resetSubmitFlag() {
    _state = _state.copyWith(submitSuccess: false);
    notifyListeners();
  }

  // --
  static Future<List<ItineraryDay>> generateItinerary(Trip trip) async {
    final prompt = buildPromptFromTrip(trip);

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4",
        "temperature": 0.8,
        "messages": [
          {"role": "user", "content": prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate ${response.body}');
    }

    final rawContent = utf8.decode(response.bodyBytes);
    final content =
        jsonDecode(rawContent)['choices'][0]['message']['content']
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

    final List<dynamic> jsonList = jsonDecode(content);
    final List<ItineraryDay> enrichedDays = [];

    final Location? tripLocation = await getTripLocationCoordinates(
      trip.location,
    );
    if (tripLocation == null)
      throw Exception('Cannot resolve ${trip.location} location');

    for (final day in jsonList) {
      final destinations = <Destination>[];

      for (final d in day['destinations']) {
        final query = "${d['name']}, ${trip.location}";
        SearchResult? matchedPlace;

        final textSearch = await googlePlace.search.getTextSearch(
          query,
          location: tripLocation,
          radius: 50000,
        );

        if (textSearch?.results != null && textSearch!.results!.isNotEmpty) {
          matchedPlace = textSearch.results!.firstWhere(
            (p) =>
                p.name != null &&
                (p.name!.toLowerCase().contains(
                      d['name'].toString().toLowerCase(),
                    ) ||
                    d['name'].toString().toLowerCase().contains(
                      p.name!.toLowerCase(),
                    )),
            orElse: () => textSearch.results!.first,
          );
        }

        DetailsResult? placeDetails;
        if (matchedPlace?.placeId != null) {
          final detailResponse = await googlePlace.details.get(
            matchedPlace!.placeId!,
          );
          placeDetails = detailResponse?.result;
        }

        String? imageUrl;

        if (placeDetails?.photos?.isNotEmpty == true) {
          imageUrl = await PlaceImageCacheService.cachePlacePhoto(
            photoReference: placeDetails!.photos!.first.photoReference!,
            path: 'destinations/${trip.id}/${matchedPlace!.placeId}.jpg',
          );
        }

        destinations.add(
          Destination(
            placeId: matchedPlace?.placeId ?? '',
            name: d['name'],
            address: placeDetails?.formattedAddress ?? '',
            description: d['description'],
            durationMinutes: d['durationMinutes'],
            latitude: placeDetails?.geometry?.location?.lat ?? 0.0,
            longitude: placeDetails?.geometry?.location?.lng ?? 0.0,
            imageUrl: imageUrl,
            types: placeDetails?.types,
            website: placeDetails?.website,
            openingHours: placeDetails?.openingHours?.weekdayText,
            rating: placeDetails?.rating,
            userRatingsTotal: placeDetails?.userRatingsTotal,
            url: placeDetails?.url,
          ),
        );
      }

      enrichedDays.add(
        ItineraryDay(
          date: DateTime.parse(day['date']),
          destinations: destinations,
        ),
      );
    }

    return enrichedDays;
  }

  static Future<Location?> getTripLocationCoordinates(
    String locationName,
  ) async {
    final result = await googlePlace.search.getTextSearch(locationName);
    if (result?.results != null && result!.results!.isNotEmpty) {
      return result.results!.first.geometry?.location;
    }
    return null;
  }

  static String buildPromptFromTrip(Trip trip) {
    return '''
  You are a professional travel planner.

  Below is the trip information provided by a user. Your task is to generate a precise list of tourist attractions.

  Destination: ${trip.location}
  Start: ${trip.startDate.toIso8601String()}
  End: ${trip.endDate.toIso8601String()}
  Budget: ${trip.budget} USD
  Transportation: ${trip.transportation.label}
  Must-Visit Places: ${trip.mustVisitPlaces.map((p) => p.name).join(', ')}
  Interests: ${trip.interests.join(', ')}

  The list starts on ${trip.startDate.toIso8601String()} and ends on ${trip.endDate.toIso8601String()}.
  Each day should have 3-5 destinations and **fully utilized** with realistic visit durations.
  Prioritize must-visit places but **reorder them for optimal routing**.
  Use **precise place names**, avoiding nicknames or abbreviations.
  Add several places, relevant to: ${trip.interests.join(', ')}, and consider major attractions.
  Make each day's destinations **geographically logical**. Cluster nearby locations together and do not split adjacent spots into different days.

  Return a valid JSON array only, no explanation or markdown:
  [
    {
      "date": "YYYY-MM-DD",
      "destinations": [
        {
          "name": "Place Name",
          "description": "Detail description",
          "durationMinutes": 90,
        }
      ]
    }
  ]

  ''';
  }
}
