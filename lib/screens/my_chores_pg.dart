import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_chore_pg.dart';

class MyChoresPage extends StatelessWidget {
  const MyChoresPage({super.key});

  Stream<QuerySnapshot> getUserChoresStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty(); // No user logged in
    }

    return FirebaseFirestore.instance
        .collection('chores')
        .where('uid', isEqualTo: user.uid)
        .orderBy('date')
        .snapshots();
  }

  Future<void> deleteChore(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('chores').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chore deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete chore')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chores'),
        backgroundColor: const Color(0xFF5E5BDA),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserChoresStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Firestore Error: ${snapshot.error}'); // 🔽 This will print the full link
            return const Center(child: Text('Something went wrong fetching chores'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chores = snapshot.data?.docs ?? [];

          if (chores.isEmpty) {
            return const Center(child: Text('You have no chores yet.'));
          }
          return ListView.builder(
            itemCount: chores.length,
            itemBuilder: (context, index) {
              final doc = chores[index];
              final title = doc['title'] ?? 'Unnamed chore';
              final date = (doc['date'] as Timestamp).toDate();
              final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

              return ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: Text(title),
                subtitle: Text('Date: $formattedDate'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditChorePage(choreDoc: doc),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteChore(doc.id, context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
