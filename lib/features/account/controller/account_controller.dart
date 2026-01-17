import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itinerme/features/account/state/account_state.dart';

class AccountController extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final ImagePicker _picker = ImagePicker();

  AccountState _state = const AccountState();
  AccountState get state => _state;

  AccountController({required this.firestore, required this.storage});

  Future<void> pickAndUploadAvatar(String userId) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    _state = _state.copyWith(isUploading: true);
    notifyListeners();

    try {
      final imageFile = File(file.path);

      final ref = storage.ref().child('user_avatars/$userId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      await firestore.collection('users').doc(userId).update({
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _state = _state.copyWith(isUploading: false, avatarUrl: url);
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isUploading: false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
