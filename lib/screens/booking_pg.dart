import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? selectedResourceId;
  String? selectedResourceName;
  String? selectedItemId;
  String? selectedItemName;
  DateTime? selectedDate;

  List<QueryDocumentSnapshot> resources = [];
  List<QueryDocumentSnapshot> items = [];

  @override
  void initState() {
    super.initState();
    fetchResources();
  }

  Future<void> fetchResources() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('resources').get();
    if (!mounted) return;
    setState(() {
      resources = snapshot.docs;
    });
  }

  Future<void> fetchItems(String resourceId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .doc(resourceId)
        .collection('items')
        .get();
    if (!mounted) return;
    setState(() {
      items = snapshot.docs;
    });
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> submitBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        selectedResourceId == null ||
        selectedItemId == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      // Check for existing booking (same resource, item, and date)
      final existing = await FirebaseFirestore.instance
          .collection('bookings')
          .where('resourceId', isEqualTo: selectedResourceId)
          .where('itemId', isEqualTo: selectedItemId)
          .where('date', isEqualTo: Timestamp.fromDate(selectedDate!))
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This item is already booked for this date'),
          ),
        );
        return;
      }

      // Add booking
      await FirebaseFirestore.instance.collection('bookings').add({
        'resourceId': selectedResourceId,
        'itemId': selectedItemId,
        'resourceName': selectedResourceName,
        'itemName': selectedItemName,
        'date': Timestamp.fromDate(selectedDate!),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted')),
      );

      // Reset form
      if (!mounted) return;
      setState(() {
        selectedResourceId = null;
        selectedItemId = null;
        selectedDate = null;
        selectedItemName = null;
        selectedResourceName = null;
        items = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Shared Resource'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Resource dropdown
            DropdownButton<String>(
              hint: const Text('Select Resource'),
              value: selectedResourceId,
              isExpanded: true,
              items: resources.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(data['name'] ?? 'Unnamed Resource'),
                );
              }).toList(),
              onChanged: (value) {
                final resource =
                resources.firstWhere((doc) => doc.id == value);
                final name =
                (resource.data() as Map<String, dynamic>)['name'];
                setState(() {
                  selectedResourceId = value;
                  selectedResourceName = name;
                  selectedItemId = null;
                  selectedItemName = null;
                });
                fetchItems(value!);
              },
            ),

            const SizedBox(height: 16),

            // Item dropdown
            DropdownButton<String>(
              hint: const Text('Select Item'),
              value: selectedItemId,
              isExpanded: true,
              items: items.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(data['name'] ?? 'Unnamed Item'),
                );
              }).toList(),
              onChanged: (value) {
                final item = items.firstWhere((doc) => doc.id == value);
                final name =
                (item.data() as Map<String, dynamic>)['name'];
                setState(() {
                  selectedItemId = value;
                  selectedItemName = name;
                });
              },
            ),

            const SizedBox(height: 16),

            // Date picker
            ElevatedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate != null
                  ? DateFormat.yMMMd().format(selectedDate!)
                  : 'Select Date'),
            ),

            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: submitBooking,
              child: const Text('Submit Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
