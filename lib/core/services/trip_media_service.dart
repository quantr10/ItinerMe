import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'place_image_cache_service.dart';

class TripMediaService {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();

  // UPLOAD COVER FROM DEVICE
  Future<String?> uploadFromDevice(String tripId) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final ref = storage.ref('trip_covers/$tripId.jpg');
    await ref.putFile(File(picked.path));
    return await ref.getDownloadURL();
  }

  // UPLOAD COVER FROM GOOGLE PLACE PHOTO
  Future<String?> uploadFromGoogle(String tripId, String photoRef) {
    return PlaceImageCacheService.cachePlacePhoto(
      photoReference: photoRef,
      path: 'trip_covers/$tripId.jpg',
    );
  }
}
