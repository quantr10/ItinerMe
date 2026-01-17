import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_scaffold.dart';
import '../../../core/routes/app_routes.dart';

import '../../user/providers/user_provider.dart';
import '../controller/account_controller.dart';
import '../widgets/account_info_card.dart';
import '../widgets/avatar_section.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => AccountController(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
          ),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountController>();
    final state = controller.state;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Stack(
      children: [
        MainScaffold(
          currentIndex: 3,
          body: Padding(
            padding: AppTheme.defaultPadding,
            child: Column(
              children: [
                AvatarSection(
                  avatar:
                      state.avatarUrl != null
                          ? NetworkImage(state.avatarUrl!)
                          : (user?.avatarUrl.isNotEmpty == true
                              ? NetworkImage(user!.avatarUrl)
                              : null),
                  isUploading: state.isUploading,
                  onPickImage: () async {
                    if (user == null) return;
                    try {
                      await controller.pickAndUploadAvatar(user.id);
                      if (controller.state.avatarUrl != null) {
                        userProvider.updateUserAvatar(
                          controller.state.avatarUrl!,
                        );
                      }
                      AppTheme.success('Profile updated');
                    } catch (_) {
                      AppTheme.error('Upload failed');
                    }
                  },
                ),
                AppTheme.largeSpacing,
                AccountInfoCard(
                  email: user?.email ?? '',
                  name: user?.name ?? '',
                ),
                AppTheme.largeSpacing,
                AppTheme.elevatedButton(
                  label: 'LOG OUT',
                  isPrimary: false,
                  onPressed: () async {
                    await controller.logout();
                    userProvider.clearUser();

                    AppTheme.success('Logged out successfully');

                    await Future.delayed(const Duration(milliseconds: 400));

                    if (!context.mounted) return;
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
        ),
        if (state.isUploading)
          Positioned.fill(child: AppTheme.loadingScreen(overlay: true)),
      ],
    );
  }
}
