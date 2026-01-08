import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';

class UserService {
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  Future<void> createOrUpdateUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersRef.doc(id).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
