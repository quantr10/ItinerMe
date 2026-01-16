import 'package:google_place/google_place.dart';
import 'package:itinerme/core/enums/transportation_enums.dart';
import '../../../core/enums/interest_tag_enums.dart';
import '../../../core/models/must_visit_place.dart';

class CreateTripState {
  final List<InterestTag> interests;
  final List<MustVisitPlace> mustVisitPlaces;
  final List<AutocompletePrediction> destinationPredictions;
  final List<AutocompletePrediction> mustVisitPredictions;
  final List<InterestTag> interestPredictions;

  final DateTime? startDate;
  final DateTime? endDate;
  final TransportationType? transportation;
  final bool isLoading;

  final LatLon? selectedDestinationCoordinates;
  final String? selectedDestinationName;
  final String? coverPhotoReference;

  final bool submitSuccess;

  const CreateTripState({
    this.interests = const [],
    this.mustVisitPlaces = const [],
    this.destinationPredictions = const [],
    this.mustVisitPredictions = const [],
    this.interestPredictions = const [],
    this.startDate,
    this.endDate,
    this.transportation,
    this.isLoading = false,
    this.selectedDestinationCoordinates,
    this.selectedDestinationName,
    this.coverPhotoReference,
    this.submitSuccess = false,
  });

  CreateTripState copyWith({
    List<InterestTag>? interests,
    List<MustVisitPlace>? mustVisitPlaces,
    List<AutocompletePrediction>? destinationPredictions,
    List<AutocompletePrediction>? mustVisitPredictions,
    List<InterestTag>? interestPredictions,
    DateTime? startDate,
    DateTime? endDate,
    TransportationType? transportation,
    bool? isLoading,
    LatLon? selectedDestinationCoordinates,
    String? selectedDestinationName,
    String? coverPhotoReference,
    bool? submitSuccess,
  }) {
    return CreateTripState(
      interests: interests ?? this.interests,
      mustVisitPlaces: mustVisitPlaces ?? this.mustVisitPlaces,
      destinationPredictions:
          destinationPredictions ?? this.destinationPredictions,
      mustVisitPredictions: mustVisitPredictions ?? this.mustVisitPredictions,
      interestPredictions: interestPredictions ?? this.interestPredictions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transportation: transportation ?? this.transportation,
      isLoading: isLoading ?? this.isLoading,
      selectedDestinationCoordinates:
          selectedDestinationCoordinates ?? this.selectedDestinationCoordinates,
      selectedDestinationName:
          selectedDestinationName ?? this.selectedDestinationName,
      coverPhotoReference: coverPhotoReference ?? this.coverPhotoReference,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
