#!/bin/bash
#
# Script de Instalación para Raspberry Pi 3B+ Commander
# =====================================================
# Instala foto-uart-dropin optimizado para Pi 3B+ como commander/storage
#
# Uso:
#     curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b.sh | bash
#     
#     O manualmente:
#     chmod +x install_pi3b.sh
#     ./install_pi3b.sh [--auto-start] [--web-gallery] [--backup-usb]
#

set -euo pipefail

# Configuración
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
INSTALL_DIR="$HOME/$PROJECT_NAME"
USER=$(whoami)
PI3B_DETECTED=false

# Opciones de instalación
SETUP_AUTO_START=false
SETUP_WEB_GALLERY=false
SETUP_USB_BACKUP=false
BRANCH="main"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Funciones de utilidad
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
pi3b() { echo -e "${PURPLE}[PI3B+]${NC} $*"; }

# Banner Pi 3B+
show_pi3b_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║    📡 FotoUART Pi 3B+ Commander + Storage                   ║
    ║                                                              ║
    ║    • Controla Pi Zero W via UART                            ║
    ║    • Almacenamiento local de imágenes                       ║
    ║    • Web gallery opcional                                   ║
    ║    • Auto-backup a USB                                      ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Detectar Pi 3B+
detect_pi3b() {
    info "Detectando hardware Raspberry Pi..."
    
    local model_file="/proc/device-tree/model"
    
    if [[ -f "$model_file" ]]; then
        local model=$(tr -d '\0' < "$model_file")
        
        if echo "$model" | grep -q "Pi 3"; then
            PI3B_DETECTED=true
            pi3b "✅ Raspberry Pi 3B+ detectada: $model"
        else
            warn "Hardware detectado: $model"
            warn "Este script está optimizado para Pi 3B+"
            read -p "¿Continuar con instalación? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    else
        warn "No se puede detectar modelo de Pi"
    fi
    
    # Verificar memoria RAM (Pi 3B+ tiene 1GB)
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    if [[ $mem_total -gt 900 ]]; then
        pi3b "✅ Memoria RAM adecuada: ${mem_total}MB"
        PI3B_DETECTED=true
    fi
}

# Parsear argumentos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-start)
                SETUP_AUTO_START=true
                shift
                ;;
            --web-gallery)
                SETUP_WEB_GALLERY=true
                shift
                ;;
            --backup-usb)
                SETUP_USB_BACKUP=true
                shift
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                shift
                ;;
            -h|--help)
                show_help_pi3b
                exit 0
                ;;
            *)
                error "Argumento desconocido: $1"
                show_help_pi3b
                exit 1
                ;;
        esac
    done
}

# Ayuda
show_help_pi3b() {
    cat << EOF
Script de Instalación FotoUART - Pi 3B+ Commander

Uso: $0 [opciones]

Opciones Pi 3B+ Commander:
    --auto-start         Iniciar automáticamente al boot
    --web-gallery        Habilitar galería web en puerto 8080
    --backup-usb         Configurar backup automático a USB
    --branch=RAMA        Especificar rama git (default: main)
    --help               Mostrar esta ayuda

Características Pi 3B+:
    ✅ Commander UART para Pi Zero W
    ✅ Almacenamiento local robusto
    ✅ Web gallery opcional
    ✅ Backup automático a USB
    ✅ Monitoreo y estadísticas
    ✅ API REST para integración

Ejemplos:
    $0                                    # Instalación básica
    $0 --web-gallery --auto-start        # Con web y auto-inicio
    $0 --backup-usb                      # Con backup USB
EOF
}

# Verificar prerrequisitos Pi 3B+
check_pi3b_prerequisites() {
    info "Verificando prerrequisitos para Pi 3B+ Commander..."
    
    # Verificar OS
    if ! grep -q "Raspbian\|Raspberry Pi OS" /etc/os-release 2>/dev/null; then
        warn "⚠️  Este script está optimizado para Raspberry Pi OS"
    fi
    
    # Verificar Python 3.8+
    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null; then
        error "❌ Se requiere Python 3.8 o superior"
        exit 1
    fi
    
    # Verificar espacio en disco (mínimo 5GB para almacenamiento)
    local available_space=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $available_space -lt 5 ]]; then
        error "❌ Espacio insuficiente: ${available_space}GB (mínimo 5GB para storage)"
        exit 1
    fi
    
    # Verificar memoria RAM disponible
    local mem_available=$(free -m | awk 'NR==2{print $7}')
    if [[ $mem_available -lt 200 ]]; then
        warn "⚠️  Memoria RAM baja: ${mem_available}MB"
    fi
    
    success "✅ Prerrequisitos Pi 3B+ verificados"
}

