import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/controllers/user_controller.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/repositories/user_repository.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserController(userRepository: UserRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'ItinerMe',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppTheme.messengerKey,
        home: const AuthWrapper(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
