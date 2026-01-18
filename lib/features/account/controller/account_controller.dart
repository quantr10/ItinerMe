// lib/features/account/controller/account_controller.dart

import 'package:flutter/material.dart';
import '../state/account_state.dart';
import '../../../core/services/account_service.dart';

class AccountController extends ChangeNotifier {
  final AccountService accountService;

  AccountState _state = const AccountState();
  AccountState get state => _state;

  AccountController({required this.accountService});

  // PICK & UPLOAD AVATAR
  Future<void> pickAndUploadAvatar(String userId) async {
    _state = _state.copyWith(isUploading: true);
    notifyListeners();

    try {
      final url = await accountService.pickAndUploadAvatar(userId);

      // User cancelled image picking → url null
      if (url == null) {
        _state = _state.copyWith(isUploading: false);
        notifyListeners();
        return;
      }

      _state = _state.copyWith(isUploading: false, avatarUrl: url);
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isUploading: false);
      notifyListeners();
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() => accountService.logout();
}