# Configurar UART para Pi 3B+
configure_pi3b_uart() {
    if [[ "$PI3B_DETECTED" != true ]]; then
        return 0
    fi
    
    pi3b "Configurando UART para Pi 3B+ Commander..."
    
    # Habilitar UART
    if ! grep -q "enable_uart=1" /boot/config.txt 2>/dev/null; then
        echo "enable_uart=1" | sudo tee -a /boot/config.txt
        pi3b "UART habilitado en config.txt"
    fi
    
    # Deshabilitar console serial
    if grep -q "console=serial0" /boot/cmdline.txt 2>/dev/null; then
        sudo sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
        pi3b "Console serial deshabilitado"
    fi
    
    # Deshabilitar servicios que interfieren
    sudo systemctl disable serial-getty@ttyS0.service 2>/dev/null || true
    sudo systemctl mask serial-getty@ttyS0.service 2>/dev/null || true
    
    # Permisos UART
    sudo usermod -a -G dialout,tty,gpio $USER
    
    success "✅ UART Pi 3B+ configurado correctamente"
}

# Instalar dependencias Pi 3B+
install_pi3b_dependencies() {
    info "Instalando dependencias para Pi 3B+ Commander..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    sudo apt update
    
    # Dependencias para Pi 3B+ Commander
    local packages=(
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "python3-serial"
        "python3-flask"
        "git"
        "rsync"
        "curl"
        "jq"
        "htop"
        "tree"
    )
    
    # Si web gallery habilitada, instalar nginx
    if [[ "$SETUP_WEB_GALLERY" == true ]]; then
        packages+=("nginx")
    fi
    
    # Instalar paquetes
    sudo apt install -y "${packages[@]}"
    
    # Limpiar cache
    sudo apt clean
    sudo apt autoremove -y
    
    success "✅ Dependencias Pi 3B+ instaladas"
}

# Configurar proyecto Pi 3B+
setup_pi3b_project() {
    info "Configurando proyecto para Pi 3B+ Commander..."
    
    # Clonar repositorio
    if [[ ! -d "$INSTALL_DIR" ]]; then
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    else
        cd "$INSTALL_DIR"
        git pull origin "$BRANCH"
    fi
    
    cd "$INSTALL_DIR"
    
    # Crear virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Instalar dependencias Python
    pip install --no-cache-dir \
        pyserial \
        requests \
        flask \
        pillow \
        python-dotenv \
        gitpython \
        psutil
    
    # Configuración específica Pi 3B+
    mkdir -p config/raspberry_pi
    mkdir -p data/{images/received,images/processed,images/backup,logs,temp}
    
    # Usar configuración Pi 3B+ si no existe
    if [[ ! -f config/raspberry_pi/config.json ]]; then
        if [[ -f config/raspberry_pi/config_pi3b.json ]]; then
            ln -sf config_pi3b.json config/raspberry_pi/config.json
        else
            # Crear configuración básica
            cp config/raspberry_pi/config.example.json config/raspberry_pi/config.json 2>/dev/null || true
        fi
    fi
    
    success "✅ Proyecto Pi 3B+ configurado"
}

# Configurar web gallery
setup_web_gallery() {
    if [[ "$SETUP_WEB_GALLERY" != true ]]; then
        return 0
    fi
    
    info "Configurando Web Gallery..."
    
    cd "$INSTALL_DIR"
    
    # Crear directorio web
    mkdir -p web/{static,templates}
    
    # Configurar nginx
    sudo tee /etc/nginx/sites-available/foto-uart-gallery > /dev/null << EOF
server {
    listen 8080;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /static/ {
        alias $INSTALL_DIR/web/static/;
    }
    
    location /images/ {
        alias $INSTALL_DIR/data/images/received/;
        autoindex on;
    }
}
EOF
    
    # Habilitar sitio
    sudo ln -sf /etc/nginx/sites-available/foto-uart-gallery /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Reiniciar nginx
    sudo systemctl reload nginx
    sudo systemctl enable nginx
    
    success "✅ Web Gallery configurada en puerto 8080"
}

