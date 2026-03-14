# Plugin Bugs & Patches — Flutter Desktop Linux

Este documento cataloga bugs conocidos de plugins de Flutter Desktop en Linux, sus síntomas exactos, causa raíz y el parche obligatorio para solucionarlos. Cada entrada incluye código de producción verificado.

> **⚠️ Nota importante:** Los parches aquí descritos se aplican directamente al código fuente del plugin en `~/.pub-cache/`. Esto significa que **se pierden** si ejecutas `flutter pub cache clean` o actualizas la versión del plugin. Debes reaplicarlos manualmente en ese caso.

---

## Bug 1 — `desktop_webview_window` Crash en Linux al Cerrar Ventana WebView

**Versión afectada:** `desktop_webview_window: ^0.2.3` (y versiones anteriores — no corregido en pub.dev a 2026)

**Plataforma:** Linux únicamente (Ubuntu/Wayland/X11)

### Síntomas

- La app entera crashea con **Segmentation Fault** al cerrar cualquier ventana del WebView.
- En la consola aparece: `signal 11` o `Use-After-Free` cerca de `webview_window.cc:66`.
- En segundo crash: **freeze o pérdida del contexto OpenGL** del motor Flutter principal al abrir la primera ventana WebView.

```
[flutter] Fatal error: signal 11 (SIGSEGV), address 0x...
Context Loss / Use-After-Free at webview_window.cc line ~66
flutter: OpenGL context loss after secondary window close
```

### Causa Raíz

Dos bugs independientes en `linux/webview_window.cc`:

1. **Use-After-Free:** En la señal `"destroy"` de la ventana GTK, el código original destruye primero la memoria C++ de la ventana y luego intenta leer `window->window_id_` para notificar a Dart — accediendo a memoria ya liberada.

2. **Colapso OpenGL:** El plugin intenta incrustar una segunda instancia Flutter (`fl_view_new`) dentro de la ventana del WebView para renderizar botones de barra de título. En Linux con multiprocesamiento, esto colapsa el motor OpenGL/GTK del proceso principal.

### Localizar el archivo a parchear

```bash
~/.pub-cache/hosted/pub.dev/desktop_webview_window-0.2.3/linux/webview_window.cc
# Ajusta la versión según la que tengas
find ~/.pub-cache -name "webview_window.cc" -path "*/desktop_webview_window*"
```

---

### Parche 1 — Use-After-Free en la señal `"destroy"` (línea ~66)

Busca el bloque `g_signal_connect(G_OBJECT(window_), "destroy", ...)` dentro del constructor `WebviewWindow::WebviewWindow`.

**❌ ORIGINAL — buggy:**
```cpp
g_signal_connect(G_OBJECT(window_), "destroy",
                 G_CALLBACK(+[](GtkWidget *, gpointer arg) {
                   auto *window = static_cast<WebviewWindow *>(arg);
                   if (window->on_close_callback_) {
                     window->on_close_callback_(); // ← LIBERA MEMORIA AQUÍ
                   }
                   // ← CRASH: lee window_id_ de memoria ya liberada
                   auto *args = fl_value_new_map();
                   fl_value_set(args, fl_value_new_string("id"),
                       fl_value_new_int(window->window_id_));
                   fl_method_channel_invoke_method(
                       FL_METHOD_CHANNEL(window->method_channel_),
                       "onWindowClose", args, nullptr, nullptr, nullptr);
                 }), this);
```

**✅ CORRECTO — notificar Dart ANTES de liberar memoria:**
```cpp
g_signal_connect(G_OBJECT(window_), "destroy",
                 G_CALLBACK(+[](GtkWidget *, gpointer arg) {
                   auto *window = static_cast<WebviewWindow *>(arg);
                   // 1. Notificar a Dart PRIMERO (memoria aún válida)
                   auto *args = fl_value_new_map();
                   fl_value_set(args, fl_value_new_string("id"),
                       fl_value_new_int(window->window_id_));
                   fl_method_channel_invoke_method(
                       FL_METHOD_CHANNEL(window->method_channel_),
                       "onWindowClose", args, nullptr, nullptr, nullptr);
                   // 2. Liberar memoria C++ DESPUÉS
                   if (window->on_close_callback_) {
                     window->on_close_callback_();
                   }
                 }), this);
```

---

### Parche 2 — Colapso OpenGL por inyección de `FlView` como barra de título (línea ~85)

Busca el comentario `// initial flutter_view` o `fl_view_new(project)` dentro del mismo constructor.

**✅ CORRECTO — comentar por completo el bloque de inyección:**
```cpp
// DISABLED: prevents Flutter Engine OpenGL crash on Linux multiprocess
// g_autoptr(FlDartProject) project = fl_dart_project_new();
// const char *args[] = {"web_view_title_bar", g_strdup_printf("%ld", window_id), nullptr};
// fl_dart_project_set_dart_entrypoint_arguments(project, const_cast<char **>(args));
// auto *title_bar = fl_view_new(project);
//
// g_autoptr(FlPluginRegistrar) desktop_webview_window_registrar =
//     fl_plugin_registry_get_registrar_for_plugin(
//         FL_PLUGIN_REGISTRY(title_bar), "DesktopWebviewWindowPlugin");
// client_message_channel_plugin_register_with_registrar(desktop_webview_window_registrar);
//
// gtk_widget_set_size_request(GTK_WIDGET(title_bar), -1, title_bar_height);
// gtk_widget_set_vexpand(GTK_WIDGET(title_bar), FALSE);
// gtk_box_pack_start(box_, GTK_WIDGET(title_bar), FALSE, FALSE, 0);
```

También comentar el `handler_id` residual cerca del final del constructor (~línea 118):
```cpp
// guint handler_id = g_signal_handler_find(
//     window_, G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, title_bar);
// if (handler_id > 0) {
//   g_signal_handler_disconnect(window_, handler_id);
// }
```

---

### Integración en Dart — `main()` (obligatoria)

El plugin requiere delegar args de arranque **antes** de cualquier otra inicialización:

```dart
Future<void> main(List<String> args) async {
  // DEBE ser la primera línea — sin mover, sin condición previa
  if (runWebViewTitleBarWidget(args)) return;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // ... resto de la inicialización
}
```

---

### Recompilar tras el parche

```bash
flutter clean && flutter run -d linux
# o para build de release:
flutter clean && flutter build linux --release
```

---

### Contingencia si el parche se pierde

Si después de actualizar dependencias o limpiar el cache el crash vuelve:

```bash
# Encontrar la versión instalada
find ~/.pub-cache -name "webview_window.cc" -path "*/desktop_webview_window*"

# Editar el archivo directamente
nano ~/.pub-cache/hosted/pub.dev/desktop_webview_window-<VERSION>/linux/webview_window.cc

# Luego recompilar
flutter clean && flutter run -d linux
```

---

## Tabla resumen de bugs documentados

| Plugin | Versión afectada | Plataforma | Bug | Estado en pub.dev |
|---|---|---|---|---|
| `desktop_webview_window` | `^0.2.3` | Linux | Use-after-free Segfault al cerrar WebView | ❌ No corregido (2026) |
| `desktop_webview_window` | `^0.2.3` | Linux | Colapso OpenGL por `FlView` embebido | ❌ No corregido (2026) |
