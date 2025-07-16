import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceItemsPage extends StatefulWidget {
  final String resourceId;
  final String resourceName;

  const ResourceItemsPage({
    super.key,
    required this.resourceId,
    required this.resourceName,
  }); //Takes resourceId and resourceName as arguments

  @override
  State<ResourceItemsPage> createState() => _ResourceItemsPageState();
}

class _ResourceItemsPageState extends State<ResourceItemsPage> {
  String? selectedItemId;
  String? selectedItemName;

  Future<void> _addItem() async { //Adds a new item document to /resources/{resourceId}/items
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Item name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final itemName = controller.text.trim();
              if (itemName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('resources')
                    .doc(widget.resourceId)
                    .collection('items')
                    .add({'name': itemName});
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSelectedItem() async { //Updates the name of the selected item
    if (selectedItemId == null) return;
    final controller = TextEditingController(text: selectedItemName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('resources')
                    .doc(widget.resourceId)
                    .collection('items')
                    .doc(selectedItemId)
                    .update({'name': newName});
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedItem() async {
    if (selectedItemId == null) return;

    // Check for bookings using this item
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('resourceId', isEqualTo: widget.resourceId)
        .where('itemId', isEqualTo: selectedItemId)
        .get();

    if (bookingSnapshot.docs.isNotEmpty) {
      final message = bookingSnapshot.docs.map((doc) {
        final data = doc.data();
        final user = data['userEmail'] ?? 'Unknown user';
        final timestamp = data['date'] as Timestamp?;
        final dateStr = timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).toLocal().toString().split(' ')[0]
            : 'Unknown date';
        return '- $user on $dateStr';
      }).join('\n');

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete Item'),
          content: Text('This item is booked by:\n\n$message'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$selectedItemName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Delete if confirmed
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(widget.resourceId)
          .collection('items')
          .doc(selectedItemId)
          .delete();
      setState(() {
        selectedItemId = null;
        selectedItemName = null;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resourceName),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editSelectedItem),
          IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelectedItem),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resources')
            .doc(widget.resourceId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final id = doc.id;
              final itemName = doc['name'];

              return ListTile(
                leading: Checkbox(
                  value: selectedItemId == id,
                  onChanged: (_) {
                    setState(() {
                      selectedItemId = id;
                      selectedItemName = itemName;
                    });
                  },
                ),
                title: ElevatedButton(
                  onPressed: () {},
                  child: Text(itemName),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
