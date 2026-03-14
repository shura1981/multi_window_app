#!/bin/bash
# Script de empaquetado .deb para multi_window_app
# Uso: ./linux/installer/build_deb.sh

# Navegamos siempre a la raíz del proyecto sin importar desde dónde se invoque.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_ROOT"

# ─── Variables del proyecto ────────────────────────────────────────────────
APP_NAME="multi-window-app"
APP_EXEC="multi_window_app"
APP_VERSION="1.0.1"
# ──────────────────────────────────────────────────────────────────────────

ARCH="amd64"
DEB_DIR_NAME="${APP_NAME}_${APP_VERSION}_${ARCH}"
INSTALLER_DIR="linux/installer"
RELEASES_DIR="${INSTALLER_DIR}/releases"
BUILD_BUNDLE_DIR="build/linux/x64/release/bundle"
DEB_STAGING_DIR="${INSTALLER_DIR}/${DEB_DIR_NAME}"

# Extraemos el Application ID configurado en CMakeLists.txt para GNOME/Wayland
APP_ID=$(grep 'set(APPLICATION_ID' linux/CMakeLists.txt | awk -F '"' '{print $2}')
if [ -z "$APP_ID" ]; then
    APP_ID="$APP_EXEC"
fi

echo "=========================================================="
echo "          Generando Instalador .deb para Linux            "
echo "=========================================================="

# 1. Compilar aplicación para Linux
echo "=========================================================="
echo "          Compilando Proyecto Flutter para Linux          "
echo "=========================================================="
fvm flutter build linux

if [ $? -ne 0 ]; then
    echo "Error: La compilación de Flutter falló."
    exit 1
fi

# 2. Verificar que el bundle existe
if [ ! -d "$BUILD_BUNDLE_DIR" ]; then
    echo "Error: No se encontró el bundle en $BUILD_BUNDLE_DIR"
    exit 1
fi

# 3. Limpiar directorio de staging anterior
if [ -d "$DEB_STAGING_DIR" ]; then
    echo "Limpiando directorio temporal anterior..."
    rm -rf "$DEB_STAGING_DIR"
fi

# 4. Crear estructura de directorios del paquete .deb
echo "Creando estructura de directorios..."
mkdir -p "${DEB_STAGING_DIR}/DEBIAN"
mkdir -p "${DEB_STAGING_DIR}/opt/${APP_EXEC}"
mkdir -p "${DEB_STAGING_DIR}/usr/share/applications"
mkdir -p "${DEB_STAGING_DIR}/usr/share/pixmaps"

# 5. Copiar binarios de la aplicación
echo "Copiando binarios de la aplicación..."
cp -R ${BUILD_BUNDLE_DIR}/* "${DEB_STAGING_DIR}/opt/${APP_EXEC}/"

# 6. Copiar el icono
echo "Copiando icono..."
if [ -f "${INSTALLER_DIR}/icon.png" ]; then
    cp "${INSTALLER_DIR}/icon.png" "${DEB_STAGING_DIR}/usr/share/pixmaps/${APP_EXEC}.png"
else
    echo "Advertencia: No se encontró icon.png en ${INSTALLER_DIR}/"
fi

# 7. Crear archivo DEBIAN/control
echo "Generando archivo de control..."
cat << EOF > "${DEB_STAGING_DIR}/DEBIAN/control"
Package: ${APP_NAME}
Version: ${APP_VERSION}
Architecture: ${ARCH}
Maintainer: Steven <steven@example.com>
Description: Gestor de usuarios
 Aplicación de escritorio Flutter con soporte multi-ventana.
EOF

# 8. Crear archivo .desktop
echo "Generando archivo .desktop..."
cat << EOF > "${DEB_STAGING_DIR}/usr/share/applications/${APP_ID}.desktop"
[Desktop Entry]
Version=1.0
Name=Multi Window App
Comment=Gestor de usuarios
Exec=/opt/${APP_EXEC}/${APP_EXEC} %u
Icon=${APP_EXEC}
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=${APP_ID}
Actions=new-window;

[Desktop Action new-window]
Name=Nueva ventana
Exec=/opt/${APP_EXEC}/${APP_EXEC}
EOF

# 9. Permisos correctos
chmod +x "${DEB_STAGING_DIR}/opt/${APP_EXEC}/${APP_EXEC}"
chmod 644 "${DEB_STAGING_DIR}/usr/share/applications/${APP_ID}.desktop"
chmod 644 "${DEB_STAGING_DIR}/usr/share/pixmaps/${APP_EXEC}.png"

# 10. Construir el paquete .deb
echo "Construyendo el paquete .deb..."
mkdir -p "$RELEASES_DIR"
dpkg-deb --root-owner-group --build "$DEB_STAGING_DIR" "${RELEASES_DIR}/${DEB_DIR_NAME}.deb"

if [ $? -eq 0 ]; then
    echo "=========================================================="
    echo "¡Éxito! El paquete .deb se ha generado correctamente."
    echo "Archivo: ${RELEASES_DIR}/${DEB_DIR_NAME}.deb"
    echo "Instalar con: sudo dpkg -i ${RELEASES_DIR}/${DEB_DIR_NAME}.deb"
    echo "=========================================================="
    rm -rf "$DEB_STAGING_DIR"
else
    echo "Error al construir el paquete .deb."
    exit 1
fi
