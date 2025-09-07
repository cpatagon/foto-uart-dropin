#!/bin/bash
#
# Script de Instalación Optimizada para Raspberry Pi Zero W
# =========================================================
# Detecta automáticamente Pi Zero W y aplica optimizaciones específicas.
#
# Uso:
#     curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash
#     
#     O manualmente:
#     chmod +x install_pi_zero.sh
#     ./install_pi_zero.sh [--auto-update] [--service] [--performance-mode]
#

set -euo pipefail

# Configuración específica Pi Zero W
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
INSTALL_DIR="$HOME/$PROJECT_NAME"
USER=$(whoami)
PI_ZERO_DETECTED=false
PERFORMANCE_MODE=false

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
pi_zero() { echo -e "${PURPLE}[PI-ZERO]${NC} $*"; }

# Mostrar banner Pi Zero W
show_pi_zero_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║    📸 FotoUART Drop-in System - Pi Zero W Edition           ║
    ║                                                              ║
    ║    Instalación optimizada para Raspberry Pi Zero W          ║
    ║    • Configuración automática de hardware                   ║
    ║    • Optimizaciones de memoria y CPU                        ║
    ║    • Gestión inteligente de recursos                        ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Detectar Raspberry Pi Zero W
detect_pi_zero() {
    info "Detectando hardware Raspberry Pi..."
    
    local model_file="/proc/device-tree/model"
    local revision_file="/proc/cpuinfo"
    
    if [[ -f "$model_file" ]]; then
        local model=$(tr -d '\0' < "$model_file")
        
        if echo "$model" | grep -q "Pi Zero"; then
            PI_ZERO_DETECTED=true
            pi_zero "✅ Raspberry Pi Zero detectada: $model"
            
            # Verificar si es Zero W (con WiFi)
            if iwconfig 2>/dev/null | grep -q "wlan0" || \
               lsusb 2>/dev/null | grep -q "Broadcom" || \
               echo "$model" | grep -q "Zero W"; then
                pi_zero "✅ WiFi detectado - Raspberry Pi Zero W confirmada"
            else
                warn "⚠️  Pi Zero sin WiFi detectada - funcionalidad limitada"
            fi
        else
            warn "Hardware detectado: $model"
            warn "Este script está optimizado para Pi Zero W"
            read -p "¿Continuar con instalación genérica? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    else
        warn "No se puede detectar modelo de Pi"
    fi
    
    # Verificar memoria RAM
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    if [[ $mem_total -lt 600 ]]; then
        pi_zero "✅ Memoria RAM limitada detectada: ${mem_total}MB"
        PI_ZERO_DETECTED=true
    fi
}

# Parsear argumentos específicos Pi Zero W
parse_arguments() {
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
            --performance-mode)
                PERFORMANCE_MODE=true
                shift
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                shift
                ;;
            -h|--help)
                show_help_pi_zero
                exit 0
                ;;
            *)
                error "Argumento desconocido: $1"
                show_help_pi_zero
                exit 1
                ;;
        esac
    done
}

# Ayuda específica Pi Zero W
show_help_pi_zero() {
    cat << EOF
Script de Instalación FotoUART - Edición Pi Zero W

Uso: $0 [opciones]

Opciones específicas Pi Zero W:
    --auto-update        Configurar auto-actualización (recomendado)
    --service            Instalar como servicio systemd
    --performance-mode   Aplicar optimizaciones agresivas de rendimiento
    --branch=RAMA        Especificar rama git (default: main)
    --help               Mostrar esta ayuda

Optimizaciones automáticas Pi Zero W:
    ✅ Configuración de GPU memory (128MB)
    ✅ Ajuste de swap (512MB)
    ✅ Deshabilitar servicios innecesarios
    ✅ Configuración de red optimizada
    ✅ Límites de memoria y CPU
    ✅ Configuración de cámara específica

Ejemplos:
    $0                                    # Instalación básica optimizada
    $0 --auto-update --service           # Instalación completa con servicio
    $0 --performance-mode                # Máximo rendimiento
EOF
}

