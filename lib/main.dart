import 'dart:convert';
import 'package:flutter/material.dart';
import 'main_window.dart';
import 'user_form_window.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  if (args.firstOrNull == 'multi_window') {
    final windowController = await WindowController.fromCurrentEngine();
    
    final argument = windowController.arguments.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(windowController.arguments) as Map<String, dynamic>;
        
    final user = argument['user'] as Map<String, dynamic>?;
    final mainWindowId = argument['mainWindowId'] as String?;

    runApp(SubWindowApp(user: user, mainWindowId: mainWindowId));
  } else {
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Multi Window App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
      title: 'Form Window',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: UserFormWindow(initialData: user, mainWindowId: mainWindowId),
    );
  }
}
