import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  String placeId;
  String name;
  String address;
  String description;
  double latitude;
  double longitude;
  int durationMinutes;
  DateTime? startTime;
  DateTime? endTime;
  List<String>? types;
  String? website;
  List<String>? openingHours;
  double? rating;
  int? userRatingsTotal;
  String? url;
  String? imageUrl; // NEW (Firebase URL)

  Destination({
    required this.placeId,
    required this.name,
    required this.address,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    this.types,
    this.website,
    this.openingHours,
    this.rating,
    this.userRatingsTotal,
    this.url,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'placeId': placeId,
      'name': name,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'durationMinutes': durationMinutes,
      'types': types,
      'website': website,
      'openingHours': openingHours,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'url': url,
    };

    if (startTime != null) {
      map['startTime'] = Timestamp.fromDate(startTime!);
    }
    if (endTime != null) {
      map['endTime'] = Timestamp.fromDate(endTime!);
    }

    return map;
  }

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    placeId: json['placeId'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    description: json['description'] ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    imageUrl: json['imageUrl'],
    durationMinutes: json['durationMinutes'] ?? 0,
    startTime:
        json['startTime'] != null
            ? (json['startTime'] is Timestamp
                ? (json['startTime'] as Timestamp).toDate()
                : DateTime.tryParse(json['startTime']))
            : null,
    endTime:
        json['endTime'] != null
            ? (json['endTime'] is Timestamp
                ? (json['endTime'] as Timestamp).toDate()
                : DateTime.tryParse(json['endTime']))
            : null,
    types: json['types'] != null ? List<String>.from(json['types']) : null,
    website: json['website'],
    openingHours:
        json['openingHours'] != null
            ? List<String>.from(json['openingHours'])
            : null,
    rating: (json['rating'] as num?)?.toDouble(),
    userRatingsTotal: json['userRatingsTotal'],
    url: json['url'],
  );

  Destination copyWith({
    String? placeId,
    String? name,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? types,
    String? website,
    List<String>? openingHours,
    double? rating,
    int? userRatingsTotal,
    String? url,
  }) {
    return Destination(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      types: types ?? this.types,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      url: url ?? this.url,
    );
  }
}