# Configurar backup USB
setup_usb_backup() {
    if [[ "$SETUP_USB_BACKUP" != true ]]; then
        return 0
    fi
    
    info "Configurando backup automático a USB..."
    
    # Crear script de backup
    cat > "$INSTALL_DIR/scripts/backup_to_usb.sh" << 'EOF'
#!/bin/bash
# Backup automático a USB para Pi 3B+

BACKUP_SOURCE="$HOME/foto-uart-dropin/data/images/received"
USB_MOUNT="/media/usb"
LOG_FILE="$HOME/foto-uart-dropin/data/logs/usb_backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

# Buscar dispositivo USB
USB_DEVICE=$(lsblk -rpo NAME,TRAN | awk '$2=="usb"{print $1}' | head -1)

if [[ -z "$USB_DEVICE" ]]; then
    log "No se encontró dispositivo USB"
    exit 1
fi

# Montar USB si no está montado
if ! mountpoint -q "$USB_MOUNT"; then
    sudo mkdir -p "$USB_MOUNT"
    if sudo mount "$USB_DEVICE" "$USB_MOUNT"; then
        log "USB montado: $USB_DEVICE -> $USB_MOUNT"
    else
        log "Error montando USB: $USB_DEVICE"
        exit 1
    fi
fi

# Crear directorio backup
BACKUP_DIR="$USB_MOUNT/foto-uart-backup/$(date '+%Y-%m-%d')"
sudo mkdir -p "$BACKUP_DIR"

# Sincronizar archivos
if sudo rsync -av --progress "$BACKUP_SOURCE/" "$BACKUP_DIR/"; then
    log "Backup exitoso: $(ls -1 "$BACKUP_SOURCE" | wc -l) archivos"
else
    log "Error en backup"
    exit 1
fi

# Limpiar backups antiguos (mantener 7 días)
find "$USB_MOUNT/foto-uart-backup" -type d -name "20*" -mtime +7 -exec sudo rm -rf {} + 2>/dev/null || true

log "Backup completado"
EOF
    
    chmod +x "$INSTALL_DIR/scripts/backup_to_usb.sh"
    
    # Configurar cron para backup diario
    (crontab -l 2>/dev/null; echo "0 2 * * * $INSTALL_DIR/scripts/backup_to_usb.sh") | crontab -
    
    success "✅ Backup USB configurado (diario a las 2:00 AM)"
}

