import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'database_helper.dart';

class UserFormWindow extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? mainWindowId;

  const UserFormWindow({super.key, this.initialData, this.mainWindowId});

  @override
  State<UserFormWindow> createState() => _UserFormWindowState();
}

class _UserFormWindowState extends State<UserFormWindow> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _dobController = TextEditingController(text: widget.initialData?['dob'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = {
        'name': _nameController.text,
        'dob': _dobController.text,
        'phone': _phoneController.text,
      };

      if (widget.initialData == null) {
        await DatabaseHelper.instance.insertUser(user);
      } else {
        await DatabaseHelper.instance.updateUser(user, widget.initialData!['id']);
      }

      // Notify the main window to refresh its table via its own controller channel.
      final mainId = widget.mainWindowId;
      if (mainId != null) {
        final mainController = WindowController.fromWindowId(mainId);
        await mainController.invokeMethod('refresh');
      }

      // Hide this child window (don't close — that would kill the whole app on Linux).
      final self = await WindowController.fromCurrentEngine();
      await self.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16.0,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter DOB' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Cell Phone', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
              ),
              ElevatedButton(
                onPressed: _saveUser,
                child: const Text('Save User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
