import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';

import 'place_image_cache_service.dart';

class GooglePlaceService {
  final GooglePlace place = GooglePlace(dotenv.env['GOOGLE_MAPS_API_KEY']!);

  // AUTOCOMPLETE SEARCH
  Future<List<AutocompletePrediction>> autocomplete(
    String query, {
    LatLon? loc,
  }) async {
    final res = await place.autocomplete.get(
      query,
      location: loc, // null nếu chưa có
      radius: loc == null ? null : 100000,
      strictbounds: false, // <<< QUAN TRỌNG
    );

    return res?.predictions ?? [];
  }

  // GET PLACE DETAILS
  Future<DetailsResult?> getDetails(String placeId) async {
    final res = await place.details.get(placeId);
    return res?.result;
  }

  // GET LOCATION COORDINATES
  Future<LatLon?> getLocationCoords(String locationName) async {
    final res = await place.search.getTextSearch(locationName);
    if (res?.results?.isNotEmpty ?? false) {
      final loc = res!.results!.first.geometry!.location!;
      return LatLon(loc.lat!, loc.lng!);
    }
    return null;
  }

  // FIND BEST MATCH FROM TEXT
  Future<DetailsResult?> findBestMatchFromText(String query) async {
    final search = await place.search.getTextSearch(query);
    final match = search?.results?.first;
    if (match?.placeId == null) return null;

    final detail = await place.details.get(match!.placeId!);
    return detail?.result;
  }

  // GET FIRST PHOTO CACHED URL
  Future<String?> getFirstPhotoCachedUrl({
    required String tripId,
    required String placeId,
    required List<Photo>? photos,
  }) async {
    if (photos == null || photos.isEmpty) return null;

    return PlaceImageCacheService.cachePlacePhoto(
      photoReference: photos.first.photoReference!,
      path: 'destinations/$tripId/$placeId.jpg',
    );
  }

  // GET PHOTO REFERENCES FROM LOCATION
  Future<List<String>> getPhotoReferencesFromLocation(
    String locationName,
  ) async {
    final search = await place.search.getTextSearch(locationName);
    if (search?.results?.isEmpty ?? true) return [];

    final placeId = search!.results!.first.placeId!;
    final detail = await place.details.get(placeId);
    final photos = detail?.result?.photos;
    if (photos == null || photos.isEmpty) return [];

    return photos.map((p) => p.photoReference!).toList();
  }
}
