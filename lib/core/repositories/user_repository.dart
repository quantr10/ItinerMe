import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  // CREATE OR UPDATE USER
  Future<void> createOrUpdateUser(UserModel user) async {
    final doc = _usersRef.doc(user.id);
    final existing = await doc.get();

    if (existing.exists) {
      await doc.update({
        'name': user.name,
        'email': user.email,
        'avatarUrl': user.avatarUrl,
      });
    } else {
      await doc.set(user.toJson());
    }
  }

  // GET USER BY ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersRef.doc(id).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // UPDATE USER AVATAR
  Future<void> updateAvatar(String userId, String newUrl) async {
    await _usersRef.doc(userId).update({
      'avatarUrl': newUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
