import 'package:flutter/material.dart';
import 'task_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> tasks = [];

  // Function to show dialog and add task
  void addTaskDialog() {
    String title = "";
    String desc = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Title"),
                onChanged: (value) {
                  title = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Description"),
                onChanged: (value) {
                  desc = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  setState(() {
                    tasks.add(Task(
                      title: title,
                      description: desc,
                      date: "Today",
                    ));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Toggle task completion
  void toggleTask(int index) {
    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tasks.isEmpty
          ? const Center(child: Text("No tasks yet. Add one!"))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(tasks[index].title),
                    subtitle: Text(tasks[index].description),
                    trailing: Icon(
                      tasks[index].isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: tasks[index].isCompleted
                          ? Colors.green
                          : Colors.grey,
                    ),
                    onTap: () => toggleTask(index),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: addTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}