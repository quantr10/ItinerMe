// core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;
  final UserRepository userRepository;

  AuthService({
    required this.auth,
    required this.userRepository,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn = googleSignIn ?? GoogleSignIn();

  // LOGIN WITH EMAIL
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception("No user");

    await _ensureUserDocument(user);
  }

  // LOGIN WITH GOOGLE
  Future<void> loginWithGoogle() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception("Cancelled");

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception("No user");

    await _ensureUserDocument(user);
  }

  // SIGN UP WITH EMAIL
  Future<void> signUpEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) throw Exception("No user");

    final userModel = UserModel(
      id: user.uid,
      name: username.trim(),
      email: user.email ?? '',
      avatarUrl: '',
      createdTripIds: const [],
      savedTripIds: const [],
    );

    await userRepository.createOrUpdateUser(userModel);
  }

  // ENSURE USER DOCUMENT
  Future<void> _ensureUserDocument(User firebaseUser) async {
    final existing = await userRepository.getUserById(firebaseUser.uid);

    if (existing != null) return;

    final displayName =
        firebaseUser.displayName ??
        firebaseUser.email?.split('@').first ??
        'User${firebaseUser.uid.substring(0, 6)}';

    final userModel = UserModel(
      id: firebaseUser.uid,
      name: displayName,
      email: firebaseUser.email ?? '',
      avatarUrl: firebaseUser.photoURL ?? '',
      createdTripIds: const [],
      savedTripIds: const [],
    );

    await userRepository.createOrUpdateUser(userModel);
  }
}