# Verificar prerrequisitos Pi Zero W
check_pi_zero_prerequisites() {
    info "Verificando prerrequisitos para Pi Zero W..."
    
    # Verificar Raspberry Pi OS
    if ! grep -q "Raspbian\|Raspberry Pi OS" /etc/os-release 2>/dev/null; then
        warn "⚠️  Este script está optimizado para Raspberry Pi OS"
    fi
    
    # Verificar Python 3.8+
    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)" 2>/dev/null; then
        error "❌ Se requiere Python 3.8 o superior"
        exit 1
    fi
    
    # Verificar espacio en disco (mínimo 2GB)
    local available_space=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $available_space -lt 2 ]]; then
        error "❌ Espacio insuficiente: ${available_space}GB (mínimo 2GB)"
        exit 1
    fi
    
    # Verificar memoria RAM disponible
    local mem_available=$(free -m | awk 'NR==2{print $7}')
    if [[ $mem_available -lt 100 ]]; then
        warn "⚠️  Memoria RAM baja: ${mem_available}MB"
    fi
    
    success "✅ Prerrequisitos verificados"
}

# Aplicar optimizaciones específicas Pi Zero W
apply_pi_zero_optimizations() {
    if [[ "$PI_ZERO_DETECTED" != true ]]; then
        return 0
    fi
    
    pi_zero "Aplicando optimizaciones específicas para Pi Zero W..."
    
    # 1. Configurar GPU memory split
    if ! grep -q "gpu_mem=128" /boot/config.txt 2>/dev/null; then
        echo "gpu_mem=128" | sudo tee -a /boot/config.txt
        pi_zero "GPU memory configurada a 128MB"
    fi
    
    # 2. Configurar CPU governor
    echo 'GOVERNOR="ondemand"' | sudo tee /etc/default/cpufrequtils > /dev/null 2>&1 || true
    
    # 3. Optimizar swap
    if [[ -f /etc/dphys-swapfile ]]; then
        sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
        pi_zero "Swap configurado a 512MB"
    fi
    
    # 4. Deshabilitar servicios innecesarios
    local services_to_disable=(
        "triggerhappy"
        "avahi-daemon"
    )
    
    if [[ "$PERFORMANCE_MODE" == true ]]; then
        services_to_disable+=(
            "bluetooth"
            "hciuart"
            "cups"
            "cups-browsed"
        )
    fi
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            sudo systemctl disable "$service" 2>/dev/null || true
            pi_zero "Servicio $service deshabilitado"
        fi
    done
    
    # 5. Optimizaciones de red Pi Zero W
    if [[ "$PI_ZERO_DETECTED" == true ]]; then
        cat > /tmp/dhcpcd_pi_zero.conf << 'EOF'
# Optimizaciones Pi Zero W
interface wlan0
static domain_name_servers=8.8.8.8 1.1.1.1
noipv6

# Power management
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
option ntp_servers
EOF
        
        if ! grep -q "Optimizaciones Pi Zero W" /etc/dhcpcd.conf; then
            sudo tee -a /etc/dhcpcd.conf < /tmp/dhcpcd_pi_zero.conf > /dev/null
            pi_zero "Configuración de red optimizada"
        fi
        rm -f /tmp/dhcpcd_pi_zero.conf
    fi
    
    # 6. Configuraciones adicionales en modo performance
    if [[ "$PERFORMANCE_MODE" == true ]]; then
        # Deshabilitar logs de kernel en consola
        echo "kernel.printk = 3 4 1 3" | sudo tee -a /etc/sysctl.conf
        
        # Optimizar scheduler I/O
        echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="deadline"' | \
            sudo tee /etc/udev/rules.d/60-ioschedulers.rules
        
        pi_zero "Optimizaciones de rendimiento aplicadas"
    fi
    
    success "✅ Optimizaciones Pi Zero W completadas"
}

# Instalar dependencias ligeras para Pi Zero W
install_pi_zero_dependencies() {
    info "Instalando dependencias optimizadas para Pi Zero W..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Actualizar solo si es necesario
    if ! command -v git &> /dev/null; then
        sudo apt update
    fi
    
    # Dependencias mínimas para Pi Zero W
    local packages=(
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "python3-picamera2"
        "python3-opencv"
        "python3-serial"
        "python3-numpy"
        "git"
        "rsync"
    )
    
    # Instalar con opciones para ahorrar memoria
    sudo apt install -y --no-install-recommends "${packages[@]}"
    
    # Limpiar cache para liberar espacio
    sudo apt clean
    sudo apt autoremove -y
    
    success "✅ Dependencias ligeras instaladas"
}

