import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'main_window.dart';
import 'theme_provider.dart';
import 'user_form_dialog.dart';

/// Global navigator key so we can open dialogs from tray callbacks.
final mainNavigatorKey = GlobalKey<NavigatorState>();

/// Called from tray to open "New User" dialog using the global navigator key.
void openNewUserDialog() {
  final ctx = mainNavigatorKey.currentContext;
  if (ctx == null) return;
  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => UserFormDialog(
      onSaved: () => MainWindowRefreshNotifier.instance.requestRefresh(),
    ),
  );
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── window_manager ────────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  // ── local_notifier ────────────────────────────────────────────────────
  await localNotifier.setup(appName: 'User Manager');

  // ── tray_manager ──────────────────────────────────────────────────────
  await trayManager.setIcon('assets/tray_icon.png');
  await trayManager.setContextMenu(Menu(
    items: [
      MenuItem(label: 'Show Window', onClick: (_) async {
        await windowManager.show();
        await windowManager.focus();
      }),
      MenuItem.separator(),
      MenuItem(label: 'New User', onClick: (_) async {
        await windowManager.show();
        await windowManager.focus();
        // Small delay so the window is in foreground before the dialog.
        await Future.delayed(const Duration(milliseconds: 200));
        openNewUserDialog();
      }),
      MenuItem(label: 'Refresh', onClick: (_) {
        MainWindowRefreshNotifier.instance.requestRefresh();
      }),
      MenuItem.separator(),
      MenuItem(label: 'Exit', onClick: (_) async {
        await trayManager.destroy();
        await windowManager.close();
        exit(0);
      }),
    ],
  ));
  if (Platform.isWindows || Platform.isMacOS) {
    await trayManager.setToolTip('User Manager');
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: mainNavigatorKey,
      title: 'User Manager',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainWindow(),
    );
  }
}

/// Simple notifier to request a data refresh from outside the widget tree.
class MainWindowRefreshNotifier extends ChangeNotifier {
  MainWindowRefreshNotifier._();
  static final instance = MainWindowRefreshNotifier._();
  void requestRefresh() => notifyListeners();
}
