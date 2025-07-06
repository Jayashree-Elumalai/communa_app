import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController = TextEditingController();

  Future<void> submitFeedback() async {
    final text = feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('anonymous_feedback').add({
      'text': text,
      'timestamp': Timestamp.now(),
    });

    feedbackController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Feedback submitted anonymously!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anonymous Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Tell us what’s on your mind anonymously.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your feedback here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitFeedback,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Anonymous Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('anonymous_feedback')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading feedback.');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final feedbackDocs = snapshot.data!.docs;

                  if (feedbackDocs.isEmpty) {
                    return const Text('No feedback yet.');
                  }

                  return ListView.builder(
                    itemCount: feedbackDocs.length,
                    itemBuilder: (context, index) {
                      final data = feedbackDocs[index].data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;
                      final formattedTime = timestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                          timestamp.millisecondsSinceEpoch)
                          : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(text),
                          subtitle: formattedTime != null
                              ? Text('${formattedTime.toLocal()}')
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