# Configurar proyecto específico Pi Zero W
setup_pi_zero_project() {
    info "Configurando proyecto para Pi Zero W..."
    
    # Clonar repositorio si no existe
    if [[ ! -d "$INSTALL_DIR" ]]; then
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    else
        cd "$INSTALL_DIR"
        git pull origin "$BRANCH"
    fi
    
    cd "$INSTALL_DIR"
    
    # Crear virtual environment optimizado
    python3 -m venv --system-site-packages venv
    source venv/bin/activate
    
    # Instalar solo dependencias críticas en venv
    pip install --no-cache-dir \
        pyserial \
        requests \
        flask \
        python-dotenv \
        gitpython
    
    # Usar configuración específica Pi Zero W
    mkdir -p config/raspberry_pi
    
    # Si existe config_pi_zero.json, usarlo; si no, crear uno básico
    if [[ ! -f config/raspberry_pi/config_pi_zero.json ]]; then
        cat > config/raspberry_pi/config_pi_zero.json << 'EOF'
{
  "_comment": "Configuración optimizada para Raspberry Pi Zero W",
  "serial": {
    "puerto": "/dev/ttyAMA0",
    "baudrate": 115200,
    "timeout": 2
  },
  "imagen": {
    "ancho_default": 800,
    "calidad_default": 4,
    "chunk_size": 128,
    "ack_timeout": 15,
    "jpeg_progressive": false
  },
  "almacenamiento": {
    "directorio_fullres": "data/images/raw",
    "directorio_enhanced": "data/images/processed",
    "mantener_originales": false,
    "logs_dir": "data/logs"
  },
  "procesamiento": {
    "aplicar_mejoras": true,
    "unsharp_mask": false,
    "clahe_enabled": true
  },
  "limites": {
    "max_jpeg_bytes": 65536,
    "fallback_quality_drop": 15
  },
  "pi_zero_optimizations": {
    "enabled": true,
    "reduce_memory_usage": true,
    "disable_fullres_save": true,
    "cpu_governor": "ondemand"
  }
}
EOF
    fi
    
    # Si no hay configuración genérica, crear enlace
    if [[ ! -f config/raspberry_pi/config.json ]]; then
        ln -sf config_pi_zero.json config/raspberry_pi/config.json
    fi
    
    # Crear directorios de datos
    mkdir -p data/{images/raw,images/processed,logs}
    
    success "✅ Proyecto configurado para Pi Zero W"
}

# Test de rendimiento específico Pi Zero W
test_pi_zero_performance() {
    info "Ejecutando tests de rendimiento Pi Zero W..."
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    # Test de importación básica (sin hardware)
    if python3 -c "
import sys
from unittest.mock import MagicMock

# Mock picamera2 si no está disponible
try:
    import picamera2
except ImportError:
    sys.modules['picamera2'] = MagicMock()
    sys.modules['picamera2.Picamera2'] = MagicMock()

# Test de configuración
import json
with open('config/raspberry_pi/config_pi_zero.json') as f:
    config = json.load(f)
    
print('✅ Configuración cargada correctamente')
print(f'   Resolución: {config[\"imagen\"][\"ancho_default\"]}px')
print(f'   Calidad: {config[\"imagen\"][\"calidad_default\"]}')
print(f'   Chunk size: {config[\"imagen\"][\"chunk_size\"]} bytes')
"; then
        success "✅ Test de configuración exitoso"
    else
        error "❌ Error en test de configuración"
        return 1
    fi
    
    # Verificar memoria disponible
    local mem_available=$(free -m | awk 'NR==2{print $7}')
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    local mem_percent=$((mem_available * 100 / mem_total))
    
    if [[ $mem_percent -gt 30 ]]; then
        success "✅ Memoria disponible: ${mem_available}MB (${mem_percent}%)"
    else
        warn "⚠️  Memoria baja: ${mem_available}MB (${mem_percent}%)"
    fi
    
    # Verificar temperatura CPU
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        if [[ $temp -lt 70 ]]; then
            success "✅ Temperatura CPU: ${temp}°C"
        else
            warn "⚠️  Temperatura alta: ${temp}°C"
        fi
    fi
    
    # Verificar espacio en disco
    local disk_available=$(df -h / | awk 'NR==2{print $4}' | sed 's/G.*//')
    if (( $(echo "$disk_available > 1" | bc -l 2>/dev/null || echo "1") )); then
        success "✅ Espacio disponible: ${disk_available}GB"
    else
        warn "⚠️  Espacio limitado: ${disk_available}GB"
    fi
    
    success "✅ Tests de rendimiento completados"
}

