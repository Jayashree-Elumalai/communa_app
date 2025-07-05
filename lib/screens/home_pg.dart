import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_pg.dart';
import 'calendarchore_pg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String quote = '';
  String author = '';

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void goToChores(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarChorePage()),
    );
  }

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['name'] ?? 'User';
  }

  Future<void> fetchQuoteOfTheDay() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/quotes/random'));
      final data = jsonDecode(response.body);
      setState(() {
        quote = data['quote'];
        author = data['author'];
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          quote = data['content'] ?? 'No quote found.';
          author = data['author'] ?? 'Unknown';
        });
      } else {
        setState(() {
          quote = 'Failed to load quote (status: ${response.statusCode}).';
          author = '';
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        quote = 'Unable to load quote.';
        author = '';
      });
    }
  }



  @override
  void initState() {
    super.initState();
    fetchQuoteOfTheDay();
  }

  Widget buildFeatureButton({
    required String label,
    required String imagePath,
    required VoidCallback? onTap,
    double containerWidth = 150,
    double imageWidth = 100,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: containerWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: imageWidth,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5E5BDA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        final appBarTitle = snapshot.connectionState == ConnectionState.waiting
            ? 'Loading...'
            : 'Hi, ${snapshot.data}';

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: const Color(0xFF5E5BDA),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => logout(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔽 Quote of the Day
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFFD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Quote of the Day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5E5BDA),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"$quote"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      if (author.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '- $author',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 🔼 Row of Feedback and Book Facilities
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildFeatureButton(
                      label: 'Feedback',
                      imagePath: 'assets/images/feedback.png',
                      onTap: null,
                    ),
                    const SizedBox(width: 24),
                    buildFeatureButton(
                      label: 'Book Facilities',
                      imagePath: 'assets/images/book_facility.png',
                      onTap: null,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 🔽 Chores Button with custom size
                buildFeatureButton(
                  label: 'Chores',
                  imagePath: 'assets/images/chores.png',
                  containerWidth: 200,
                  imageWidth: 180,
                  onTap: () => goToChores(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

