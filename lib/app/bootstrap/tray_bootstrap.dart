import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

Future<void> focusMainWindow() async {
  if (!await windowManager.isFocused()) {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    if (Platform.isLinux) {
      // Unmap and remap to bypass Wayland focus-stealing prevention.
      await windowManager.hide();
    }
    await windowManager.show();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    await Future.delayed(const Duration(milliseconds: 300));
    await windowManager.setAlwaysOnTop(false);
  }
}

String resolveTrayIconPath() {
  if (Platform.isWindows) {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <String>[
      p.join(exeDir, 'resources', 'app_icon.ico'),
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'),
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),
    ];
    for (final iconPath in candidates) {
      if (File(iconPath).existsSync()) {
        return iconPath;
      }
    }
  }
  return 'assets/tray_icon_48x48.png';
}

Future<void> setupSystemTray({
  required Future<void> Function() onOpenNewUser,
  required void Function() onRefresh,
  required Future<void> Function() onExit,
}) async {
  await trayManager.setIcon(resolveTrayIconPath());
  await trayManager.setContextMenu(Menu(
    items: [
      MenuItem(
        label: 'Show Window',
        onClick: (_) async => focusMainWindow(),
      ),
      MenuItem.separator(),
      MenuItem(
        label: 'New User',
        onClick: (_) async {
          await focusMainWindow();
          await Future.delayed(const Duration(milliseconds: 200));
          await onOpenNewUser();
        },
      ),
      MenuItem(
        label: 'Refresh',
        onClick: (_) => onRefresh(),
      ),
      MenuItem.separator(),
      MenuItem(
        label: 'Exit',
        onClick: (_) async => onExit(),
      ),
    ],
  ));

  if (Platform.isWindows || Platform.isMacOS) {
    await trayManager.setToolTip('User Manager');
  }
}
