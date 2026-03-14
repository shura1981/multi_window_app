---
name: scaffold-flutter-desktop
description: Scaffold or generate a new Flutter desktop project based on the multi_window_app template. Use when the user asks to create, generate, scaffold, or start a new Flutter desktop application with any of these features: system tray (tray_manager), window management (window_manager), multi-window (desktop_multi_window), SQLite database (sqflite_common_ffi), Riverpod + SharedPreferences theme management, PDF printing (pdf + printing), Linux/Wayland window focus, desktop_webview_window. Run the scaffold script or generate code from templates. Triggers: "nuevo proyecto flutter", "crear app de escritorio", "generar proyecto", "scaffold", "template flutter desktop".
license: Apache-2.0
---

# scaffold-flutter-desktop

Generates a new Flutter desktop project based on the battle-tested `multi_window_app` template, which includes: system tray, window lifecycle management, Linux/Wayland workarounds, Riverpod + SharedPreferences themes, optional SQLite, and optional PDF printing.

## When to Use This Skill

* User asks to create, scaffold, or generate a new Flutter desktop project.
* User wants to reuse multi-window, tray, window_manager, or SQLite boilerplate.
* User wants a clean starting point that incorporates patterns from the reference project.

## Prerequisites

* Flutter SDK available (`flutter --version`).
* Python 3.9+ available (`python3 --version`).
* `fvm` optional — script calls `flutter` directly; replace with `fvm flutter` if needed.
* For Linux: GTK development libraries installed (`libgtk-3-dev`, `libglib2.0-dev`).

## Available Features (selectable via `--features`)

| Feature flag | What it includes |
|---|---|
| `tray` | `tray_manager ^0.5.2` + tray icon, context menu, Wayland focus workaround |
| `window` | `window_manager` (git-pinned) + prevent-close, minimize-to-tray lifecycle |
| `notify` | `local_notifier ^0.1.6` + desktop notifications |
| `sqlite` | `sqflite_common_ffi ^2.4.0` + `path_provider` + generic `DatabaseHelper` |
| `theme` | `flutter_riverpod ^3.2.1` + `shared_preferences ^2.5.4` + `ThemeSettingsNotifier` |
| `print` | `pdf ^3.11.3` + `printing ^5.14.2` + `PrintService` + `PrintDialog` |
| `webview` | `desktop_webview_window ^0.2.3` + title-bar init guard + Linux C++ patch note |
| `multiwindow` | `desktop_multi_window ^0.3.0` + `WindowController` sub-window scaffold |

Default (no flags): all features included.

## Step-by-Step Workflow

### Option A — Run the scaffold script (automated)

```bash
python3 .github/skills/scaffold-flutter-desktop/scripts/scaffold.py \
  --name my_new_app \
  --id com.example.my_new_app \
  --display "My New App" \
  --desc "A Flutter desktop application" \
  --out /path/to/output
```

The script will:
1. Copy all template files from `templates/` into a new directory `<out>/<name>/`.
2. Replace all `{{PLACEHOLDER}}` tokens with your values.
3. Run `flutter pub get` in the new project.

### Option B — AI-generate from templates (interactive)

When the user describes their project, use the templates in `templates/` as starting points:

1. Read `templates/pubspec.yaml.tmpl` — adjust dependencies to include only needed features.
2. Read `templates/lib/main.dart.tmpl` — the entry point with tray/window/webview init.
3. Read `templates/lib/main_window.dart.tmpl` — the main window scaffold.
4. Read `templates/lib/theme_provider.dart.tmpl` — Riverpod theme state (copy verbatim).
5. Read `templates/lib/database_helper.dart.tmpl` — SQLite helper (if `sqlite` feature needed).
6. Read `templates/linux/CMakeLists.txt.tmpl` — replace `APPLICATION_ID` for Linux.
7. Replace all `{{PLACEHOLDER}}` tokens, then create the project files.

## Placeholder Reference

| Placeholder | Example value | Description |
|---|---|---|
| `{{PROJECT_NAME}}` | `my_new_app` | Snake_case package name |
| `{{APP_NAME}}` | `My New App` | Human-readable display name |
| `{{APP_ID}}` | `com.example.my_new_app` | Reverse-domain application ID |
| `{{APP_DESCRIPTION}}` | `A Flutter app` | Short description for pubspec |
| `{{TABLE_NAME}}` | `items` | SQLite main table name |

## Troubleshooting

| Problem | Solution |
|---|---|
| `flutter pub get` fails after scaffold | Check internet connection; run manually in the new project dir |
| Linux app crashes on WebView close | Apply C++ patch — see [desktop_plugin_bugs.md](../../flutter_expert/references/desktop_plugin_bugs.md) |
| Tray icon missing on Windows | `resolveTrayIconPath()` is included in `main.dart.tmpl` — add `.ico` to `windows/runner/resources/` |
| Window not raised on Wayland | Focus sequence in `main_window.dart.tmpl` handles this — do not simplify it |
| `sqfliteFfiInit()` not called error | Ensure `database_helper.dart.tmpl` init block is present before first db call |

## References

* [main.dart template](./templates/lib/main.dart.tmpl)
* [main_window.dart template](./templates/lib/main_window.dart.tmpl)
* [theme_provider.dart template](./templates/lib/theme_provider.dart.tmpl)
* [database_helper.dart template](./templates/lib/database_helper.dart.tmpl)
* [pubspec.yaml template](./templates/pubspec.yaml.tmpl)
* [linux CMakeLists template](./templates/linux/CMakeLists.txt.tmpl)
* [scaffold script](./scripts/scaffold.py)
* [flutter_expert skill — desktop patterns](../../flutter_expert/references/desktop_project_patterns.md)
* [flutter_expert skill — plugin bugs](../../flutter_expert/references/desktop_plugin_bugs.md)
