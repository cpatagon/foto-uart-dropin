#!/bin/bash
"""
Script de Instalación Completa para Raspberry Pi
================================================
Instala FotoUART con capacidades de auto-actualización y configura servicios.

Uso:
    curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_raspberry_pi.sh | bash
    
    O manualmente:
    chmod +x install_raspberry_pi.sh
    ./install_raspberry_pi.sh [--auto-update] [--service]
"""

set -euo pipefail

# Configuración
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
INSTALL_DIR="$HOME/$PROJECT_NAME"
USER=$(whoami)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables de instalación
SETUP_AUTO_UPDATE=false
SETUP_SERVICE=false
BRANCH="main"

# Funciones de utilidad
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Mostrar ayuda
show_help() {
    cat << EOF
Script de Instalación FotoUART Drop-in

Uso: $0 [opciones]

Opciones:
    --auto-update    Configurar auto-actualización automática
    --service        Instalar como servicio systemd
    --branch=RAMA    Especificar rama git (default: main)
    --help           Mostrar esta ayuda

Ejemplos:
    $0                           # Instalación básica
    $0 --auto-update --service  # Instalación completa con servicio
    $0 --branch=develop         # Instalar rama develop
EOF
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-update)
            SETUP_AUTO_UPDATE=true
            shift
            ;;
        --service)
            SETUP_SERVICE=true
            shift
            ;;
        --branch=*)
            BRANCH="${1#*=}"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Argumento desconocido: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verificar sistema
check_system() {
    info "Verificando sistema..."
    
    # Verificar que es Raspberry Pi OS
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        warn "Este script está optimizado para Raspberry Pi OS"
    fi
    
    # Verificar Python 3.8+
    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null; then
        error "Se requiere Python 3.8 o superior"
        exit 1
    fi
    
    # Verificar git
    if ! command -v git &> /dev/null; then
        info "Instalando git..."
        sudo apt update
        sudo apt install -y git
    fi
    
    success "Sistema verificado"
}

# Instalar dependencias del sistema
install_system_dependencies() {
    info "Instalando dependencias del sistema..."
    
    sudo apt update
    sudo apt install -y \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        cmake \
        pkg-config \
        libjpeg-dev \
        libtiff5-dev \
        libpng-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libv4l-dev \
        libxvidcore-dev \
        libx264-dev \
        libfontconfig1-dev \
        libcairo2-dev \
        libgdk-pixbuf2.0-dev \
        libpango1.0-dev \
        libgtk2.0-dev \
        libgtk-3-dev \
        libatlas-base-dev \
        gfortran \
        libhdf5-dev \
        libhdf5-serial-dev \
        libhdf5-103 \
        libqt5gui5 \
        libqt5webkit5 \
        libqt5test5 \
        python3-pyqt5
    
    success "Dependencias del sistema instaladas"
}

# Habilitar cámara
enable_camera() {
    info "Configurando cámara..."
    
    # Verificar si la cámara está habilitada
    if ! grep -q "^camera_auto_detect=1" /boot/config.txt; then
        info "Habilitando cámara en /boot/config.txt..."
        echo "camera_auto_detect=1" | sudo tee -a /boot/config.txt
        warn "Se requiere reiniciar para habilitar la cámara"
    fi
    
    # Configurar permisos para video
    sudo usermod -a -G video $USER
    
    success "Cámara configurada"
}

# Configurar UART
configure_uart() {
    info "Configurando UART..."
    
    # Habilitar UART en config.txt
    if ! grep -q "^enable_uart=1" /boot/config.txt; then
        echo "enable_uart=1" | sudo tee -a /boot/config.txt
        warn "Se requiere reiniciar para habilitar UART"
    fi
    
    # Deshabilitar serial console si está habilitado
    if grep -q "console=serial0" /boot/cmdline.txt; then
        info "Deshabilitando console serial en UART..."
        sudo sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
    fi
    
    # Añadir usuario a grupo dialout para acceso serial
    sudo usermod -a -G dialout $USER
    
    success "UART configurado"
}

