import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/routes/app_routes.dart';
import '../../user/data/services/user_service.dart';
import '../../user/models/user.dart';
import '../../user/data/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = credential.user;
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: _usernameController.text.trim(),
          email: user.email ?? '',
          avatarUrl: '',
          createdTripIds: [],
          savedTripIds: [],
        );

        await UserService().createOrUpdateUser(userModel);
        if (!mounted) return;
        await context.read<UserProvider>().fetchUser();
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError('Sign up failed: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
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

      final userModel = UserModel(
        id: user.uid,
        name: displayName,
        email: user.email ?? '',
        avatarUrl: user.photoURL ?? '',
        createdTripIds: [],
        savedTripIds: [],
      );

      await UserService().createOrUpdateUser(userModel);
      if (!mounted) return;
      await context.read<UserProvider>().fetchUser();

      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        _showError('Google sign up failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: AppTheme.messageDuration,
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
                  child: Form(
                    key: _formKey,
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

                        // Username
                        SizedBox(
                          height: AppTheme.fieldHeight,
                          child: TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: AppTheme.defaultFontSize,
                            ),
                            decoration: AppTheme.inputDecoration(
                              'Username',
                              onClear: () => _usernameController.clear(),
                            ),
                          ),
                        ),
                        AppTheme.smallSpacing,

                        // Email
                        SizedBox(
                          height: AppTheme.fieldHeight,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: AppTheme.defaultFontSize,
                            ),
                            decoration: AppTheme.inputDecoration(
                              'Email',
                              onClear: () => _emailController.clear(),
                            ),
                          ),
                        ),
                        AppTheme.smallSpacing,

                        // Password
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
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        AppTheme.mediumSpacing,

                        // Sign Up Button
                        AppTheme.elevatedButton(
                          label: 'SIGN UP',
                          onPressed: _signUp,
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

                        // Google Sign-In Button
                        AppTheme.elevatedButton(
                          label: 'SIGN UP WITH GOOGLE',
                          onPressed: _signUpWithGoogle,
                          isPrimary: false,
                        ),
                        AppTheme.largeSpacing,
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                fontSize: AppTheme.defaultFontSize,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
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
      ),
    );
  }
}
