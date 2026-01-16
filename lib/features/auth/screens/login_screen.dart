import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

import '../../user/providers/user_provider.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_email_field.dart';
import '../widgets/auth_google_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _controller = AuthController();
  AuthState _state = const AuthState();

  Future<void> _login() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      await _controller.loginEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await context.read<UserProvider>().fetchUser();

      final user = context.read<UserProvider>().user;
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 200));
        await context.read<UserProvider>().fetchUser();
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on FirebaseAuthException {
      AppTheme.error('Login failed');
    } finally {
      if (mounted) {
        setState(() => _state = _state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      await _controller.loginWithGoogle();

      await context.read<UserProvider>().fetchUser();

      final user = context.read<UserProvider>().user;
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 200));
        await context.read<UserProvider>().fetchUser();
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on FirebaseAuthException {
      AppTheme.error('Google login failed');
    } finally {
      if (mounted) {
        setState(() => _state = _state.copyWith(isLoading: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.largeHorizontalPadding,
          child: Column(
            children: [
              const AuthHeader(),

              AuthEmailField(controller: _emailController),
              AppTheme.smallSpacing,
              AuthPasswordField(
                controller: _passwordController,
                obscure: _state.obscurePassword,
                onToggle:
                    () => setState(
                      () =>
                          _state = _state.copyWith(
                            obscurePassword: !_state.obscurePassword,
                          ),
                    ),
              ),

              AppTheme.mediumSpacing,
              AppTheme.elevatedButton(
                label: 'LOGIN',
                onPressed: _login,
                isPrimary: true,
              ),

              AuthGoogleButton(onPressed: _loginGoogle),

              AppTheme.largeSpacing,

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.signup);
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
