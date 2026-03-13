import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
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

String resolveTrayIconPath() {
  if (Platform.isWindows) {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <String>[
      // Running from a bundled app/exe.
      p.join(exeDir, 'resources', 'app_icon.ico'),
      // Running with `flutter run` from project root.
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'),
      // Defensive fallback for some runner layouts.
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),
    ];
    for (final iconPath in candidates) {
      if (File(iconPath).existsSync()) {
        return iconPath;
      }
    }
  }
  return 'assets/tray_icon.png';
}

Future<void> main(List<String> args) async {
  // ── desktop_webview_window ─────────────────────────────────────────────
  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();

  // ── window_manager ────────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  // ── local_notifier ────────────────────────────────────────────────────
  await localNotifier.setup(appName: 'User Manager');

  // ── tray_manager ──────────────────────────────────────────────────────
  await trayManager.setIcon(resolveTrayIconPath());
  await trayManager.setContextMenu(Menu(
    items: [
      MenuItem(label: 'Show Window', onClick: (_) async {
        if (!await windowManager.isFocused()) {
          if (await windowManager.isMinimized()) {
            await windowManager.restore();
          }
          if (Platform.isLinux) {
            // Unmap and remap to bypass Wayland focus stealing prevention completely
            await windowManager.hide();
          }
          await windowManager.show();
          await windowManager.setAlwaysOnTop(true);
          await windowManager.focus();
          await Future.delayed(const Duration(milliseconds: 300));
          await windowManager.setAlwaysOnTop(false);
        }
      }),
      MenuItem.separator(),
      MenuItem(label: 'New User', onClick: (_) async {
        if (!await windowManager.isFocused()) {
          if (await windowManager.isMinimized()) {
            await windowManager.restore();
          }
          if (Platform.isLinux) {
            await windowManager.hide();
          }
          await windowManager.show();
          await windowManager.setAlwaysOnTop(true);
          await windowManager.focus();
          await Future.delayed(const Duration(milliseconds: 300));
          await windowManager.setAlwaysOnTop(false);
        }
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
    final settings = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: mainNavigatorKey,
      title: 'User Manager',
      themeMode: settings.mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.color,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.color,
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
