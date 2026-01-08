import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../user/data/providers/user_provider.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/routes/app_routes.dart';
import '../../user/models/user.dart';
import '../../../core/theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _uploadAvatar() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null || _imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = _storage
          .ref()
          .child('user_avatars')
          .child('${user.id}.jpg');
      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(user.id).update({
        'avatarUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      userProvider.updateUserAvatar(imageUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile photo updated'),
          duration: AppTheme.messageDuration,
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: AppTheme.messageDuration,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadAvatar();
    }
  }

  Future<void> _logout() async {
    FirebaseAuth.instance.signOut();
    context.read<UserProvider>().clearUser();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return MainScaffold(
      currentIndex: 3,
      body: SingleChildScrollView(
        child: Padding(
          padding: AppTheme.defaultPadding,
          child: Column(
            children: [
              AppTheme.mediumSpacing,
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                      backgroundImage: _getAvatarImage(user),
                      child:
                          _showDefaultAvatar(user)
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [AppTheme.defaultShadow],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: AppTheme.largeIconFont,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AppTheme.mediumSpacing,
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  side: BorderSide(
                    color: AppTheme.primaryColor,
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: Padding(
                  padding: AppTheme.defaultPadding,
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.email,
                        user?.email ?? 'Not provided',
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      _buildDetailRow(
                        Icons.person,
                        user?.name ?? 'Not provided',
                      ),
                    ],
                  ),
                ),
              ),
              AppTheme.largeSpacing,
              AppTheme.elevatedButton(
                label: 'LOG OUT',
                onPressed: _logout,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Padding(
      padding: AppTheme.smallPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: AppTheme.largeIconFont,
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.defaultFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage(UserModel? user) {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (user?.avatarUrl.isNotEmpty ?? false)
      return NetworkImage(user!.avatarUrl);
    return null;
  }

  bool _showDefaultAvatar(UserModel? user) {
    return _imageFile == null && (user?.avatarUrl.isEmpty ?? true);
  }
}
