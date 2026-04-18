class Task {
  String title;
  String description;
  String date;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
  });
}