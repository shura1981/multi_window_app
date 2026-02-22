import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'database_helper.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  List<Map<String, dynamic>> _users = [];
  String? _mainWindowId;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
    _setupWindowHandler();
  }

  Future<void> _setupWindowHandler() async {
    // Get the main window's own controller and listen for 'refresh' calls from children.
    final controller = await WindowController.fromCurrentEngine();
    _mainWindowId = controller.windowId;
    await controller.setWindowMethodHandler((call) async {
      if (call.method == 'refresh') {
        await _refreshUsers();
      }
    });
  }

  Future<void> _refreshUsers() async {
    final data = await DatabaseHelper.instance.getAllUsers();
    if (mounted) {
      setState(() {
        _users = data;
      });
    }
  }

  Future<void> _openUserWindow({Map<String, dynamic>? user}) async {
    final window = await WindowController.create(WindowConfiguration(
      arguments: jsonEncode({
        'user': user,
        'mainWindowId': _mainWindowId,
      }),
    ));
    await window.show();
  }

  void _showNativeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Native OS Dialog Test'),
        content: const Text(
            'This is a native desktop dialog using Flutter 3.41 multi-window rendering.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Table',
            onPressed: _refreshUsers,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show Native Dialog',
            onPressed: _showNativeDialog,
          ),
        ],
      ),
      body: _users.isEmpty
          ? const Center(child: Text('No users found. Add one!'))
          : SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('DOB')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _users.map((user) {
                  return DataRow(cells: [
                    DataCell(Text(user['id'].toString())),
                    DataCell(Text(user['name'])),
                    DataCell(Text(user['dob'])),
                    DataCell(Text(user['phone'])),
                    DataCell(
                      Row(
                        spacing: 8.0,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openUserWindow(user: user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteUser(user['id']);
                              _refreshUsers();
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserWindow(),
        tooltip: 'Add User (New Window)',
        child: const Icon(Icons.add),
      ),
    );
  }
}
