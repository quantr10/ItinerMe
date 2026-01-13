import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itinerme/core/models/itinerary_day.dart';
import 'package:itinerme/core/models/must_visit_place.dart';

class Trip {
  String id;
  String name;
  String location;
  String coverImageUrl;
  int budget;
  DateTime startDate;
  DateTime endDate;
  String transportation;
  List<String> interests;
  List<MustVisitPlace> mustVisitPlaces;
  List<ItineraryDay> itinerary;

  Trip({
    required this.id,
    required this.name,
    required this.location,
    required this.coverImageUrl,
    required this.budget,
    required DateTime startDate,
    required DateTime endDate,
    required this.transportation,
    required this.interests,
    required this.mustVisitPlaces,
    required this.itinerary,
  }) : startDate = DateTime(
         startDate.year,
         startDate.month,
         startDate.day,
         0,
         0,
       ),
       endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'coverImageUrl': coverImageUrl,
    'budget': budget,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'transportation': transportation,
    'interests': interests,
    'mustVisitPlaces': mustVisitPlaces.map((e) => e.toJson()).toList(),
    'itinerary': itinerary.map((e) => e.toJson()).toList(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'],
    name: json['name'],
    location: json['location'],
    coverImageUrl: json['coverImageUrl'],
    budget: json['budget'],
    startDate:
        json['startDate'] is Timestamp
            ? (json['startDate'] as Timestamp).toDate()
            : DateTime.parse(json['startDate']),
    endDate:
        json['endDate'] is Timestamp
            ? (json['endDate'] as Timestamp).toDate()
            : DateTime.parse(json['endDate']),
    transportation: json['transportation'],
    interests: List<String>.from(json['interests']),
    mustVisitPlaces:
        (json['mustVisitPlaces'] as List)
            .map((e) => MustVisitPlace.fromJson(e))
            .toList(),
    itinerary:
        (json['itinerary'] as List)
            .map((e) => ItineraryDay.fromJson(e))
            .toList(),
  );

  Trip copyWith({
    String? id,
    String? name,
    String? location,
    String? coverImageUrl,
    int? budget,
    DateTime? startDate,
    DateTime? endDate,
    String? transportation,
    List<String>? interests,
    List<MustVisitPlace>? mustVisitPlaces,
    List<ItineraryDay>? itinerary,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      budget: budget ?? this.budget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transportation: transportation ?? this.transportation,
      interests: interests ?? this.interests,
      mustVisitPlaces: mustVisitPlaces ?? this.mustVisitPlaces,
      itinerary: itinerary ?? this.itinerary,
    );
  }
}
