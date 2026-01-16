import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itinerme/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'features/user/providers/user_provider.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
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
