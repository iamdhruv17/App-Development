import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedule = [
      {"subject": "Math", "time": "9 AM"},
      {"subject": "Physics", "time": "10 AM"},
      {"subject": "Chemistry", "time": "11 AM"},
      {"subject": "English", "time": "12 PM"},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(schedule[index]['subject']!),
                content: Text("Time: ${schedule[index]['time']}"),
              ),
            );
          },
          child: Card(
            color: Colors.blue.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    schedule[index]['subject']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(schedule[index]['time']!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}