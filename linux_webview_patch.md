# Parche Vital para Linux Multi-ventana (`desktop_webview_window`)

> **[❗IMPORTANTE❗]**
> Si en el futuro ejecutas `flutter pub cache clean`, `flutter clean` seguido de un reestablecimiento fuerte de dependencias, o si **actualizas el paquete `desktop_webview_window`** a una versión posterior que no tenga arreglado este problema oficialemente en Pub.dev, **LA APLICACIÓN VOLVERÁ A ROMPERSE EN LINUX** al cerrar ventanas secundarias del navegador (Crash de motor Flutter / OpenGL Context Loss / Use-After-Free Segmentation Fault).

Este parche C++ nativo es estrictamente obligatorio para mantener la estabilidad del núcleo gráfico en `Ubuntu/Wayland/X11` mientras utilices el plugin multiventana de navegadores.

---

## 🛠 Instrucciones de Reconstrucción del Parche

### 1. Localizar el Archivo C++ Vulnerable
El plugin se descarga globalmente (o en tu caché de proyecto). Debes buscar y editar exactamente este archivo fuente dentro del ecosistema oculto de `.pub-cache`:

```bash
~/.pub-cache/hosted/pub.dev/desktop_webview_window-<VERSION>/linux/webview_window.cc
```
*(Nota: Asegúrate de buscar la carpeta con la <VERSION> que estés usando, por ej. `0.2.3`)*

### 2. Aplicar la Corrección de "Use-After-Free" (Evitar Segmentation Fault)
Busca la definición inicial del constructor `WebviewWindow::WebviewWindow` alrededor de la línea `66`.
Verás un bloque de código `g_signal_connect(...)` apuntando al evento `"destroy"`.

**Debes intercambiar el orden de destrucción y notificación para que Flutter se entere ANTES de que la RAM se libere.**

**MAL (Original):**
```cpp
  g_signal_connect(G_OBJECT(window_), "destroy",
                   G_CALLBACK(+[](GtkWidget *, gpointer arg) {
                     auto *window = static_cast<WebviewWindow *>(arg);
                     if (window->on_close_callback_) {
                       window->on_close_callback_();
                     } // <--- SE DESTRUYE LA VENTANA EN MEMORIA AQUÍ
                     auto *args = fl_value_new_map();
                     fl_value_set(args, fl_value_new_string("id"), fl_value_new_int(window->window_id_)); // <--- CRASH: TRATA DE LEER EL ID DE LA MEMORIA QUE ACABA DE DESTRUIR
                     fl_method_channel_invoke_method( ... );
                   }), this);
```

**CORRECTO (Reemplazar todo el bloque "destroy" por esto):**
```cpp
  g_signal_connect(G_OBJECT(window_), "destroy",
                   G_CALLBACK(+[](GtkWidget *, gpointer arg) {
                     auto *window = static_cast<WebviewWindow *>(arg);
                     // 1. Notificar a Dart primero (SEGURO)
                     auto *args = fl_value_new_map();
                     fl_value_set(args, fl_value_new_string("id"), fl_value_new_int(window->window_id_));
                     fl_method_channel_invoke_method(
                         FL_METHOD_CHANNEL(window->method_channel_), "onWindowClose", args,
                         nullptr, nullptr, nullptr);
                     
                     // 2. Destruir la memoria de la ventana al C/C++ después (SEGURO)    
                     if (window->on_close_callback_) {
                       window->on_close_callback_();
                     }
                   }), this);
```

### 3. Aplicar Corrección de Choque OpenGL (Evitar Freeze del Main Engine)
Ahí mismo en ese archivo `webview_window.cc`, baja un poco hasta la línea `85` aprox, en la zona que dice `// initial flutter_view`.
Este plugin trata de incrustar **una segunda vista Flutter híbrida (FlView)** en el tope del navegador solo para pintar unos botones. Esto colapsa el motor OpenGL/GTK en distribuciones Linux modernas bajo Multiprocesamiento.

**Debes COMENTAR por completo la inyección del `title_bar` y su `handler_id`.**

**CORRECTO (Comentar estas 12 líneas de C++):**
```cpp
  // COMINEZAN LOS COMENTARIOS DE EXTIRPACIÓN -------------------
  // initial flutter_view is DISABLED to prevent Flutter Engine crashes on Linux
  // g_autoptr(FlDartProject) project = fl_dart_project_new();
  // const char *args[] = {"web_view_title_bar", g_strdup_printf("%ld", window_id), nullptr};
  // fl_dart_project_set_dart_entrypoint_arguments(project, const_cast<char **>(args));
  // auto *title_bar = fl_view_new(project);

  // g_autoptr(FlPluginRegistrar) desktop_webview_window_registrar =
  //     fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(title_bar), "DesktopWebviewWindowPlugin");
  // client_message_channel_plugin_register_with_registrar(desktop_webview_window_registrar);

  // gtk_widget_set_size_request(GTK_WIDGET(title_bar), -1, title_bar_height);
  // gtk_widget_set_vexpand(GTK_WIDGET(title_bar), FALSE);
  // gtk_box_pack_start(box_, GTK_WIDGET(title_bar), FALSE, FALSE, 0);
  // TERMINA EXTIRPACIÓN -------------------
```

Más abajo al final del constructor (alrededor de la línea `118`), comenta también la referencia basura estática final al título:
```cpp
  // FROM: https://github.com/leanflutter/window_manager/pull/343
  // Disconnect all delete-event handlers first in flutter 3.10.1, which causes delete_event not working.
  // Issues from flutter/engine: https://github.com/flutter/engine/pull/40033
  // guint handler_id = g_signal_handler_find(window_, G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, title_bar);
  // if (handler_id > 0) {
  //   g_signal_handler_disconnect(window_, handler_id);
  // }
```

### 4. Recompilar
Una vez guardes el archivo nativo `.cc` modificado en la carpeta del cache, simplemente recompila limpiamente tu proyecto para que `CMake` inyecte el parche C++ de nuevo al binario final de tu app:

```bash
flutter run -d linux
```
