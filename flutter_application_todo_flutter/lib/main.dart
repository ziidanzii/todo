import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        scaffoldBackgroundColor: Colors.blue[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue),
          ),
          border: OutlineInputBorder(),
        ),
      ),
      home: const TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  final int id;
  final String title;
  final String priority;
  final String dueDate;
  final String createdAt;
  final String updatedAt;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isDone,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      dueDate: json['due_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isDone: json['is_done'].toString().toLowerCase() == 'true',
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});
  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final String baseUrl = 'http://127.0.0.1:8000/api';
  List<Task> tasks = [];
  String searchQuery = '';

  final TextEditingController titleController = TextEditingController();
  String selectedPriority = 'low';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  List<Task> getFilteredTasks() {
    List<Task> filtered = tasks.where((task) {
      return task.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      DateTime aDate = DateTime.parse(a.dueDate);
      DateTime bDate = DateTime.parse(b.dueDate);
      return aDate.compareTo(bDate);
    });

    return filtered;
  }

  Future<void> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/tasks'));
    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      setState(() {
        tasks = jsonData.map((e) => Task.fromJson(e)).toList();
      });
    }
  }

  Future<void> addTask() async {
    if (titleController.text.isEmpty || selectedDate == null) return;
    await http.post(Uri.parse('$baseUrl/tasks'), body: {
      'title': titleController.text,
      'priority': selectedPriority,
      'due_date': selectedDate!.toIso8601String().split('T')[0],
    });
    titleController.clear();
    selectedDate = null;
    fetchTasks();
  }

  Future<void> editTask(Task task) async {
    if (titleController.text.isEmpty || selectedDate == null) return;
    await http.put(Uri.parse('$baseUrl/tasks/${task.id}'), body: {
      'title': titleController.text,
      'priority': selectedPriority,
      'due_date': selectedDate!.toIso8601String().split('T')[0],
      'is_done': task.isDone.toString(),
    });
    titleController.clear();
    selectedDate = null;
    fetchTasks();
  }

  Future<void> deleteTask(int id) async {
    await http.delete(Uri.parse('$baseUrl/tasks/$id'));
    fetchTasks();
  }

  Future<void> updateTaskStatus(Task task, bool newStatus) async {
    await http.put(Uri.parse('$baseUrl/tasks/${task.id}'), body: {
      'title': task.title,
      'priority': task.priority,
      'due_date': task.dueDate,
      'is_done': newStatus.toString(),
    });
    fetchTasks();
  }

  String formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return raw;
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Tugas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedPriority,
              items: ['low', 'medium', 'high'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) => setState(() => selectedPriority = val!),
            ),
            TextButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Text(selectedDate == null
                  ? 'Pilih Tanggal'
                  : selectedDate.toString().split(' ')[0]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              addTask();
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void showEditDialog(Task task) {
    titleController.text = task.title;
    selectedPriority = task.priority;
    selectedDate = DateTime.parse(task.dueDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Tugas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedPriority,
              items: ['low', 'medium', 'high'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) => setState(() => selectedPriority = val!),
            ),
            TextButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Text(selectedDate == null
                  ? 'Pilih Tanggal'
                  : selectedDate.toString().split(' ')[0]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              editTask(task);
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Tugas',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('Belum ada tugas.'))
                  : filteredTasks.isEmpty
                      ? const Center(child: Text('Tidak ada tugas yang cocok.'))
                      : ListView.builder(
                          itemCount: filteredTasks.length,
                          itemBuilder: (ctx, i) {
                            final task = filteredTasks[i];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.lightBlue),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: task.isDone,
                                    activeColor: Colors.lightBlue,
                                    onChanged: (val) {
                                      updateTaskStatus(task, !task.isDone);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            decoration: task.isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Prioritas: ${task.priority}'),
                                        Text('Deadline: ${task.dueDate}'),
                                        Text(
                                            'Dibuat: ${formatDateTime(task.createdAt)}'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => showEditDialog(task),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => deleteTask(task.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
