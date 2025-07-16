import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resource_items_pg.dart';

class ResourceManagementPage extends StatefulWidget {
  const ResourceManagementPage({super.key});

  @override
  State<ResourceManagementPage> createState() => _ResourceManagementPageState();
}

class _ResourceManagementPageState extends State<ResourceManagementPage> {
  String? selectedResourceId;
  String? selectedResourceName;

  Future<void> _addResource() async { //Adds a document to the resources collection
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Resource'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Resource name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('resources').add({'name': name});
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSelectedResource() async { //Updates the name of a selected resource
    if (selectedResourceId == null) return;
    final controller = TextEditingController(text: selectedResourceName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Resource'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('resources')
                    .doc(selectedResourceId)
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

  Future<void> _deleteSelectedResource() async {
    if (selectedResourceId == null) return;

    // Check for bookings using this resource
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('resourceId', isEqualTo: selectedResourceId)
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
          title: const Text('Cannot Delete Resource'),
          content: Text('This resource is booked by:\n\n$message'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "$selectedResourceName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance.collection('resources').doc(selectedResourceId).delete();
      setState(() {
        selectedResourceId = null;
        selectedResourceName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editSelectedResource),
          IconButton(icon: const Icon(Icons.add), onPressed: _addResource),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteSelectedResource,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('resources').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final id = doc.id;
              final name = doc['name'];

              return ListTile(
                leading: Checkbox(
                  value: selectedResourceId == id,
                  onChanged: (_) {
                    setState(() {
                      selectedResourceId = id;
                      selectedResourceName = name;
                    });
                  },
                ),
                title: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResourceItemsPage(
                          resourceId: id,
                          resourceName: name,
                        ),
                      ),
                    );
                  },
                  child: Text(name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
