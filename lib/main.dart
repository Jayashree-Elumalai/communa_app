import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_pg.dart';
import 'screens/register_pg.dart';
import 'screens/home_pg.dart';
import 'screens/booking_pg.dart';
import 'screens/feedback_pg.dart';
import 'screens/admin_pg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Communa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking': (context) => const BookingPage(),
        '/feedback': (context) => const FeedbackPage(),
      },
    );
  }
}
