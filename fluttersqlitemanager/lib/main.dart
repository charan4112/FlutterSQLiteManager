import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  await dbHelper.init();
  runApp(MyApp(dbHelper: dbHelper));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper dbHelper;
  const MyApp({super.key, required this.dbHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQLite Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(dbHelper: dbHelper),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  const HomeScreen({super.key, required this.dbHelper});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  List<Map<String, dynamic>> _records = [];

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

  void _addRecord() async {
    if (_nameController.text.isNotEmpty && _ageController.text.isNotEmpty) {
      await widget.dbHelper.insert({
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
      });
      _nameController.clear();
      _ageController.clear();
      _refreshRecords();
    }
  }

  void _deleteRecord(int id) async {
    await widget.dbHelper.delete(id);
    _refreshRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SQLite CRUD Example')),
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
            ElevatedButton(onPressed: _addRecord, child: Text('Add Record')),
            Expanded(
              child: ListView.builder(
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_records[index]['name']),
                    subtitle: Text('Age: ${_records[index]['age']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRecord(_records[index]['_id']),
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
