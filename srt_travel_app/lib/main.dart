import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/adminhomescreen.dart';
import 'screens/leads_list_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/company_detail_screen.dart';
import 'screens/booking_list_screen.dart';
import 'screens/vehicles_list_screen.dart';
import 'screens/tour_list_screen.dart';
import 'screens/driver_list_screen.dart';

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
        '/register': (_) => const RegisterScreen()
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

         else if (settings.name == '/leads') {
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
        else if (settings.name == '/users') {
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
        else if (settings.name == '/company') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => CompanyDetailsScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }
        else if (settings.name == '/tours') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => TourListScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }
        else if (settings.name == '/vehicles') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => VehiclesListScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }
        else if (settings.name == '/drivers') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => DriverListScreen(
              userRole: userRole,
              username: username,
              email: email,
              id: id,
            ),
          );
        }
        else if (settings.name == '/bookings') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final userRole = args['role'] ?? '';
          final username = args['username'] ?? '';
          final email = args['email'] ?? '';
          final id = args['id'] ?? '';
          return MaterialPageRoute(
            builder: (_) => BookingListScreen(
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
