import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/user_controller.dart';
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
      create:
          (_) => AuthController(
            authService: AuthService(
              auth: FirebaseAuth.instance,
              userRepository: UserRepository(),
            ),
          ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final state = controller.state;
    final userController = context.read<UserController>();

    return Stack(
      children: [
        Scaffold(
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
                    obscure: state.obscurePassword,
                    onToggle: controller.togglePasswordVisibility,
                  ),
                  AppTheme.mediumSpacing,
                  AppTheme.elevatedButton(
                    label: 'LOGIN',
                    isPrimary: true,
                    onPressed: () async {
                      await controller.loginEmail(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        userController: userController,
                        context: context,
                      );
                    },
                  ),
                  AuthGoogleButton(
                    onPressed: () async {
                      await controller.loginWithGoogle(
                        userController: userController,
                        context: context,
                      );
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
        ),
        if (state.isLoading)
          Positioned.fill(child: AppTheme.loadingScreen(overlay: true)),
      ],
    );
  }
}
