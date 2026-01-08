import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itinerme/features/trip/models/destination.dart';

class ItineraryDay {
  final DateTime date;
  final List<Destination> destinations;

  ItineraryDay({required this.date, required this.destinations});

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'destinations': destinations.map((e) => e.toJson()).toList(),
  };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
    date:
        json['date'] is Timestamp
            ? (json['date'] as Timestamp).toDate()
            : DateTime.parse(json['date']),
    destinations:
        (json['destinations'] as List)
            .map((e) => Destination.fromJson(e))
            .toList(),
  );
}
