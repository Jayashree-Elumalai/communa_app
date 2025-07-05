import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? selectedResourceId;
  String? selectedResourceName;
  String? selectedItemId;
  String? selectedItemName;
  DateTime? selectedDate;

  final userId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, Map<String, String>> resourceItemsMap = {}; // resourceName -> {itemId: itemName}
  Map<String, String> availableItems = {};

  @override
  void initState() {
    super.initState();
    fetchResourcesAndItems();
  }

  Future<void> fetchResourcesAndItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('resources').get();
    Map<String, Map<String, String>> tempMap = {};

    for (var doc in snapshot.docs) {
      final resourceId = doc.id;
      final resourceName = doc['name'];

      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .collection('items')
          .get();

      final items = {
        for (var item in itemsSnapshot.docs) item.id: item['name'] as String
      };

      tempMap[resourceId] = {
        'name': resourceName,
        'items': items.entries.map((e) => e.key).join(','),
      };

      setState(() {
        resourceItemsMap[resourceId] = items;
      });
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> bookResource() async {
    if (selectedResourceId == null ||
        selectedItemId == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select resource, item, and date.')),
      );
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('bookings')
        .where('resourceId', isEqualTo: selectedResourceId)
        .where('itemId', isEqualTo: selectedItemId)
        .where('date', isEqualTo: Timestamp.fromDate(selectedDate!))
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ This item is already booked on this date.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': userId,
      'resourceId': selectedResourceId,
      'resourceName': selectedResourceName,
      'itemId': selectedItemId,
      'itemName': selectedItemName,
      'date': Timestamp.fromDate(selectedDate!),
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Booking successful!')),
    );

    setState(() {
      selectedResourceId = null;
      selectedItemId = null;
      selectedResourceName = null;
      selectedItemName = null;
      selectedDate = null;
      availableItems = {};
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Booking cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Shared Resource')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedResourceId,
              hint: const Text('Select Resource'),
              items: resourceItemsMap.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.values.first),
                );
              }).toList(),
              onChanged: (resId) {
                setState(() {
                  selectedResourceId = resId;
                  selectedResourceName = resourceItemsMap[resId!]!.values.first;
                  availableItems = resourceItemsMap[resId]!;
                  selectedItemId = null;
                  selectedItemName = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedItemId,
              hint: const Text('Select Item'),
              items: availableItems.entries.map((entry) {
                return DropdownMenuItem(value: entry.key, child: Text(entry.value));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedItemId = val;
                  selectedItemName = availableItems[val];
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                selectedDate == null ? 'Pick Date' : DateFormat.yMMMd().format(selectedDate!),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: bookResource,
              child: const Text('Submit Booking'),
            ),
            const SizedBox(height: 32),
            const Text('Your Bookings:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: userId)
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No bookings yet.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.book_online),
                          title: Text('${data['resourceName']} - ${data['itemName']}'),
                          subtitle: Text(DateFormat.yMMMd().format(date)),
                          trailing: TextButton(
                            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            onPressed: () => cancelBooking(doc.id),
                          ),
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
