import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_pg.dart';
import 'register_pg.dart';
import 'admin_pg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  String error = '';

  Future<void> login() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        setState(() {
          error = 'Something went wrong. User ID is null.';
        });
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        setState(() {
          error = 'User record not found in Firestore.';
        });
        return;
      }

      final data = docSnapshot.data();
      final role = data?['role']?.toString().toLowerCase() ?? 'user';

      // DEBUG print
      print("Logged in as $email with role: $role");

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print("Login error: $e");
      setState(() {
        error = 'Login failed. Please check your credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔽 LOGO & TITLE
            Image.asset('assets/images/communa_logo.png', height: 100),
            const SizedBox(height: 16),
            const Text(
              'Communa',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF5E5BDA),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Personalised Dorm Journey',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 32),

            // 🔽 FORM
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔽 LOGIN BUTTON
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5BDA),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),

            // 🔽 REGISTER LINK
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No account?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Register here'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
