import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _statusMessage = 'Ready';
  late AppLifecycleListener _lifecycleListener;

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Force-kill process when main window is closed so hidden sub-window
    // Flutter engines don't keep the OS process alive.
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        exit(0); // Kills process including all hidden sub-window engines.
      },
    );
    _refreshUsers();
    _setupWindowHandler();
  }

  Future<void> _setupWindowHandler() async {
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
        _statusMessage = '${data.length} user${data.length == 1 ? '' : 's'} total';
      });
    }
  }

  Future<void> _openUserWindow({Map<String, dynamic>? user}) async {
    setState(() => _statusMessage = 'Opening form…');
    final window = await WindowController.create(WindowConfiguration(
      arguments: jsonEncode({
        'user': user,
        'mainWindowId': _mainWindowId,
      }),
    ));
    await window.show();
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteUser(id);
      _refreshUsers();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'User Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Flutter 3.41 Desktop — Multi-Window + SQLite Demo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Desktop Menu Bar ──────────────────────────────────────────
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add, size: 16),
                    onPressed: () => _openUserWindow(),
                    child: const MenuAcceleratorLabel('&New User\tCtrl+N'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.refresh, size: 16),
                    onPressed: _refreshUsers,
                    child: const MenuAcceleratorLabel('&Refresh\tCtrl+R'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.exit_to_app, size: 16),
                    onPressed: () {},
                    child: const MenuAcceleratorLabel('E&xit'),
                  ),
                ],
                child: const MenuAcceleratorLabel('&File'),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.info_outline, size: 16),
                    onPressed: _showAbout,
                    child: const MenuAcceleratorLabel('&About'),
                  ),
                ],
                child: const MenuAcceleratorLabel('&Help'),
              ),
            ],
          ),

          // ── Toolbar ───────────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _openUserWindow(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New User'),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                  onPressed: _refreshUsers,
                ),
              ],
            ),
          ),

          // ── Data Table — full width ───────────────────────────────────
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: theme.colorScheme.outlineVariant),
                        Text('No users yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline)),
                        FilledButton.icon(
                          onPressed: () => _openUserWindow(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first user'),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainerHighest),
                          showCheckboxColumn: false,
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          columns: const [
                            DataColumn(label: Text('ID'), numeric: true),
                            DataColumn(label: Expanded(child: Text('Name'))),
                            DataColumn(label: Expanded(child: Text('Date of Birth'))),
                            DataColumn(label: Expanded(child: Text('Cell Phone'))),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _users.map((user) {
                            return DataRow(
                              onSelectChanged: (_) =>
                                  _openUserWindow(user: user),
                              cells: [
                                DataCell(Text(user['id'].toString())),
                                DataCell(Text(user['name'])),
                                DataCell(Text(user['dob'])),
                                DataCell(Text(user['phone'])),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: theme.colorScheme.primary,
                                      tooltip: 'Edit',
                                      onPressed: () =>
                                          _openUserWindow(user: user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: theme.colorScheme.error,
                                      tooltip: 'Delete',
                                      onPressed: () =>
                                          _deleteUser(user['id']),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
          ),

          // ── Status Bar ────────────────────────────────────────────────
          Container(
            height: 28,
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.circle,
                    size: 10, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(_statusMessage,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
