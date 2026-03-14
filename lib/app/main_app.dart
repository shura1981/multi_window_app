import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_window_app/app/main_window_refresh_notifier.dart';
import 'package:multi_window_app/app/window/main_window.dart';
import 'package:multi_window_app/features/theme/theme_provider.dart';
import 'package:multi_window_app/features/users/user_form_dialog.dart';

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
