import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'database_helper.dart';

class UserFormWindow extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? mainWindowId;

  const UserFormWindow({super.key, this.initialData, this.mainWindowId});

  @override
  State<UserFormWindow> createState() => _UserFormWindowState();
}

class _UserFormWindowState extends State<UserFormWindow> with WindowListener {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Intercept OS window close (X button) — hide instead of destroy.
    windowManager.addListener(this);
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _dobController = TextEditingController(text: widget.initialData?['dob'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Called when user presses OS X button — hide instead of destroy.
  @override
  void onWindowClose() async {
    final self = await WindowController.fromCurrentEngine();
    await self.hide();
  }

  Future<void> _hideWindow() async {
    final self = await WindowController.fromCurrentEngine();
    await self.hide();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = {
      'name': _nameController.text.trim(),
      'dob': _dobController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    if (widget.initialData == null) {
      await DatabaseHelper.instance.insertUser(user);
    } else {
      await DatabaseHelper.instance.updateUser(user, widget.initialData!['id']);
    }

    // Notify main window to refresh.
    final mainId = widget.mainWindowId;
    if (mainId != null) {
      final mainController = WindowController.fromWindowId(mainId);
      await mainController.invokeMethod('refresh');
    }

    await _hideWindow();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit User' : 'New User'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _hideWindow,
            tooltip: 'Close',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                isEdit ? 'Update user information' : 'Enter user information',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _dobController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.cake_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveUser(),
                decoration: const InputDecoration(
                  labelText: 'Cell Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const Spacer(),
              Row(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : _hideWindow,
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveUser,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(isEdit ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