# Clonar e instalar proyecto
install_project() {
    info "Instalando proyecto FotoUART..."
    
    # Clonar repositorio
    if [[ -d "$INSTALL_DIR" ]]; then
        warn "Directorio $INSTALL_DIR existe, actualizando..."
        cd "$INSTALL_DIR"
        git fetch origin
        git reset --hard "origin/$BRANCH"
    else
        git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    # Crear virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Actualizar pip
    pip install --upgrade pip
    
    # Instalar dependencias
    pip install -r requirements.txt
    
    # Crear configuración desde ejemplo
    if [[ ! -f "config/raspberry_pi/config.json" ]]; then
        cp "config/raspberry_pi/config.example.json" "config/raspberry_pi/config.json"
        info "Configuración creada desde ejemplo"
    fi
    
    # Crear directorios de datos
    mkdir -p data/{images/raw,images/processed,logs}
    
    success "Proyecto instalado en $INSTALL_DIR"
}

# Configurar auto-actualización
setup_auto_update() {
    if [[ "$SETUP_AUTO_UPDATE" != true ]]; then
        return 0
    fi
    
    info "Configurando auto-actualización..."
    
    cd "$INSTALL_DIR"
    
    # Hacer ejecutable el script de actualización
    chmod +x scripts/setup/auto_update.sh
    
    # Crear enlace simbólico en PATH local
    mkdir -p "$HOME/.local/bin"
    ln -sf "$INSTALL_DIR/scripts/setup/auto_update.sh" "$HOME/.local/bin/foto-uart-update"
    
    # Configurar cron para verificación periódica
    (crontab -l 2>/dev/null; echo "0 */6 * * * $HOME/.local/bin/foto-uart-update --check") | crontab -
    
    success "Auto-actualización configurada (cada 6 horas)"
}

# Configurar servicio systemd
setup_systemd_service() {
    if [[ "$SETUP_SERVICE" != true ]]; then
        return 0
    fi
    
    info "Configurando servicio systemd..."
    
    cd "$INSTALL_DIR"
    
    # Crear archivo de servicio
    sudo tee /etc/systemd/system/foto-uart.service > /dev/null << EOF
[Unit]
Description=FotoUART Drop-in Service
Documentation=https://github.com/cpatagon/foto-uart-dropin
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/python -m src.raspberry_pi.foto_uart_with_auto_update
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Seguridad
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=$INSTALL_DIR /var/log
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

    # Configurar servicio de actualización si auto-update está habilitado
    if [[ "$SETUP_AUTO_UPDATE" == true ]]; then
        sudo cp scripts/setup/foto-uart-updater.service /etc/systemd/system/
        sudo cp scripts/setup/foto-uart-updater.timer /etc/systemd/system/
        
        # Personalizar paths en los archivos de servicio
        sudo sed -i "s|/home/pi|$HOME|g" /etc/systemd/system/foto-uart-updater.service
        sudo sed -i "s|User=pi|User=$USER|g" /etc/systemd/system/foto-uart-updater.service
        sudo sed -i "s|Group=pi|Group=$USER|g" /etc/systemd/system/foto-uart-updater.service
    fi
    
    # Recargar systemd y habilitar servicios
    sudo systemctl daemon-reload
    sudo systemctl enable foto-uart.service
    
    if [[ "$SETUP_AUTO_UPDATE" == true ]]; then
        sudo systemctl enable foto-uart-updater.timer
        sudo systemctl start foto-uart-updater.timer
    fi
    
    success "Servicio systemd configurado"
    info "Comandos útiles:"
    info "  sudo systemctl start foto-uart.service    # Iniciar servicio"
    info "  sudo systemctl status foto-uart.service   # Ver estado"
    info "  sudo journalctl -u foto-uart.service -f   # Ver logs en tiempo real"
}

