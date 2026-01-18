import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TravelService {
  final Map<String, Map<String, String>> _cache = {};

  // BUILD CACHE KEY
  String _key(oLat, oLng, dLat, dLng, mode) => '$oLat,$oLng->$dLat,$dLng:$mode';

  // GET DIRECTIONS
  Future<Map<String, String>?> getDirections({
    required double oLat,
    required double oLng,
    required double dLat,
    required double dLng,
    required String mode,
  }) async {
    final key = _key(oLat, oLng, dLat, dLng, mode);
    if (_cache.containsKey(key)) return _cache[key];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$oLat,$oLng&destination=$dLat,$dLng'
      '&mode=$mode&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    if (data['status'] != 'OK') return null;

    final leg = data['routes'][0]['legs'][0];
    final Map<String, String> result = {
      'distance': leg['distance']['text'].toString(),
      'duration': leg['duration']['text'].toString(),
    };

    _cache[key] = result;
    return result;
  }
}
