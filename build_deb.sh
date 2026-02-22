#!/bin/bash
# Script para empaquetar la aplicación Flutter a un archivo .deb de forma segura
# Evita los bugs de auto-detección de 'flutter_to_debian' con ldd/libc6

echo "==> Armando estructura del paquete Debian..."
# Ejecutamos flutter_to_debian en inglés. Sabemos que va a fallar en la fase final (dpkg-deb), 
# pero la estructura de carpetas /tmp/flutter_debian/... se generará correctamente.
LC_ALL=C flutter_to_debian >/dev/null 2>&1 || true

CONTROL_FILE="/tmp/flutter_debian/multi-window-app_1.0.0_amd64/DEBIAN/control"

if [ -f "$CONTROL_FILE" ]; then
    echo "==> Reparando dependencias corruptas en DEBIAN/control..."
    # Reemplazamos la línea de dependencias rota por una lista estable y limpia
    sed -i 's/^Depends:.*/Depends: libayatana-appindicator3-1, libc6, libglib2.0-dev, libjpeg-turbo8, libnotify4, libstdc++6/g' "$CONTROL_FILE"
    
    # Reemplazamos Maintainer "unknown" si aparece
    sed -i 's/^Maintainer:unknown/Maintainer:Steven/g' "$CONTROL_FILE"
    
    echo "==> Compilando paquete .deb final..."
    dpkg-deb --build /tmp/flutter_debian/multi-window-app_1.0.0_amd64 .
    echo ""
    echo "[✓] ¡Paquete Debian (.deb) generado exitosamente en este directorio!"
else
    echo "[✗] Error: No se encontró la estructura de DEBIAN/control. Fallo crítico al exportar."
    exit 1
fi
