import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AccountService {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  final ImagePicker picker;

  AccountService({
    required this.firestore,
    required this.storage,
    required this.auth,
    ImagePicker? picker,
  }) : picker = picker ?? ImagePicker();

  // PICK & UPLOAD AVATAR
  Future<String?> pickAndUploadAvatar(String userId) async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final imageFile = File(file.path);

    final ref = storage.ref().child('user_avatars/$userId.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    await firestore.collection('users').doc(userId).update({
      'avatarUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  // LOGOUT
  Future<void> logout() async {
    await auth.signOut();
  }
}
