import 'package:flutter/material.dart';
import 'package:srt_travel_app/screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/adminhomescreen.dart';
import 'screens/leads_list_screen.dart';
import 'screens/user_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sai Ram Tours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';

          if (userRole == 'admin') {
            return MaterialPageRoute(
              builder: (_) => AdminHomeScreen(
                userRole: userRole, username: username, email: email, id: id,
              ),
            );
          }
          else {
            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                userRole: userRole, username: username, email: email, id: id,
              ),
            );
          }
        }

        if (settings.name == '/leads') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => LeadsListScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }
        if (settings.name == '/users') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => UserListScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }

        return null;
      },
    );
  }
}
