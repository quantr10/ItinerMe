import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/enums/transportation_enums.dart';
import '../../../core/enums/interest_tag_enums.dart';
import '../../../core/models/must_visit_place.dart';

import '../../../core/services/google_place_service.dart';
import '../../../core/services/trip_ai_service.dart';
import '../../../core/repositories/trip_repository.dart';

import '../state/create_trip_state.dart';

class CreateTripController extends ChangeNotifier {
  final GooglePlaceService googlePlaceService;
  final TripAIService tripAIService;
  final TripRepository tripRepository;

  CreateTripController({
    required this.googlePlaceService,
    required this.tripAIService,
    required this.tripRepository,
  });

  CreateTripState _state = const CreateTripState();
  CreateTripState get state => _state;

  // DESTINATION SEARCH
  Future<void> searchDestination(String value) async {
    if (value.isEmpty) {
      _state = _state.copyWith(destinationPredictions: []);
      notifyListeners();
      return;
    }

    final predictions = await googlePlaceService.autocomplete(value);

    _state = _state.copyWith(destinationPredictions: predictions);
    notifyListeners();
  }

  // SELECT DESTINATION
  Future<void> selectDestination(AutocompletePrediction prediction) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await googlePlaceService.getDetails(prediction.placeId!);
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

  // MUST VISIT PLACES
  Future<void> searchMustVisit(String value) async {
    if (value.isEmpty || _state.selectedDestinationCoordinates == null) {
      _state = _state.copyWith(mustVisitPredictions: []);
      notifyListeners();
      return;
    }

    final predictions = await googlePlaceService.autocomplete(
      value,
      loc: _state.selectedDestinationCoordinates!,
    );

    _state = _state.copyWith(mustVisitPredictions: predictions);
    notifyListeners();
  }

  Future<void> selectMustVisit(AutocompletePrediction prediction) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await googlePlaceService.getDetails(prediction.placeId!);
    final name = result?.name;
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

  // INTEREST TAGS
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

  // DATE RANGE
  void setDateRange(DateTime start, DateTime end) {
    _state = _state.copyWith(startDate: start, endDate: end);
    notifyListeners();
  }

  // TRANSPORTATION
  void setTransportation(TransportationType value) {
    _state = _state.copyWith(transportation: value);
    notifyListeners();
  }

  // SUBMIT TRIP CREATION
  Future<void> submitTrip({
    required String tripName,
    required int budget,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final trip = await tripRepository.createTrip(
        tripName: tripName,
        budget: budget,
        locationName: _state.selectedDestinationName!,
        startDate: _state.startDate!,
        endDate: _state.endDate!,
        transportation: _state.transportation!,
        interests: _state.interests.map((e) => e.label).toList(),
        mustVisitPlaces: _state.mustVisitPlaces,
        coverPhotoReference: _state.coverPhotoReference,
      );

      final itinerary = await tripAIService.generateItinerary(trip);

      await tripRepository.attachItinerary(trip.id, itinerary);

      _state = const CreateTripState(submitSuccess: true);
      AppTheme.success('Trip created successfully!');
    } catch (_) {
      AppTheme.error('Failed to create trip');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // RESET SUBMIT FLAG
  void resetSubmitFlag() {
    _state = _state.copyWith(submitSuccess: false);
    notifyListeners();
  }
}
