import 'dart:convert';
import 'package:flutter/material.dart';
import 'main_window.dart';
import 'user_form_window.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.firstOrNull == 'multi_window') {
    // ── Child/form window ──────────────────────────────────────────────
    await windowManager.ensureInitialized();
    final windowController = await WindowController.fromCurrentEngine();

    final argument = windowController.arguments.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(windowController.arguments) as Map<String, dynamic>;

    final user = argument['user'] as Map<String, dynamic>?;
    final mainWindowId = argument['mainWindowId'] as String?;

    // Size and center BEFORE parent calls show()
    await windowManager.setSize(const Size(420, 480));
    await windowManager.center();
    // Prevent the OS X button from destroying the Flutter engine.
    // Instead we'll intercept and call hide() via WindowListener.
    await windowManager.setPreventClose(true);

    runApp(SubWindowApp(user: user, mainWindowId: mainWindowId));
  } else {
    // ── Main window — do NOT use windowManager (causes GTK MenuBar crash) ──
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
      ),
      home: const MainWindow(),
    );
  }
}

class SubWindowApp extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String? mainWindowId;
  const SubWindowApp({super.key, this.user, this.mainWindowId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Form',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: UserFormWindow(initialData: user, mainWindowId: mainWindowId),
    );
  }
}
