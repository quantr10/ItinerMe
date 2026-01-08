import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaceImageCacheService {
  static Future<String?> cachePlacePhoto({
    required String photoReference,
    required String path,
    int maxWidth = 800,
  }) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=$maxWidth'
          '&photoreference=$photoReference'
          '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final Uint8List bytes = res.bodyBytes;

      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
