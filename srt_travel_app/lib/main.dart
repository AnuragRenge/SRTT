import 'package:flutter/material.dart';
import 'package:srt_travel_app/screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue,fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) =>  HomeScreen(),
      },
    );
  }
}
