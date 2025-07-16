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
  final user = FirebaseAuth.instance.currentUser;

  String filterStatus = 'all'; // 'all', 'upcoming', 'completed'
  String filterBy = 'all'; // 'all', 'mine'

  @override
  void initState() {
    super.initState();
    fetchResources();
  }

  Future<void> fetchResources() async {
    final snapshot = await FirebaseFirestore.instance.collection('resources').get();
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

  Future<void> selectDate() async { // Opens a date picker for the booking date
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

  Future<void> submitBooking() async { //Validates fields
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
      final existing = await FirebaseFirestore.instance
          .collection('bookings')
          .where('resourceId', isEqualTo: selectedResourceId)
          .where('itemId', isEqualTo: selectedItemId)
          .where('date', isEqualTo: Timestamp.fromDate(selectedDate!))
          .get();

      if (existing.docs.isNotEmpty) { //Checks for duplicate booking
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This item is already booked for this date'),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('bookings').add({
        'resourceId': selectedResourceId,
        'itemId': selectedItemId,
        'resourceName': selectedResourceName,
        'itemName': selectedItemName,
        'date': Timestamp.fromDate(selectedDate!),
        'userId': user!.uid,
        'userEmail': user!.email ?? 'Unknown',
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      }); //Saves the booking with fields

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted')),
      );

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

  void _confirmDelete(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to cancel booking: $e')),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('bookings');

    if (filterStatus != 'all') {
      query = query.where('status', isEqualTo: filterStatus); //Shows all/upcoming/completed
    }

    if (filterBy == 'mine') { //Shows everyone's bookings or only the current user’s
      query = query.where('userId', isEqualTo: user?.uid);
    }

    query = query.orderBy('date');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Shared Resource'),
        backgroundColor: const Color(0xFF5E5BDA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                final resource = resources.firstWhere((doc) => doc.id == value);
                final name = (resource.data() as Map<String, dynamic>)['name'];
                setState(() {
                  selectedResourceId = value;
                  selectedResourceName = name;
                  selectedItemId = null;
                  selectedItemName = null;
                });
                fetchItems(value!);
              },
            ),
            const SizedBox(height: 12),
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
                final name = (item.data() as Map<String, dynamic>)['name'];
                setState(() {
                  selectedItemId = value;
                  selectedItemName = name;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate != null
                  ? DateFormat.yMMMd().format(selectedDate!)
                  : 'Select Date'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitBooking,
              child: const Text('Submit Booking'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filterStatus,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        filterStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Text('By:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: filterBy,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Everyone')),
                      DropdownMenuItem(value: 'mine', child: Text('My Bookings')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        filterBy = value!;
                      });
                    },
                  ),
                ),
              ],
            ),


            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading bookings.');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final bookings = snapshot.data!.docs;

                  if (bookings.isEmpty) {
                    return const Text('No bookings found.');
                  }

                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final data = bookings[index].data() as Map<String, dynamic>;
                      final resourceName = data['resourceName'] ?? '';
                      final itemName = data['itemName'] ?? '';
                      final status = data['status'] ?? 'unknown';
                      final userEmail = data['userEmail'] ?? 'Unknown user';
                      final timestamp = data['date'] as Timestamp?;
                      final dateStr = timestamp != null
                          ? DateFormat.yMMMd().format(timestamp.toDate())
                          : 'Unknown Date';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text('$resourceName - $itemName'),
                          subtitle: Text('$dateStr\nStatus: $status\nBy: $userEmail'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (data['userId'] == user?.uid && status == 'upcoming')
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Mark as completed',
                                  onPressed: () => _markAsCompleted(bookings[index].id),
                                ),
                              if (data['userId'] == user?.uid)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Cancel booking',
                                  onPressed: () => _confirmDelete(bookings[index].id),
                                ),
                            ],
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
