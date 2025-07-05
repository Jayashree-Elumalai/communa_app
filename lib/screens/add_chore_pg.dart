import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendarchore_pg.dart';

class AddChorePage extends StatefulWidget {
  const AddChorePage({super.key});

  @override
  State<AddChorePage> createState() => _AddChorePageState();
}

class _AddChorePageState extends State<AddChorePage> {
  DateTime? selectedDate;
  String? selectedChore;
  final customChoreController = TextEditingController();
  String error = '';
  bool isSubmitting = false;

  final List<String> chores = [
    'Sweep floor',
    'Wash dishes',
    'Take out trash',
    'Clean bathroom',
  ];

  Future<void> saveChore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final customChore = customChoreController.text.trim();
    final selected = selectedChore ?? '';

    // ✅ Validation: can't do both or neither
    if (customChore.isNotEmpty && selected.isNotEmpty) {
      setState(() {
        error = 'Please either select a chore or enter your own, not both.';
      });
      return;
    }

    final chore = customChore.isNotEmpty ? customChore : selected;

    if (selectedDate == null || chore.isEmpty) {
      setState(() => error = 'Please select a date and enter a chore.');
      return;
    }

    setState(() {
      isSubmitting = true;
      error = '';
    });

    try {
      final selectedDateOnly = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      final dateTimestamp = Timestamp.fromDate(selectedDateOnly);

      // ✅ Check for duplicate chore on same date
      final existing = await FirebaseFirestore.instance
          .collection('chores')
          .where('title', isEqualTo: chore)
          .where('date', isEqualTo: dateTimestamp)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          error = 'This chore is already taken for the selected date.';
          isSubmitting = false;
        });
        return;
      }

      // ✅ Fetch user's name from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = userDoc.data()?['name'] ?? 'Unnamed';

      await FirebaseFirestore.instance.collection('chores').add({
        'uid': uid,
        'name': name,
        'title': chore,
        'date': dateTimestamp, // ✅ Store as Timestamp
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Chore added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        error = 'Failed to save chore. Try again.';
      });
    } finally {
      setState(() => isSubmitting = false);
    }
  }



  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Chore')),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔽 Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate != null
                    ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                    : 'Select a date',
              ),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),

            // 🔽 Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select a common chore',
                border: OutlineInputBorder(),
              ),
              value: selectedChore,
              items: chores.map((chore) {
                return DropdownMenuItem(value: chore, child: Text(chore));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedChore = value;
                  customChoreController.clear(); // ✅ Clear custom input
                });
              },
            ),
            const SizedBox(height: 16),

            // 🔽 Custom Chore
            TextField(
              controller: customChoreController,
              onChanged: (value) {
                if (value.isNotEmpty && selectedChore != null) {
                  setState(() {
                    selectedChore = null; // ✅ Clear dropdown if typing
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Or enter your own chore',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 🔽 Error message
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),

            // 🔽 Save Button
            ElevatedButton(
              onPressed: isSubmitting ? null : saveChore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5BDA),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Chore', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}