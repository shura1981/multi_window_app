# WebView en Linux — Incompatibilidades (Flutter stable 3.41)

> **Conclusión (verificado marzo 2026):** No existe ningún plugin de webview funcional para Flutter Linux desktop en stable 3.41. **Usar `url_launcher` para abrir URLs en el navegador del sistema operativo.**

---

## Plugins evaluados y descartados

| Plugin | Versión | Error | Veredicto |
|---|---|---|---|
| `webview_flutter` | `^4.13.1` | `WebViewPlatform.instance != null` — sin implementación Linux | ❌ No usar |
| `flutter_inappwebview` | `^6.1.5` | `InAppWebViewPlatform.instance != null` — backend GTK no se registra | ❌ No usar |
| `desktop_webview_window` | `^0.2.3` | Segfault + cierra toda la app al cerrar ventana | ❌ No usar |

---

## Alternativa recomendada: `url_launcher`

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> abrirEnNavegador(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

`url_launcher` está incluido en las dependencias del proyecto (vía otros plugins) y funciona en todas las plataformas: Linux, macOS, Windows, iOS, Android.

---

## Historial de intentos en este proyecto

1. **`desktop_webview_window: ^0.2.3`** — Eliminado. Requería parche C++ manual en `.pub-cache` (no mantenible). Al cerrar la ventana webview crasheaba toda la app por segfault en la señal `destroy` de GTK.

2. **`webview_flutter: ^4.13.1`** — Eliminado. Error en runtime: `WebViewPlatform.instance != null`. El paquete no incluye implementación para Linux.

3. **`flutter_inappwebview: ^6.1.5`** — Eliminado. Error en runtime: `InAppWebViewPlatform.instance != null`. Documenta soporte Linux/WebKitGTK pero no funciona en Flutter stable 3.41.

**Decisión final:** retirar todo el módulo de browser embebido. La funcionalidad de abrir URLs se delega al navegador del sistema con `url_launcher`.