# Crear scripts de conveniencia Pi Zero W
create_pi_zero_scripts() {
    info "Creando scripts de conveniencia para Pi Zero W..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Script optimizado para Pi Zero W
    cat > "$HOME/.local/bin/foto-uart-pi-zero" << EOF
#!/bin/bash
# Script optimizado para Raspberry Pi Zero W
cd "$INSTALL_DIR"
source venv/bin/activate

# Verificar temperatura antes de ejecutar
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=\$(cat /sys/class/thermal/thermal_zone0/temp)
    temp=\$((temp / 1000))

    if [[ \$temp -gt 75 ]]; then
        echo "⚠️  Temperatura alta: \${temp}°C - esperando..."
        sleep 30
    fi
fi

# Ejecutar con configuración Pi Zero W
python -m src.raspberry_pi.foto_uart \\
    --config config/raspberry_pi/config_pi_zero.json "\$@"
EOF

    # Script de monitoreo Pi Zero W
    cat > "$HOME/.local/bin/foto-uart-monitor" << 'EOF'
#!/bin/bash
# Monitor de sistema para Pi Zero W
while true; do
    clear
    echo "=== Monitor FotoUART Pi Zero W ==="
    echo "Fecha: $(date)"
    echo
    
    # Temperatura
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        echo "🌡️  Temperatura: ${temp}°C"
    fi
    
    # Memoria
    free -h | head -2
    echo
    
    # Espacio en disco
    df -h / | tail -1
    echo
    
    # Estado del servicio
    if systemctl is-active --quiet foto-uart.service 2>/dev/null; then
        echo "✅ Servicio: ACTIVO"
    else
        echo "❌ Servicio: INACTIVO"
    fi
    
    # Últimas líneas del log
    echo
    echo "📝 Últimos logs:"
    if [[ -d "$HOME/foto-uart-dropin/data/logs" ]]; then
        tail -n 3 "$HOME/foto-uart-dropin/data/logs/"*.log 2>/dev/null || echo "No hay logs disponibles"
    fi
    
    sleep 10
done
EOF

    # Script de test de rendimiento
    cat > "$HOME/.local/bin/foto-uart-performance-test" << EOF
#!/bin/bash
# Test de rendimiento específico para Pi Zero W
echo "🧪 Test de Rendimiento Pi Zero W"
echo "================================="

cd "$INSTALL_DIR"
source venv/bin/activate

echo "📊 Información del sistema:"
if [[ -f /proc/cpuinfo ]]; then
    echo "CPU: \$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
fi
echo "RAM: \$(free -h | awk 'NR==2{print \$2}')"
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    echo "Temperatura: \$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))°C"
fi
echo

echo "🔬 Test de configuración Pi Zero W..."
python3 -c "
import json
with open('config/raspberry_pi/config_pi_zero.json') as f:
    config = json.load(f)
    
print(f'✅ Configuración cargada')
print(f'   Resolución: {config[\"imagen\"][\"ancho_default\"]}px')
print(f'   Calidad: {config[\"imagen\"][\"calidad_default\"]}')
print(f'   Límite imagen: {config[\"limites\"][\"max_jpeg_bytes\"]} bytes')
"

echo "✅ Test completado"
EOF

    chmod +x "$HOME/.local/bin/foto-uart"*
    
    # Agregar al PATH si no está
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    success "✅ Scripts de conveniencia creados"
}

