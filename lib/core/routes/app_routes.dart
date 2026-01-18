import 'package:flutter/material.dart';
import '../../features/my_collection/screens/my_collection_screen.dart';
import '../../features/create_trip/screens/create_trip_screen.dart';
import '../../features/account/screen/account_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/auth_wrapper.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String createTrip = '/create-trip';
  static const String account = '/account';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String myCollection = '/my-collection';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case myCollection:
        return MaterialPageRoute(builder: (_) => const MyCollectionScreen());
      case createTrip:
        return MaterialPageRoute(builder: (_) => const CreateTripScreen());
      case account:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
