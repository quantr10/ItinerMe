import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itinerme/core/routes/app_routes.dart';
import 'package:provider/provider.dart';

import 'package:itinerme/core/theme/app_theme.dart';
import 'package:itinerme/core/widgets/main_scaffold.dart';

import 'package:itinerme/features/user/providers/user_provider.dart';
import 'package:itinerme/features/account/controller/account_controller.dart';
import 'package:itinerme/features/account/state/account_state.dart';
import 'package:itinerme/features/account/widgets/account_info_card.dart';
import 'package:itinerme/features/account/widgets/avatar_section.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountController _controller;
  AccountState _state = const AccountState();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AccountController(
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
    );
  }

  Future<void> _pickAndUpload() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _state = _state.copyWith(isUploading: true));

    try {
      final url = await _controller.uploadAvatar(
        userId: user.id,
        imageFile: File(file.path),
      );
      context.read<UserProvider>().updateUserAvatar(url);
      AppTheme.success('Profile updated');
    } catch (_) {
      AppTheme.error('Upload failed');
    } finally {
      setState(() => _state = _state.copyWith(isUploading: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return MainScaffold(
      currentIndex: 3,
      body: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          children: [
            AvatarSection(
              avatar:
                  user?.avatarUrl.isNotEmpty == true
                      ? NetworkImage(user!.avatarUrl)
                      : null,
              isUploading: _state.isUploading,
              onPickImage: _pickAndUpload,
            ),
            AppTheme.largeSpacing,
            AccountInfoCard(email: user?.email ?? '', name: user?.name ?? ''),
            AppTheme.largeSpacing,
            AppTheme.elevatedButton(
              label: 'LOG OUT',
              isPrimary: false,
              onPressed: () async {
                await _controller.logout();
                context.read<UserProvider>().clearUser();

                if (!mounted) return;
                AppTheme.success('Logged out successfully');

                await Future.delayed(const Duration(milliseconds: 500));

                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.dashboard,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
