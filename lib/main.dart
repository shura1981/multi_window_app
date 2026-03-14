import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:multi_window_app/app/bootstrap/tray_bootstrap.dart';
import 'package:multi_window_app/app/main_app.dart';
import 'package:multi_window_app/app/main_window_refresh_notifier.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── window_manager ────────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  // ── local_notifier ────────────────────────────────────────────────────
  await localNotifier.setup(appName: 'User Manager');

  // ── tray_manager ──────────────────────────────────────────────────────
  await setupSystemTray(
    onOpenNewUser: () async => openNewUserDialog(),
    onRefresh: () => MainWindowRefreshNotifier.instance.requestRefresh(),
    onExit: () async {
      await trayManager.destroy();
      await windowManager.close();
      exit(0);
    },
  );

  runApp(const ProviderScope(child: MainApp()));
}
