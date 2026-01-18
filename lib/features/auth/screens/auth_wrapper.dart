import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../controllers/user_controller.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? previousUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user != null && user != previousUser) {
          previousUser = user;
          // Fetch user data after login
          Future.microtask(() => context.read<UserController>().fetchUser());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: AppTheme.loadingScreen());
        }

        if (user != null) {
          // Redirect to Dashboard if user is logged in
          return const DashboardScreen();
        } else {
          // Otherwise, show Login screen
          return const LoginScreen();
        }
      },
    );
  }
}
