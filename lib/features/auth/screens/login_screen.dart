import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

import '../../user/providers/user_provider.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_email_field.dart';
import '../widgets/auth_google_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final state = controller.state;
    final userProvider = context.read<UserProvider>();

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    if (state.isLoading) {
      return Positioned.fill(child: AppTheme.loadingScreen(overlay: true));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.largeHorizontalPadding,
          child: Column(
            children: [
              const AuthHeader(),

              AuthEmailField(controller: emailController),
              AppTheme.smallSpacing,

              AuthPasswordField(
                controller: passwordController,
                obscure: state.obscurePassword,
                onToggle: controller.togglePasswordVisibility,
              ),

              AppTheme.mediumSpacing,

              AppTheme.elevatedButton(
                label: 'LOGIN',
                onPressed: () async {
                  try {
                    await controller.loginEmail(
                      email: emailController.text,
                      password: passwordController.text,
                      userProvider: userProvider,
                    );
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.dashboard,
                    );
                  } catch (_) {
                    AppTheme.error('Login failed');
                  }
                },
                isPrimary: true,
              ),

              AuthGoogleButton(
                onPressed: () async {
                  try {
                    await controller.loginWithGoogle(
                      userProvider: userProvider,
                    );
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.dashboard,
                    );
                  } catch (_) {
                    AppTheme.error('Google login failed');
                  }
                },
              ),

              AppTheme.largeSpacing,

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.signup);
                },
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
