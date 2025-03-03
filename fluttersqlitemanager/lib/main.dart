import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  await dbHelper.init();
  runApp(MyApp(dbHelper: dbHelper));
}

class MyApp extends StatefulWidget {
  final DatabaseHelper dbHelper;
  MyApp({required this.dbHelper});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('darkMode', isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Enhanced',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(dbHelper: widget.dbHelper, toggleTheme: _toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final VoidCallback toggleTheme;
  HomeScreen({required this.dbHelper, required this.toggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isSortedByName = true;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  void _refreshRecords() async {
    final data = await widget.dbHelper.queryAllRows();
    setState(() {
      _records = _isSortedByName
          ? (data..sort((a, b) => a['name'].compareTo(b['name'])))
          : (data..sort((a, b) => a['age'].compareTo(b['age'])));
    });
  }

  void _updateRecord(int id, String name, int age) async {
    await widget.dbHelper.update({'_id': id, 'name': name, 'age': age});
    _refreshRecords();
  }

  void _deleteRecord(int id) async {
    await widget.dbHelper.delete(id);
    Fluttertoast.showToast(msg: "Record deleted");
    _refreshRecords();
  }

  void _showUpdateDialog(Map<String, dynamic> record) {
    final TextEditingController nameController =
        TextEditingController(text: record['name']);
    final TextEditingController ageController =
        TextEditingController(text: record['age'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Record"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: ageController, decoration: InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _updateRecord(record['_id'], nameController.text, int.parse(ageController.text));
              Navigator.pop(context);
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite CRUD with Enhancements'),
        actions: [
          IconButton(icon: Icon(Icons.brightness_6), onPressed: widget.toggleTheme),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              setState(() {
                _isSortedByName = !_isSortedByName;
              });
              _refreshRecords();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return ListTile(
            title: Text(record['name']),
            subtitle: Text('Age: ${record['age']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () => _showUpdateDialog(record)),
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRecord(record['_id'])),
              ],
            ),
          );
        },
      ),
    );
  }
}
