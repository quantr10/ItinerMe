import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../user/services/user_service.dart';
import '../../../core/models/user.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  Future<void> loginEmail({
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception("No user");

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      final newUser = UserModel(
        id: user.uid,
        name: user.email!.split('@').first,
        email: user.email!,
        avatarUrl: user.photoURL ?? '',
        createdTripIds: [],
        savedTripIds: [],
      );
      await doc.set(newUser.toJson());
    }
  }

  Future<void> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Cancelled by user');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('No user returned');

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      final displayName =
          user.displayName ??
          user.email?.split('@').first ??
          'User${user.uid.substring(0, 6)}';

      final newUser = UserModel(
        id: user.uid,
        name: displayName,
        email: user.email ?? '',
        avatarUrl: user.photoURL ?? '',
        createdTripIds: [],
        savedTripIds: [],
      );

      await doc.set(newUser.toJson());
    }
  }

  Future<void> signUpEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) return;

    final userModel = UserModel(
      id: user.uid,
      name: username.trim(),
      email: user.email ?? '',
      avatarUrl: '',
      createdTripIds: const [],
      savedTripIds: const [],
    );

    await _userService.createOrUpdateUser(userModel);
  }
}