# Crear scripts de conveniencia Pi 3B+
create_pi3b_scripts() {
    info "Creando scripts de conveniencia para Pi 3B+..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Script commander
    cat > "$HOME/.local/bin/foto-uart-commander" << EOF
#!/bin/bash
# Pi 3B+ Commander script
cd "$INSTALL_DIR"
source venv/bin/activate
python src/raspberry_pi/pi3b_commander.py "\$@"
EOF
    
    # Script de monitoreo
    cat > "$HOME/.local/bin/foto-uart-monitor-pi3b" << EOF
#!/bin/bash
# Monitor Pi 3B+ Commander
while true; do
    clear
    echo "=== Monitor Pi 3B+ Commander ==="
    echo "Fecha: \$(date)"
    echo
    
    # Estado UART
    if [[ -c /dev/ttyS0 ]]; then
        echo "✅ UART: /dev/ttyS0 disponible"
    else
        echo "❌ UART: /dev/ttyS0 no disponible"
    fi
    
    # Espacio en disco
    echo
    echo "💾 Almacenamiento:"
    df -h "$INSTALL_DIR/data" | tail -1
    
    # Imágenes almacenadas
    if [[ -d "$INSTALL_DIR/data/images/received" ]]; then
        IMG_COUNT=\$(ls -1 "$INSTALL_DIR/data/images/received"/*.jpg 2>/dev/null | wc -l)
        echo "📷 Imágenes: \$IMG_COUNT"
    fi
    
    # Memoria y CPU
    echo
    echo "🖥️  Sistema:"
    echo "   RAM: \$(free -h | awk 'NR==2{print \$3"/"\$2}')"
    echo "   CPU: \$(top -bn1 | grep "Cpu(s)" | awk '{print \$2}' | cut -d'%' -f1)%"
    
    # Temperatura
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=\$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        echo "   Temp: \${temp}°C"
    fi
    
    sleep 10
done
EOF
    
    # Script de info rápida
    cat > "$HOME/.local/bin/foto-uart-info" << EOF
#!/bin/bash
# Info rápida del sistema
cd "$INSTALL_DIR"
source venv/bin/activate
python src/raspberry_pi/pi3b_commander.py --info
EOF
    
    chmod +x "$HOME/.local/bin/foto-uart"*
    
    # Agregar al PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    success "✅ Scripts de conveniencia creados"
}

# Configurar servicio systemd
setup_pi3b_service() {
    if [[ "$SETUP_AUTO_START" != true ]]; then
        return 0
    fi
    
    info "Configurando servicio systemd para Pi 3B+..."
    
    sudo tee /etc/systemd/system/foto-uart-pi3b-commander.service > /dev/null << EOF
[Unit]
Description=FotoUART Pi 3B+ Commander Service
Documentation=https://github.com/cpatagon/foto-uart-dropin
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/python src/raspberry_pi/pi3b_commander.py --continuous
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Límites de recursos
MemoryMax=800M
CPUQuota=80%

# Seguridad
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=$INSTALL_DIR /var/log
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable foto-uart-pi3b-commander.service
    
    success "✅ Servicio systemd configurado"
}

# Test del sistema Pi 3B+
test_pi3b_system() {
    info "Ejecutando tests del sistema Pi 3B+..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # Test de configuración
    echo "🔧 Test de configuración..."
    if python3 -c "
import json
with open('config/raspberry_pi/config.json') as f:
    config = json.load(f)
print('✅ Configuración cargada correctamente')
print(f'   Puerto UART: {config[\"serial\"][\"puerto\"]}')
print(f'   Baudrate: {config[\"serial\"][\"baudrate\"]}')
"; then
        success "✅ Configuración válida"
    else
        error "❌ Error en configuración"
        return 1
    fi
    
    # Test de UART
    echo "📡 Test de UART..."
    if python3 -c "
import serial
try:
    ser = serial.Serial('/dev/ttyS0', 115200, timeout=1)
    print('✅ Puerto UART accesible')
    ser.close()
except Exception as e:
    print(f'❌ Error UART: {e}')
    exit(1)
"; then
        success "✅ UART funcional"
    else
        error "❌ Problema con UART"
        return 1
    fi
    
    # Test de almacenamiento
    echo "💾 Test de almacenamiento..."
    local storage_dir="$INSTALL_DIR/data/images/received"
    if [[ -d "$storage_dir" ]] && [[ -w "$storage_dir" ]]; then
        success "✅ Almacenamiento accesible"
    else
        error "❌ Problema con almacenamiento"
        return 1
    fi
    
    success "✅ Todos los tests pasaron"
}

# Información final
show_pi3b_final_info() {
    clear
    pi3b "=== Instalación Pi 3B+ Commander Completada ==="
    echo
    success "🎉 FotoUART Pi 3B+ Commander instalado exitosamente!"
    echo
    
    if [[ "$PI3B_DETECTED" == true ]]; then
        pi3b "🔧 Optimizaciones Pi 3B+ aplicadas:"
        pi3b "   ✅ UART configurado en /dev/ttyS0"
        pi3b "   ✅ Almacenamiento en $INSTALL_DIR/data"
        pi3b "   ✅ Scripts de conveniencia instalados"
        echo
    fi
    
    if [[ "$SETUP_WEB_GALLERY" == true ]]; then
        info "🌐 Web Gallery habilitada:"
        info "   Acceder: http://$(hostname -I | awk '{print $1}'):8080"
        echo
    fi
    
    if [[ "$SETUP_AUTO_START" == true ]]; then
        info "🤖 Servicio automático configurado:"
        info "   sudo systemctl start foto-uart-pi3b-commander.service"
        info "   sudo systemctl status foto-uart-pi3b-commander.service"
        echo
    fi
    
    info "🚀 Comandos Pi 3B+ Commander:"
    info "   foto-uart-commander                   # Captura única"
    info "   foto-uart-commander --continuous      # Modo continuo"  
    info "   foto-uart-commander --info            # Info almacenamiento"
    info "   foto-uart-monitor-pi3b                # Monitor sistema"
    echo
    
    info "📁 Archivos importantes:"
    info "   Config: $INSTALL_DIR/config/raspberry_pi/config.json"
    info "   Imágenes: $INSTALL_DIR/data/images/received/"
    info "   Logs: $INSTALL_DIR/data/logs/"
    echo
    
    info "📖 Próximos pasos:"
    info "   1. Verificar: foto-uart-info"
    info "   2. Conectar Pi Zero W a GPIO 14/15"
    info "   3. En Pi Zero W: ejecutar foto_uart.py" 
    info "   4. En Pi 3B+: ejecutar foto-uart-commander"
    echo
    
    if [[ "$SETUP_USB_BACKUP" == true ]]; then
        info "💾 Backup USB configurado:"
        info "   Conectar USB y el backup será automático (2:00 AM)"
        echo
    fi
    
    success "🎉 ¡Sistema Pi 3B+ Commander listo para usar!"
}

# Función principal
main() {
    show_pi3b_banner
    
    parse_arguments "$@"
    detect_pi3b
    check_pi3b_prerequisites
    configure_pi3b_uart
    install_pi3b_dependencies
    setup_pi3b_project
    setup_web_gallery
    setup_usb_backup
    create_pi3b_scripts
    setup_pi3b_service
    test_pi3b_system
    show_pi3b_final_info
}

# Manejo de errores
trap 'error "Error durante instalación Pi 3B+ en línea $LINENO"' ERR

# Ejecutar instalación
main "$@"
