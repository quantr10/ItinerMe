import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';
import 'package:itinerme/features/trip/models/destination.dart';
import 'package:itinerme/features/trip/models/itinerary_day.dart';
import 'package:itinerme/features/trip/services/place_image_cache_service.dart';
import '../models/trip.dart';

class ItineraryGeneratorService {
  static final GooglePlace googlePlace = GooglePlace(
    dotenv.env['GOOGLE_MAPS_API_KEY']!,
  );

  static Future<List<ItineraryDay>> generateItinerary(Trip trip) async {
    final prompt = _buildPromptFromTrip(trip);

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

  static String _buildPromptFromTrip(Trip trip) {
    return '''
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
  }
}