# Crear scripts de conveniencia
create_convenience_scripts() {
    info "Creando scripts de conveniencia..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Script para ejecutar foto-uart
    cat > "$HOME/.local/bin/foto-uart" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
python -m src.raspberry_pi.foto_uart "\$@"
EOF
    
    # Script con auto-update
    cat > "$HOME/.local/bin/foto-uart-auto" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
python -m src.raspberry_pi.foto_uart_with_auto_update "\$@"
EOF
    
    # Script de test
    cat > "$HOME/.local/bin/foto-uart-test" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
source venv/bin/activate
python -c "from src.raspberry_pi.foto_uart import FotoUART; print('✅ FotoUART OK')"
EOF
    
    chmod +x "$HOME/.local/bin/foto-uart"*
    
    # Agregar ~/.local/bin al PATH si no está
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        info "Agregado $HOME/.local/bin al PATH en .bashrc"
    fi
    
    success "Scripts de conveniencia creados"
    info "Comandos disponibles:"
    info "  foto-uart       # Ejecutar FotoUART básico"
    info "  foto-uart-auto  # Ejecutar con auto-actualización"
    info "  foto-uart-test  # Verificar instalación"
}

# Verificar instalación
verify_installation() {
    info "Verificando instalación..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # Verificar imports
    if python -c "from src.raspberry_pi.foto_uart import FotoUART; print('✅ FotoUART import OK')"; then
        success "Verificación de imports exitosa"
    else
        error "Error en imports de FotoUART"
        return 1
    fi
    
    # Verificar configuración
    if python -c "import json; json.load(open('config/raspberry_pi/config.json')); print('✅ Config JSON OK')"; then
        success "Configuración JSON válida"
    else
        error "Configuración JSON inválida"
        return 1
    fi
    
    # Verificar permisos de archivos
    if [[ -r "/dev/ttyAMA0" ]]; then
        success "Acceso a UART OK"
    else
        warn "No se puede acceder a /dev/ttyAMA0 (normal si no hay dispositivo conectado)"
    fi
    
    success "Instalación verificada"
}

# Mostrar información post-instalación
show_post_install_info() {
    info "=== Instalación Completada ==="
    echo
    success "FotoUART Drop-in instalado correctamente en: $INSTALL_DIR"
    echo
    
    if [[ "$SETUP_SERVICE" == true ]]; then
        info "📋 Servicio systemd configurado:"
        info "   sudo systemctl start foto-uart.service    # Iniciar"
        info "   sudo systemctl status foto-uart.service   # Estado"
        info "   sudo journalctl -u foto-uart.service -f   # Logs"
        echo
    fi
    
    if [[ "$SETUP_AUTO_UPDATE" == true ]]; then
        info "🔄 Auto-actualización configurada:"
        info "   foto-uart-update --check                  # Verificar updates"
        info "   foto-uart-update                          # Actualizar ahora"
        echo
    fi
    
    info "🚀 Comandos rápidos:"
    info "   foto-uart-test                            # Verificar instalación"
    info "   foto-uart                                 # Ejecutar FotoUART"
    info "   foto-uart-auto                            # Con auto-actualización"
    echo
    
    info "📁 Archivos importantes:"
    info "   Config: $INSTALL_DIR/config/raspberry_pi/config.json"
    info "   Logs:   $INSTALL_DIR/data/logs/"
    info "   Images: $INSTALL_DIR/data/images/"
    echo
    
    info "📖 Próximos pasos:"
    info "   1. Editar configuración: nano $INSTALL_DIR/config/raspberry_pi/config.json"
    info "   2. Conectar ESP32 a GPIO 14(TX)/15(RX)"
    info "   3. Probar: foto-uart-test"
    info "   4. Ejecutar: foto-uart-auto"
    echo
    
    if grep -q "Se requiere reiniciar" /tmp/install.log 2>/dev/null || [[ ! -r "/dev/ttyAMA0" ]]; then
        warn "⚠️  REINICIO REQUERIDO para activar cámara y UART"
        warn "   Ejecutar: sudo reboot"
    fi
    
    success "🎉 Instalación completada exitosamente!"
}

# Función principal
main() {
    info "=== Instalador FotoUART Drop-in para Raspberry Pi ==="
    echo
    
    # Crear log temporal
    exec > >(tee /tmp/install.log)
    exec 2>&1
    
    check_system
    install_system_dependencies
    enable_camera
    configure_uart
    install_project
    setup_auto_update
    setup_systemd_service
    create_convenience_scripts
    verify_installation
    show_post_install_info
}

# Manejo de errores
trap 'error "Error durante la instalación en línea $LINENO"' ERR

# Ejecutar instalación
main "$@"
