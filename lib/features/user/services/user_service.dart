import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user.dart';

class UserService {
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  Future<void> createOrUpdateUser(UserModel user) async {
    final doc = _usersRef.doc(user.id);
    final existing = await doc.get();

    if (existing.exists) {
      // Only update non-avatar fields
      await doc.update({
        'name': user.name,
        'email': user.email,
        // 'createdTripIds': user.createdTripIds,
        // 'savedTripIds': user.savedTripIds,
      });
    } else {
      // New user → set full
      await doc.set(user.toJson());
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersRef.doc(id).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
