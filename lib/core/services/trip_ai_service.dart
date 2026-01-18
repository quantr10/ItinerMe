import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';
import '../models/itinerary_day.dart';
import '../models/destination.dart';
import 'place_image_cache_service.dart';

class TripAIService {
  final String _openAiKey = dotenv.env['OPENAI_API_KEY']!;
  final GooglePlace _googlePlace = GooglePlace(
    dotenv.env['GOOGLE_MAPS_API_KEY']!,
  );

  // GENERATE FULL ITINERARY
  Future<List<ItineraryDay>> generateItinerary(Trip trip) async {
    final prompt = '''
You are a professional travel planner.

Below is the trip information provided by a user. Your task is to generate a precise list of tourist attractions.

Destination: ${trip.location}
Start: ${trip.startDate.toIso8601String()}
End: ${trip.endDate.toIso8601String()}
Budget: ${trip.budget} USD
Transportation: ${trip.transportation}
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
    final response = await _callOpenAI(prompt);

    final List<dynamic> jsonList = jsonDecode(response);

    final Location? tripLocation = await _getTripLocationCoordinates(
      trip.location,
    );

    if (tripLocation == null) {
      throw Exception('Cannot resolve ${trip.location}');
    }

    final List<ItineraryDay> enrichedDays = [];

    for (final day in jsonList) {
      final destinations = <Destination>[];

      for (final d in day['destinations']) {
        final destination = await _enrichDestination(d, trip, tripLocation);
        destinations.add(destination);
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

  // GENERATE DAY PLAN (LIGHT AI)
  Future<List<Map<String, dynamic>>> generateDayPlan(String location) async {
    final prompt = '''
You are a professional travel planner. Your task is to generate a precise list of tourist attractions in $location for one day.

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

    final response = await _callOpenAI(prompt);
    return List<Map<String, dynamic>>.from(jsonDecode(response));
  }

  // GENERATE PLACE INFO
  Future<Map<String, dynamic>> generatePlaceInfo(
    String name,
    String address,
  ) async {
    final prompt =
        'Give description & duration for $name at $address. Return JSON {"description":"...","durationMinutes":60}';

    final response = await _callOpenAI(prompt);
    return jsonDecode(response);
  }

  // CALL OPENAI CORE
  Future<String> _callOpenAI(String prompt) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openAiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'temperature': 0.8,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('OpenAI error: ${res.body}');
    }

    final raw =
        jsonDecode(
          utf8.decode(res.bodyBytes),
        )['choices'][0]['message']['content'];

    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  // ENRICH DESTINATION
  Future<Destination> _enrichDestination(
    dynamic d,
    Trip trip,
    Location tripLocation,
  ) async {
    final query = "${d['name']}, ${trip.location}";

    SearchResult? matchedPlace;

    final textSearch = await _googlePlace.search.getTextSearch(
      query,
      location: tripLocation,
      radius: 50000,
    );

    if (textSearch?.results?.isNotEmpty ?? false) {
      matchedPlace = textSearch!.results!.first;
    }

    DetailsResult? placeDetails;
    if (matchedPlace?.placeId != null) {
      final detailResponse = await _googlePlace.details.get(
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

    return Destination(
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
    );
  }

  // GET TRIP LOCATION COORDINATES
  Future<Location?> _getTripLocationCoordinates(String locationName) async {
    final result = await _googlePlace.search.getTextSearch(locationName);

    if (result?.results?.isNotEmpty ?? false) {
      return result!.results!.first.geometry!.location;
    }
    return null;
  }
}
