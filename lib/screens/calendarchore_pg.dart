import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_chore_pg.dart';
import'my_chores_pg.dart';

class CalendarChorePage extends StatefulWidget {
  const CalendarChorePage({super.key});

  @override
  State<CalendarChorePage> createState() => _CalendarChorePageState();
}

class _CalendarChorePageState extends State<CalendarChorePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DocumentSnapshot> _choresForSelectedDate = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchChoresForDate(_selectedDay!);
  }

  void fetchChoresForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('chores')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    setState(() {
      _choresForSelectedDate = querySnapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chore Calendar'),
        backgroundColor: const Color(0xFF5E5BDA),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyChoresPage()),
              );
            },
            child: const Text(
              'My Chores',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              fetchChoresForDate(selectedDay);
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // ✅ Hides the 2 weeks / month toggle button
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _choresForSelectedDate.isEmpty
                ? const Center(child: Text('No chores for this day.'))
                : ListView.builder(
              itemCount: _choresForSelectedDate.length,
              itemBuilder: (context, index) {
                final chore = _choresForSelectedDate[index];
                final title = chore['title'] ?? 'Unnamed chore';
                final name = chore['name'] ?? 'Unknown';
                return ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: Text(title),
                  subtitle: Text('Assigned to: $name'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5E5BDA),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddChorePage()),
          );
        },
      ),
    );
  }
}
