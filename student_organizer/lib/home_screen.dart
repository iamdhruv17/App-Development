import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'schedule_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final screens = const [
    TasksScreen(),
    ScheduleScreen(),
    NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Organizer")),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Welcome Student 👋",
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(child: screens[currentIndex]),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
        ],
      ),
    );
  }
}