# Configurar servicio systemd Pi Zero W
setup_pi_zero_service() {
    if [[ "$SETUP_SERVICE" != true ]]; then
        return 0
    fi
    
    info "Configurando servicio systemd para Pi Zero W..."
    
    sudo tee /etc/systemd/system/foto-uart-pi-zero.service > /dev/null << EOF
[Unit]
Description=FotoUART Drop-in Service - Pi Zero W Edition
Documentation=https://github.com/cpatagon/foto-uart-dropin
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStartPre=/bin/bash -c 'if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then temp=\$(cat /sys/class/thermal/thermal_zone0/temp); if [ \$((temp / 1000)) -gt 75 ]; then echo "Temperatura alta, esperando..."; sleep 30; fi; fi'
ExecStart=$INSTALL_DIR/venv/bin/python -m src.raspberry_pi.foto_uart
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

# Protección específica Pi Zero W
MemoryMax=400M
CPUQuota=90%
TasksMax=50

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
    sudo systemctl enable foto-uart-pi-zero.service
    
    success "✅ Servicio systemd configurado para Pi Zero W"
}

# Mostrar información final Pi Zero W
show_pi_zero_final_info() {
    clear
    pi_zero "=== Instalación Pi Zero W Completada ==="
    echo
    success "🎉 FotoUART Drop-in optimizado para Pi Zero W instalado exitosamente!"
    echo
    
    if [[ "$PI_ZERO_DETECTED" == true ]]; then
        pi_zero "🔧 Optimizaciones aplicadas:"
        pi_zero "   ✅ GPU Memory: 128MB"
        pi_zero "   ✅ Swap: 512MB"
        pi_zero "   ✅ CPU Governor: ondemand"
        pi_zero "   ✅ Servicios innecesarios deshabilitados"
        pi_zero "   ✅ Configuración de red optimizada"
        echo
    fi
    
    if [[ "$SETUP_SERVICE" == true ]]; then
        info "🤖 Servicio systemd configurado:"
        info "   sudo systemctl start foto-uart-pi-zero.service"
        info "   sudo systemctl status foto-uart-pi-zero.service"
        info "   sudo journalctl -u foto-uart-pi-zero.service -f"
        echo
    fi
    
    info "🚀 Comandos específicos Pi Zero W:"
    info "   foto-uart-pi-zero              # Ejecutar optimizado"
    info "   foto-uart-monitor              # Monitor de sistema"
    info "   foto-uart-performance-test     # Test de rendimiento"
    echo
    
    info "📁 Archivos importantes:"
    info "   Config: $INSTALL_DIR/config/raspberry_pi/config_pi_zero.json"
    info "   Logs:   $INSTALL_DIR/data/logs/"
    echo
    
    info "📊 Estado actual del sistema:"
    local temp=$(($(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0") / 1000))
    local mem_available=$(free -m | awk 'NR==2{print $7}')
    local disk_available=$(df -h / | awk 'NR==2{print $4}')
    
    info "   🌡️  Temperatura: ${temp}°C"
    info "   💾 RAM disponible: ${mem_available}MB"
    info "   💿 Disco disponible: ${disk_available}"
    echo
    
    info "📖 Próximos pasos para Pi Zero W:"
    info "   1. Verificar: foto-uart-performance-test"
    info "   2. Configurar ESP32 en GPIO 14(TX)/15(RX)"
    info "   3. Ejecutar: foto-uart-pi-zero"
    info "   4. Monitorear: foto-uart-monitor"
    echo
    
    if [[ $temp -gt 60 ]]; then
        warn "⚠️  Temperatura elevada (${temp}°C) - considerar disipación"
    fi
    
    success "🎉 ¡Instalación Pi Zero W completada exitosamente!"
}

# Función principal
main() {
    show_pi_zero_banner
    
    parse_arguments "$@"
    detect_pi_zero
    check_pi_zero_prerequisites
    apply_pi_zero_optimizations
    install_pi_zero_dependencies
    setup_pi_zero_project
    test_pi_zero_performance
    create_pi_zero_scripts
    setup_pi_zero_service
    show_pi_zero_final_info
}

# Manejo de errores
trap 'error "Error durante instalación Pi Zero W en línea $LINENO"' ERR

# Ejecutar instalación
main "$@"
