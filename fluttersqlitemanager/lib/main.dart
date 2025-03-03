import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Enhanced',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        dbHelper: widget.dbHelper,
        toggleTheme: () => setState(() => isDarkMode = !isDarkMode),
      ),
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  void _refreshRecords() async {
    final data = await widget.dbHelper.queryAllRows();
    setState(() {
      _records = data;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = File(pickedFile.path).readAsBytesSync();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _addRecord() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }
    await widget.dbHelper.insert({
      'name': _nameController.text,
      'age': int.parse(_ageController.text),
      'image': _imageBase64,
    });
    _nameController.clear();
    _ageController.clear();
    setState(() {
      _imageBase64 = null;
    });
    _refreshRecords();
  }

  void _deleteRecord(int id) async {
    await widget.dbHelper.delete(id);
    _refreshRecords();
  }

  List<Map<String, dynamic>> _filteredRecords() {
    if (_searchController.text.isEmpty) return _records;
    return _records.where((record) {
      return record['name']
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite CRUD with Images & Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image"),
            ),
            if (_imageBase64 != null)
              Image.memory(
                base64Decode(_imageBase64!),
                height: 100,
                width: 100,
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addRecord,
              child: Text('Add Record'),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRecords().length,
                itemBuilder: (context, index) {
                  final record = _filteredRecords()[index];
                  return Card(
                    child: ListTile(
                      leading: record['image'] != null
                          ? Image.memory(
                              base64Decode(record['image']),
                              width: 50,
                              height: 50,
                            )
                          : Icon(Icons.person),
                      title: Text(record['name']),
                      subtitle: Text('Age: ${record['age']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecord(record['_id']),
                      ),
                    ),
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
