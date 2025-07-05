import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditChorePage extends StatefulWidget {
  final DocumentSnapshot choreDoc;
  const EditChorePage({super.key, required this.choreDoc});

  @override
  State<EditChorePage> createState() => _EditChorePageState();
}

class _EditChorePageState extends State<EditChorePage> {
  late TextEditingController choreController;
  late DateTime selectedDate;
  bool isSubmitting = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    choreController = TextEditingController(text: widget.choreDoc['title']);
    selectedDate = (widget.choreDoc['date'] as Timestamp).toDate();
  }

  Future<void> updateChore() async {
    final newChore = choreController.text.trim();

    if (newChore.isEmpty) {
      setState(() => error = 'Please enter a chore.');
      return;
    }

    setState(() {
      isSubmitting = true;
      error = '';
    });

    try {
      // Check if another chore with same date and title exists
      final existing = await FirebaseFirestore.instance
          .collection('chores')
          .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
          .where('title', isEqualTo: newChore)
          .get();

      final duplicate = existing.docs.where((d) => d.id != widget.choreDoc.id);
      if (duplicate.isNotEmpty) {
        setState(() {
          error = 'Another user already took this chore on this date.';
          isSubmitting = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('chores').doc(widget.choreDoc.id).update({
        'title': newChore,
        'date': Timestamp.fromDate(selectedDate),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        error = 'Failed to update chore.';
      });
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Chore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              leading: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: choreController,
              decoration: const InputDecoration(
                labelText: 'Chore',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSubmitting ? null : updateChore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5BDA),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Chore',
                      style: TextStyle(color: Colors.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
