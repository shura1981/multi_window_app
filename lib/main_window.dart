import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'database_helper.dart';
import 'main.dart' show MainWindowRefreshNotifier;
import 'user_form_dialog.dart';
import 'system_monitor_dialog.dart';
import 'print_dialog.dart';
import 'theme_settings_dialog.dart';
import 'email_service.dart';
import 'email_view.dart';

enum ViewState { users, emails }

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow>
    with WindowListener, TrayListener {
  List<Map<String, dynamic>> _users = [];
  String _statusMessage = 'Ready';
  ViewState _currentView = ViewState.users;
  
  // NOTE: Replace these with actual cPanel IMAP credentials
  final EmailService _emailService = EmailService(
    host: 'mail.upnlab.com',
    username: 'prueba@upnlab.com',
    password: 'z6sXaPw?+IKz',
  );

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    // Allow tray "Refresh" action to trigger data reload.
    MainWindowRefreshNotifier.instance.addListener(_refreshUsers);
    _refreshUsers();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    MainWindowRefreshNotifier.instance.removeListener(_refreshUsers);
    super.dispose();
  }

  /// Double-click the tray icon → show and focus the main window.
  @override
  void onTrayIconMouseDown() async {
    if (!await windowManager.isFocused()) {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      if (Platform.isLinux) {
        // Unmap and remap to force Wayland to bring the window to front without focus-stealing prevention
        await windowManager.hide();
      }
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 300));
      await windowManager.setAlwaysOnTop(false);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseUp() {
    if (Platform.isLinux) {
      trayManager.popUpContextMenu();
    }
  }

  /// Intercepts the OS X button — shows a confirmation dialog first.
  @override
  void onWindowClose() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Application'),
        content: const Text('Are you sure you want to close User Manager?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await windowManager.close();
      exit(0);
    }
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

  Future<void> _openUserDialog({Map<String, dynamic>? user}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserFormDialog(
        initialData: user,
        onSaved: _refreshUsers,
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
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

  void _showSystemMonitor() {
    showDialog(
      context: context,
      builder: (_) => const SystemMonitorDialog(),
    );
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (_) => PrintDialog(usersToPrint: _users),
    );
  }

  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (_) => const ThemeSettingsDialog(),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'User Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Flutter 3.41 Desktop — SQLite Demo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _openUserDialog(),
          const SingleActivator(LogicalKeyboardKey.keyM, control: true): _showSystemMonitor,
          const SingleActivator(LogicalKeyboardKey.keyP, control: true): _showPrintDialog,
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refreshUsers,
          const SingleActivator(LogicalKeyboardKey.keyT, control: true): _showThemeSettings,
          const SingleActivator(LogicalKeyboardKey.f1): _showAbout,
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => setState(() => _currentView = ViewState.users),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => setState(() => _currentView = ViewState.emails),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight < 100 || constraints.maxWidth < 100) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          // ── Menu Bar ─────────────────────────────────────────────────
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add, size: 16),
                    onPressed: () => _openUserDialog(),
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                    child: const MenuAcceleratorLabel('&New User\tCtrl+N'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.monitor, size: 16),
                    onPressed: _showSystemMonitor,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyM, control: true),
                    child: const MenuAcceleratorLabel('&System Monitor (htop)\tCtrl+M'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.print, size: 16),
                    onPressed: _showPrintDialog,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyP, control: true),
                    child: const MenuAcceleratorLabel('&Print Table\tCtrl+P'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.refresh, size: 16),
                    onPressed: _refreshUsers,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true),
                    child: const MenuAcceleratorLabel('&Refresh\tCtrl+R'),
                  ),
                  const Divider(),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.exit_to_app, size: 16),
                    onPressed: () => onWindowClose(),
                    child: const MenuAcceleratorLabel('E&xit'),
                  ),
                ],
                child: const MenuAcceleratorLabel('&File'),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.people, size: 16),
                    onPressed: () {
                      setState(() => _currentView = ViewState.users);
                    },
                    shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
                    child: const MenuAcceleratorLabel('Ventana &Principal\tCtrl+1'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.email, size: 16),
                    onPressed: () {
                       setState(() => _currentView = ViewState.emails);
                    },
                    shortcut: const SingleActivator(LogicalKeyboardKey.digit2, control: true),
                    child: const MenuAcceleratorLabel('Ver &Correo\tCtrl+2'),
                  ),

                ],
                child: const MenuAcceleratorLabel('&Modo'),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.palette, size: 16),
                    onPressed: _showThemeSettings,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyT, control: true),
                    child: const MenuAcceleratorLabel('&Theme Settings\tCtrl+T'),
                  ),
                ],
                child: const MenuAcceleratorLabel('&View'),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.info_outline, size: 16),
                    onPressed: _showAbout,
                    shortcut: const SingleActivator(LogicalKeyboardKey.f1),
                    child: const MenuAcceleratorLabel('&About\tF1'),
                  ),
                ],
                child: const MenuAcceleratorLabel('&Help'),
              ),
            ],
          ),

          // ── Data Table — full width ───────────────────────────────────
          Expanded(
            child: _currentView == ViewState.emails
              ? EmailView(emailService: _emailService)
              : _users.isEmpty
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
                          onPressed: () => _openUserDialog(),
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
                            DataColumn(
                                label: Expanded(child: Text('Date of Birth'))),
                            DataColumn(
                                label: Expanded(child: Text('Cell Phone'))),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _users.map((user) {
                            return DataRow(
                              onSelectChanged: (_) =>
                                  _openUserDialog(user: user),
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
                                          _openUserDialog(user: user),
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.delete, size: 18),
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
                Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(_statusMessage,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
              );
            },
          ),
        ),
      ),
    );
  }
}
