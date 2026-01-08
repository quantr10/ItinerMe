import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/routes/app_routes.dart';
import '../../user/data/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../user/data/services/user_service.dart';
import '../../user/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      await context.read<UserProvider>().fetchUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError('Login failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Cancelled by user');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) throw Exception('No user returned');

      final displayName =
          user.displayName ??
          user.email?.split('@').first ??
          'User${user.uid.substring(0, 6)}';

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final existingDoc = await docRef.get();

      final existingData = existingDoc.data();
      final createdTripIds =
          existingData?['createdTripIds'] != null
              ? List<String>.from(existingData!['createdTripIds'])
              : <String>[];
      final savedTripIds =
          existingData?['savedTripIds'] != null
              ? List<String>.from(existingData!['savedTripIds'])
              : <String>[];

      final userModel = UserModel(
        id: user.uid,
        name: displayName,
        email: user.email ?? '',
        avatarUrl: user.photoURL ?? '',
        createdTripIds: createdTripIds,
        savedTripIds: savedTripIds,
      );

      await UserService().createOrUpdateUser(userModel);
      if (!mounted) return;
      await context.read<UserProvider>().fetchUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        _showError('Google login failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppTheme.messageDuration,
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : SingleChildScrollView(
                  padding: AppTheme.largeHorizontalPadding,
                  child: Column(
                    children: [
                      AppTheme.extraLargeSpacing,
                      const Icon(
                        Icons.travel_explore,
                        size: 60,
                        color: Colors.white,
                      ),
                      AppTheme.mediumSpacing,
                      Text(
                        'ItinerMe',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.titleFontSize,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      SizedBox(
                        height: AppTheme.fieldHeight,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: AppTheme.inputDecoration(
                            'Email',
                            onClear: () => _emailController.clear(),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppTheme.defaultFontSize,
                          ),
                        ),
                      ),
                      AppTheme.smallSpacing,

                      // Password Field
                      SizedBox(
                        height: AppTheme.fieldHeight,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: AppTheme.defaultFontSize,
                          ),
                          decoration: AppTheme.inputDecoration(
                            'Password',
                            onClear: () => _passwordController.clear(),
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppTheme.primaryColor,
                                size: AppTheme.largeIconFont,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      AppTheme.smallSpacing,
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      AppTheme.smallSpacing,
                      // Login Button
                      AppTheme.elevatedButton(
                        label: 'LOGIN',
                        onPressed: _login,
                        isPrimary: true,
                      ),
                      AppTheme.mediumSpacing,
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white)),
                          Padding(
                            padding: AppTheme.horizontalPadding,
                            child: Text(
                              'OR',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white)),
                        ],
                      ),
                      AppTheme.mediumSpacing,

                      // // Google Sign-In Button
                      AppTheme.elevatedButton(
                        label: 'LOGIN WITH GOOGLE',
                        onPressed: _loginWithGoogle,
                        isPrimary: false,
                      ),
                      AppTheme.largeSpacing,
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.signup,
                                ),
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
                                  fontSize: AppTheme.defaultFontSize,
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
