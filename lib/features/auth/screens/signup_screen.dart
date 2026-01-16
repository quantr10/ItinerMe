import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

import '../../user/providers/user_provider.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_email_field.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_google_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController _controller = AuthController();
  AuthState _state = const AuthState();

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _state = _state.copyWith(isLoading: true));

    try {
      await _controller.signUpEmail(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );

      await context.read<UserProvider>().fetchUser();
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      AppTheme.error('Sign up failed');
    } finally {
      if (mounted) {
        setState(() => _state = _state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _state = _state.copyWith(isLoading: true));

    try {
      await _controller.loginWithGoogle();
      await context.read<UserProvider>().fetchUser();
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      AppTheme.error('Google sign up failed');
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AuthHeader(),

                // Username
                SizedBox(
                  height: AppTheme.fieldHeight,
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: AppTheme.inputDecoration(
                      'Username',
                      onClear: () => _usernameController.clear(),
                    ),
                    style: const TextStyle(
                      fontSize: AppTheme.defaultFontSize,
                      color: Colors.black,
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Username required'
                                : null,
                  ),
                ),

                AppTheme.smallSpacing,

                // Email
                AuthEmailField(controller: _emailController),

                AppTheme.smallSpacing,

                // Password
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

                // Sign up button
                AppTheme.elevatedButton(
                  label: 'SIGN UP',
                  onPressed: _signUp,
                  isPrimary: true,
                ),

                // Google sign up
                AuthGoogleButton(onPressed: _signUpWithGoogle),

                AppTheme.largeSpacing,

                TextButton(
                  onPressed:
                      () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }
}
