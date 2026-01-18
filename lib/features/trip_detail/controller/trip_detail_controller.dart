import 'package:google_place/google_place.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/trip_detail_state.dart';

import '../../../core/repositories/trip_repository.dart';
import '../../../core/enums/transportation_enums.dart';
import '../../../core/models/trip.dart';
import '../../../core/models/destination.dart';
import '../../../core/models/itinerary_day.dart';

import '../../../core/services/google_place_service.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/services/trip_ai_service.dart';
import '../../../core/services/trip_media_service.dart';

class TripDetailController extends ChangeNotifier {
  final Trip trip;
  final TripRepository tripRepo;
  final TripAIService aiService;
  final GooglePlaceService placeService;
  final TravelService travelService;
  final TripMediaService coverService;

  TripDetailState _state = const TripDetailState();
  TripDetailState get state => _state;

  TripDetailController({
    required this.trip,
    required this.tripRepo,
    required this.aiService,
    required this.placeService,
    required this.travelService,
    required this.coverService,
  }) {
    checkEditPermission();
  }

  // ===== PERMISSION =====
  Future<void> checkEditPermission() async {
    try {
      final createdIds = await tripRepo.getCreatedTripIds();
      _state = _state.copyWith(canEdit: createdIds.contains(trip.id));
      notifyListeners();
    } catch (_) {
      // Fail silently → default canEdit = false
    }
  }

  // EXPAND OR COLLAPSE A DESTINATION CARD
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

  // ===== REMOVE A DESTINATION FROM A GIVEN DAY =====
  Future<bool> removeDestination(int dayIndex, int destIndex) async {
    try {
      final removed = trip.itinerary[dayIndex].destinations.removeAt(destIndex);

      final updated = Set<String>.from(_state.expandedDestinations)
        ..remove(removed.name);

      _state = _state.copyWith(expandedDestinations: updated);
      notifyListeners();

      await tripRepo.updateItinerary(trip.id, trip.itinerary);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== CLEAR ALL DESTINATIONS FROM A GIVEN DAY =====
  Future<bool> deleteDay(int dayIndex) async {
    try {
      trip.itinerary[dayIndex].destinations.clear();
      _state = _state.copyWith(expandedDestinations: {});
      notifyListeners();

      await tripRepo.updateItinerary(trip.id, trip.itinerary);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== FETCHE TRAVEL DURATION & DISTANCEDISTANCE=
  Future<Map<String, String>?> getTravelInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required TransportationType preferredTransport,
  }) {
    return travelService.getDirections(
      oLat: originLat,
      oLng: originLng,
      dLat: destLat,
      dLng: destLng,
      mode: preferredTransport.googleMode,
    );
  }

  // ===== REGENERATE A SINGLE DAY WITH AI =====
  Future<bool> generateSingleDay(int dayIndex) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final places = await aiService.generateDayPlan(trip.location);

      final existingNames =
          trip.itinerary
              .expand((d) => d.destinations)
              .map((d) => d.name.toLowerCase().trim())
              .toSet();

      final List<Destination> newDest = [];

      for (final p in places) {
        final rawName = p['name']?.toString() ?? '';
        final normalized = rawName.toLowerCase().trim();
        if (normalized.isEmpty || existingNames.contains(normalized)) continue;

        final result = await placeService.findBestMatchFromText(
          '$rawName, ${trip.location}',
        );
        if (result == null || result.placeId == null) continue;

        final imageUrl = await placeService.getFirstPhotoCachedUrl(
          tripId: trip.id,
          placeId: result.placeId!,
          photos: result.photos,
        );

        final exists = trip.itinerary
            .expand((d) => d.destinations)
            .any((d) => d.placeId == result.placeId);
        if (exists) continue;

        existingNames.add(normalized);

        newDest.add(
          Destination(
            placeId: result.placeId!,
            name: result.name ?? rawName,
            description: p['description']?.toString() ?? '',
            durationMinutes: (p['durationMinutes'] as num?)?.toInt() ?? 60,
            latitude: result.geometry?.location?.lat ?? 0.0,
            longitude: result.geometry?.location?.lng ?? 0.0,
            address: result.formattedAddress ?? '',
            imageUrl: imageUrl,
          ),
        );
      }

      trip.itinerary[dayIndex].destinations.addAll(newDest);
      await tripRepo.updateItinerary(trip.id, trip.itinerary);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // ===== UPLOAD COVER IMAGE FROM DEVICE=====
  Future<bool> updateCoverFromDevice() async {
    try {
      final url = await coverService.uploadFromDevice(trip.id);
      if (url == null) return false;

      trip.coverImageUrl = url;
      await tripRepo.updateCover(trip.id, url);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== UPLOAD COVER IMAGE FROM GOOGLE=====
  Future<bool> updateCoverFromGooglePhoto(String photoReference) async {
    try {
      final url = await coverService.uploadFromGoogle(trip.id, photoReference);
      if (url == null) return false;

      trip.coverImageUrl = url;
      await tripRepo.updateCover(trip.id, url);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== OPEN GOOGLE MAPS =====
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

  // ===== ADD DESTINATION MANUALLY =====
  Future<bool> addDestinationFromSearch(
    int dayIndex,
    AutocompletePrediction prediction,
  ) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final placeId = prediction.placeId!;
      final details = await placeService.getDetails(placeId);
      if (details == null) return false;

      final exists = trip.itinerary
          .expand((d) => d.destinations)
          .any((d) => d.placeId == details.placeId);
      if (exists) return false;

      final aiData = await aiService.generatePlaceInfo(
        details.name ?? 'Unnamed',
        details.formattedAddress ?? '',
      );

      final imageUrl = await placeService.getFirstPhotoCachedUrl(
        tripId: trip.id,
        placeId: details.placeId!,
        photos: details.photos,
      );

      final newDest = Destination(
        placeId: details.placeId ?? '',
        name: details.name ?? 'Unnamed',
        address: details.formattedAddress ?? '',
        description: aiData['description']?.toString() ?? '',
        durationMinutes: (aiData['durationMinutes'] as num?)?.toInt() ?? 60,
        latitude: details.geometry?.location?.lat ?? 0.0,
        longitude: details.geometry?.location?.lng ?? 0.0,
        imageUrl: imageUrl,
        rating: details.rating,
        userRatingsTotal: details.userRatingsTotal,
        website: details.website,
        openingHours: details.openingHours?.weekdayText,
        types: details.types,
        url: details.url,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(
          Duration(minutes: (aiData['durationMinutes'] as num?)?.toInt() ?? 60),
        ),
      );

      trip.itinerary[dayIndex].destinations.add(newDest);
      await tripRepo.updateItinerary(trip.id, trip.itinerary);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // ===== GET TRIP COORDINATES =====
  Future<LatLon?> getTripCoordinates() {
    return placeService.getLocationCoords(trip.location);
  }

  Future<List<AutocompletePrediction>> searchDestinationInTrip(
    String query,
  ) async {
    final coords = await getTripCoordinates();
    if (coords == null) return [];
    return placeService.autocomplete(query, loc: coords);
  }

  Future<List<String>> getTripPhotoReferences() async {
    return placeService.getPhotoReferencesFromLocation(trip.location);
  }

  // ===== CHANGE DATE RANGE =====
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

      await tripRepo.updateDates(trip.id, start, end, newItinerary);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
