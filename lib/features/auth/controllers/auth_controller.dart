import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import 'user_controller.dart';

class AuthController extends ChangeNotifier {
  final AuthService authService;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  AuthController({required this.authService});

  // Toggle password visibility
  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  Future<void> loginEmail({
    required String email,
    required String password,
    required UserController userController,
    required BuildContext context,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await authService.loginWithEmail(email: email, password: password);
      await userController.fetchUser();

      AppTheme.success("Login successful");

      // Navigate to dashboard after successful login
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (_) {
      AppTheme.error("Login failed");
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle({
    required UserController userController,
    required BuildContext context,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await authService.loginWithGoogle();
      await userController.fetchUser();

      AppTheme.success("Google login successful");

      // Navigate to dashboard after successful login
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (_) {
      AppTheme.error("Google login failed"); // Show error only when login fails
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // SIGN UP WITH EMAIL
  Future<void> signUpEmail({
    required String email,
    required String password,
    required String username,
    required UserController userController,
    required BuildContext context,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await authService.signUpEmail(
        email: email,
        password: password,
        username: username,
      );

      await userController.fetchUser();
      AppTheme.success("Sign up successful");

      // Navigate to dashboard after successful sign up
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (_) {
      AppTheme.error("Sign up failed");
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }
}
