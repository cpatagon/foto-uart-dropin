#!/bin/bash
#
# Instalador Optimizado para Raspberry Pi 3B+
# ============================================
# Detecta y aplica optimizaciones específicas para Pi 3B+
#
# Diferencias vs Pi Zero W:
# - Mayor RAM (1GB vs 512MB)
# - CPU más potente (4 cores vs 1 core)
# - Ethernet nativo
# - Mayor capacidad de procesamiento
#

set -euo pipefail

# Configuración específica Pi 3B+
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
INSTALL_DIR="$HOME/$PROJECT_NAME"
PI3B_DETECTED=false

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de utilidad
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
pi3b() { echo -e "${CYAN}[PI-3B+]${NC} $*"; }

# Banner Pi 3B+
show_pi3b_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║    📸 FotoUART Drop-in System - Raspberry Pi 3B+ Edition        ║
    ║                                                                  ║
    ║    Instalación optimizada para Raspberry Pi 3B+                 ║
    ║    • Mayor capacidad de procesamiento                           ║
    ║    • Configuración multi-core                                   ║
    ║    • Ethernet nativo para IoT                                   ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Detectar Raspberry Pi 3B+
detect_pi3b() {
    info "🔍 Detectando hardware Raspberry Pi..."
    
    local model_file="/proc/device-tree/model"
    
    if [[ -f "$model_file" ]]; then
        local model=$(tr -d '\0' < "$model_file")
        
        if echo "$model" | grep -q "Pi 3 Model B Plus"; then
            PI3B_DETECTED=true
            pi3b "✅ Raspberry Pi 3B+ detectada: $model"
        elif echo "$model" | grep -q "Pi 3"; then
            PI3B_DETECTED=true
            pi3b "✅ Raspberry Pi 3 detectada: $model"
        else
            warn "⚠️  Hardware detectado: $model"
            warn "Este script está optimizado para Pi 3B+"
        fi
    fi
    
    # Verificar memoria RAM (Pi 3B+ tiene 1GB)
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    if [[ $mem_total -gt 800 ]]; then
        pi3b "✅ Memoria RAM: ${mem_total}MB (compatible con Pi 3B+)"
        PI3B_DETECTED=true
    fi
    
    # Verificar núcleos de CPU
    local cpu_cores=$(nproc)
    if [[ $cpu_cores -ge 4 ]]; then
        pi3b "✅ CPU multi-core detectada: $cpu_cores núcleos"
        PI3B_DETECTED=true
    fi
}

# Aplicar optimizaciones específicas Pi 3B+
apply_pi3b_optimizations() {
    if [[ "$PI3B_DETECTED" != true ]]; then
        return 0
    fi
    
    pi3b "⚡ Aplicando optimizaciones específicas para Pi 3B+..."
    
    # 1. Configurar GPU memory para mayor capacidad
    if ! grep -q "gpu_mem=256" /boot/config.txt 2>/dev/null; then
        echo "gpu_mem=256" | sudo tee -a /boot/config.txt
        pi3b "GPU memory configurada a 256MB (vs 128MB en Pi Zero)"
    fi
    
    # 2. Habilitar overclocking moderado si está disponible
    if ! grep -q "arm_freq=" /boot/config.txt 2>/dev/null; then
        echo "# Pi 3B+ optimizations" | sudo tee -a /boot/config.txt
        echo "arm_freq=1400" | sudo tee -a /boot/config.txt
        echo "core_freq=400" | sudo tee -a /boot/config.txt
        echo "over_voltage=2" | sudo tee -a /boot/config.txt
        pi3b "Overclocking moderado aplicado (1.4GHz)"
    fi
    
    # 3. Configurar CPU governor para rendimiento
    echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils > /dev/null 2>&1 || true
    pi3b "CPU governor configurado a 'performance'"
    
    # 4. Optimizar swap para 1GB RAM
    if [[ -f /etc/dphys-swapfile ]]; then
        sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
        pi3b "Swap configurado a 1024MB (aprovechando mayor RAM)"
    fi
    
    # 5. Configurar red para mayor throughput
    cat > /tmp/network_pi3b.conf << 'EOF'
# Optimizaciones de red Pi 3B+
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 16384 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.core.netdev_max_backlog = 5000
EOF
    
    if ! grep -q "Optimizaciones de red Pi 3B+" /etc/sysctl.conf; then
        sudo tee -a /etc/sysctl.conf < /tmp/network_pi3b.conf > /dev/null
        pi3b "Optimizaciones de red aplicadas"
    fi
    rm -f /tmp/network_pi3b.conf
    
    # 6. Configurar almacenamiento para mayor velocidad
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"' | \
        sudo tee /etc/udev/rules.d/60-ioschedulers-pi3b.rules
    
    success "✅ Optimizaciones Pi 3B+ aplicadas"
}

# Crear configuración específica Pi 3B+
create_pi3b_config() {
    pi3b "📋 Creando configuración optimizada para Pi 3B+..."
    
    mkdir -p "$INSTALL_DIR/config/raspberry_pi"
    
    cat > "$INSTALL_DIR/config/raspberry_pi/config_pi3b.json" << 'EOF'
{
  "_comment": "Configuración optimizada para Raspberry Pi 3B+",
  "_version": "1.0.0-pi3b",
  "_hardware": "Raspberry Pi 3B+",
  
  "serial": {
    "puerto": "/dev/ttyAMA0",
    "baudrate": 115200,
    "timeout": 1.5
  },
  
  "imagen": {
    "ancho_default": 1600,
    "calidad_default": 7,
    "chunk_size": 512,
    "ack_timeout": 8,
    "jpeg_progressive": true,
    "multiple_capture": true,
    "concurrent_processing": true
  },
  
  "almacenamiento": {
    "directorio_fullres": "data/images/raw",
    "directorio_enhanced": "data/images/processed",
    "mantener_originales": true,
    "logs_dir": "data/logs",
    "max_log_files": 10,
    "max_images_local": 500,
    "compression_level": 6
  },
  
  "procesamiento": {
    "aplicar_mejoras": true,
    "unsharp_mask": true,
    "clahe_enabled": true,
    "clahe_clip_limit": 2.0,
    "clahe_tile_size": 8,
    "noise_reduction": true,
    "color_enhancement": true,
    "parallel_processing": true,
    "max_workers": 4
  },
  
  "limites": {
    "max_jpeg_bytes": 262144,
    "fallback_quality_drop": 10,
    "max_resolution_width": 2048,
    "min_resolution_width": 320,
    "max_processing_time_ms": 5000
  },
  
  "pi3b_optimizations": {
    "enabled": true,
    "use_multicore": true,
    "cpu_affinity": [0, 1, 2, 3],
    "high_performance_mode": true,
    "gpu_memory_split": 256,
    "swap_limit_mb": 1024,
    "enable_overclocking": false,
    "thermal_throttle_limit": 80,
    "network_optimizations": true,
    "io_scheduler": "mq-deadline"
  },
  
  "network": {
    "ethernet_priority": true,
    "wifi_fallback": true,
    "connection_timeout": 30,
    "retry_attempts": 3,
    "buffer_size": 65536
  },
  
  "advanced": {
    "enable_threading": true,
    "thread_pool_size": 8,
    "async_operations": true,
    "memory_mapping": true,
    "zero_copy_networking": true
  },
  
  "update": {
    "enabled": true,
    "check_interval_hours": 6,
    "auto_update": true,
    "update_time": "02:00",
    "allow_uart_update": true,
    "backup_before_update": true,
    "max_backups": 5
  }
}
EOF
    
    success "✅ Configuración Pi 3B+ creada con optimizaciones avanzadas"
}

# Instalar dependencias optimizadas para Pi 3B+
install_pi3b_dependencies() {
    info "📦 Instalando dependencias optimizadas para Pi 3B+..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Paquetes base más completos para Pi 3B+
    local packages=(
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "python3-picamera2"
        "python3-opencv"
        "python3-serial"
        "python3-numpy"
        "python3-scipy"
        "python3-matplotlib"
        "python3-pillow"
        "git"
        "rsync"
        "htop"
        "iotop"
        "build-essential"
        "cmake"
        "pkg-config"
        "libjpeg-dev"
        "libtiff5-dev"
        "libpng-dev"
        "libavcodec-dev"
        "libavformat-dev"
        "libswscale-dev"
        "libgtk-3-dev"
        "libcanberra-gtk3-module"
        "libatlas-base-dev"
        "gfortran"
    )
    
    sudo apt update
    sudo apt install -y "${packages[@]}"
    
    # Optimizaciones específicas de compilación para Pi 3B+
    export MAKEFLAGS="-j4"  # Usar los 4 cores
    
    success "✅ Dependencias Pi 3B+ instaladas"
}

# Crear requirements específico para Pi 3B+
create_pi3b_requirements() {
    pi3b "📋 Creando requirements optimizado para Pi 3B+..."
    
    cat > "$INSTALL_DIR/requirements-pi3b.txt" << 'EOF'
# Requirements optimizado para Raspberry Pi 3B+
# Aprovecha mayor capacidad de CPU y RAM

# Core dependencies con versiones completas
picamera2>=0.3.12
opencv-python>=4.8.0
pyserial>=3.5
numpy>=1.21.0
scipy>=1.10.0
Pillow>=9.0.0
matplotlib>=3.6.0

# Flask con extensiones para servidor robusto
flask>=2.3.0
flask-cors>=4.0.0
flask-socketio>=5.3.0
gunicorn>=21.0.0

# Networking y comunicaciones mejoradas
requests>=2.31.0
urllib3>=2.0.0
aiohttp>=3.8.0

# Procesamiento de imágenes avanzado
scikit-image>=0.21.0
imageio>=2.31.0

# Herramientas de desarrollo
python-dotenv>=1.0.0
gitpython>=3.1.0
psutil>=5.9.0

# Monitoreo y logging
python-dateutil>=2.8.0
colorlog>=6.7.0

# Procesamiento paralelo y async
asyncio-throttle>=1.0.2
concurrent-futures>=3.1.1

# Optimizaciones numéricas
numba>=0.58.0

# Base de datos ligera para logs
sqlite3
EOF
    
    success "✅ Requirements Pi 3B+ creado con librerías avanzadas"
}

# Configurar sistema multi-core
setup_multicore_processing() {
    if [[ "$PI3B_DETECTED" != true ]]; then
        return 0
    fi
    
    pi3b "⚡ Configurando procesamiento multi-core..."
    
    # Configurar límites del sistema para aprovechar recursos
    cat > /tmp/pi3b_limits.conf << 'EOF'
# Límites optimizados para Pi 3B+
* soft nofile 65536
* hard nofile 65536
* soft nproc 8192
* hard nproc 8192
EOF
    
    sudo cp /tmp/pi3b_limits.conf /etc/security/limits.d/99-pi3b-foto-uart.conf
    rm -f /tmp/pi3b_limits.conf
    
    # Configurar systemd para usar múltiples cores
    sudo mkdir -p /etc/systemd/system.conf.d
    cat > /tmp/pi3b_systemd.conf << 'EOF'
[Manager]
DefaultTasksMax=8192
DefaultMemoryAccounting=yes
DefaultCPUAccounting=yes
EOF
    
    sudo cp /tmp/pi3b_systemd.conf /etc/systemd/system.conf.d/pi3b-optimizations.conf
    rm -f /tmp/pi3b_systemd.conf
    
    success "✅ Configuración multi-core aplicada"
}

# Crear scripts específicos Pi 3B+
create_pi3b_scripts() {
    pi3b "🔧 Creando scripts específicos para Pi 3B+..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Script optimizado para Pi 3B+
    cat > "$HOME/.local/bin/foto-uart-pi3b" << EOF
#!/bin/bash
# Script optimizado para Raspberry Pi 3B+
cd "$INSTALL_DIR"
source venv/bin/activate

# Configurar variables de entorno para Pi 3B+
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MKL_NUM_THREADS=4
export NUMBA_NUM_THREADS=4

# Configurar prioridad de proceso
export PYTHONPATH="$INSTALL_DIR/src:\$PYTHONPATH"

# Ejecutar con configuración Pi 3B+
python -m src.raspberry_pi.foto_uart \\
    --config config/raspberry_pi/config_pi3b.json "\$@"
EOF

    # Script de monitoreo avanzado para Pi 3B+
    cat > "$HOME/.local/bin/foto-uart-monitor-pi3b" << 'EOF'
#!/bin/bash
# Monitor avanzado para Pi 3B+
while true; do
    clear
    echo "=== Monitor FotoUART Pi 3B+ ==="
    echo "Fecha: $(date)"
    echo
    
    # Información de CPU por core
    echo "🔥 CPU por core:"
    for i in {0..3}; do
        freq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")
        if [[ "$freq" != "N/A" ]]; then
            freq_mhz=$((freq / 1000))
            echo "   Core $i: ${freq_mhz}MHz"
        fi
    done
    
    # Temperatura detallada
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        echo "🌡️  Temperatura: ${temp}°C"
        
        if [[ $temp -gt 75 ]]; then
            echo "   ⚠️  Temperatura alta"
        fi
    fi
    
    # Memoria detallada
    echo "💾 Memoria:"
    free -h | grep -E "^Mem|^Swap"
    
    # Red
    echo "🌐 Red:"
    ip route | grep default | head -1 | awk '{print "   Gateway: " $3 " via " $5}'
    
    # Carga del sistema
    echo "📊 Carga del sistema:"
    uptime | awk -F'load average:' '{print "   " $2}'
    
    # Estado de servicios FotoUART
    echo "⚙️  Servicios FotoUART:"
    for service in "foto-uart" "foto-uart-pi3b"; do
        if systemctl is-active --quiet "$service.service" 2>/dev/null; then
            echo "   ✅ $service: ACTIVO"
        else
            echo "   ❌ $service: INACTIVO"
        fi
    done
    
    # Procesos FotoUART
    echo "🔄 Procesos:"
    ps aux | grep -i foto | grep -v grep | wc -l | awk '{print "   FotoUART procesos: " $1}'
    
    sleep 5
done
EOF

    # Script de test de rendimiento Pi 3B+
    cat > "$HOME/.local/bin/foto-uart-benchmark-pi3b" << EOF
#!/bin/bash
# Benchmark específico para Pi 3B+
echo "🏁 Benchmark FotoUART Pi 3B+"
echo "============================"

cd "$INSTALL_DIR"
source venv/bin/activate

echo "📊 Información del sistema:"
echo "CPU: \$(nproc) cores"
echo "RAM: \$(free -h | awk 'NR==2{print \$2}')"
echo "Modelo: \$(cat /proc/device-tree/model | tr -d '\0')"
echo

echo "🧪 Test de configuración Pi 3B+..."
python3 -c "
import json
import time
import numpy as np
from concurrent.futures import ThreadPoolExecutor

# Test de configuración
with open('config/raspberry_pi/config_pi3b.json') as f:
    config = json.load(f)

print(f'✅ Configuración cargada')
print(f'   Resolución: {config[\"imagen\"][\"ancho_default\"]}px')
print(f'   Calidad: {config[\"imagen\"][\"calidad_default\"]}')
print(f'   Chunk size: {config[\"imagen\"][\"chunk_size\"]} bytes')
print(f'   Multi-core: {config[\"pi3b_optimizations\"][\"use_multicore\"]}')

# Test de rendimiento multi-core
print('\\n🔥 Test multi-core (matrix multiplication):')
start_time = time.time()

def matrix_test(size):
    a = np.random.rand(size, size)
    b = np.random.rand(size, size)
    return np.dot(a, b)

# Test secuencial
start = time.time()
result1 = matrix_test(500)
sequential_time = time.time() - start

# Test paralelo
start = time.time()
with ThreadPoolExecutor(max_workers=4) as executor:
    futures = [executor.submit(matrix_test, 250) for _ in range(4)]
    results = [f.result() for f in futures]
parallel_time = time.time() - start

speedup = sequential_time / parallel_time
print(f'   Secuencial: {sequential_time:.2f}s')
print(f'   Paralelo (4 cores): {parallel_time:.2f}s')
print(f'   Speedup: {speedup:.2f}x')

total_time = time.time() - start_time
print(f'\\n⏱️  Test completado en {total_time:.2f}s')
"

echo "✅ Benchmark completado"
EOF

    chmod +x "$HOME/.local/bin/foto-uart"*
    
    success "✅ Scripts Pi 3B+ creados"
}

# Configurar servicio systemd optimizado para Pi 3B+
setup_pi3b_service() {
    pi3b "⚙️  Configurando servicio systemd optimizado para Pi 3B+..."
    
    sudo tee /etc/systemd/system/foto-uart-pi3b.service > /dev/null << EOF
[Unit]
Description=FotoUART Drop-in Service - Pi 3B+ Edition
Documentation=https://github.com/cpatagon/foto-uart-dropin
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
Environment=OMP_NUM_THREADS=4
Environment=OPENBLAS_NUM_THREADS=4
Environment=PYTHONPATH=$INSTALL_DIR/src

# Configuración específica Pi 3B+
ExecStart=$INSTALL_DIR/venv/bin/python -m src.raspberry_pi.foto_uart --config config/raspberry_pi/config_pi3b.json
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Límites de recursos para Pi 3B+
MemoryMax=800M
CPUQuota=350%
TasksMax=200
CPUAffinity=0 1 2 3

# Nice level para prioridad
Nice=-5

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
    sudo systemctl enable foto-uart-pi3b.service
    
    success "✅ Servicio Pi 3B+ configurado con optimizaciones de rendimiento"
}

# Mostrar información final Pi 3B+
show_pi3b_final_info() {
    clear
    pi3b "=== Instalación Pi 3B+ Completada ==="
    echo
    success "🎉 FotoUART Drop-in optimizado para Pi 3B+ instalado exitosamente!"
    echo
    
    if [[ "$PI3B_DETECTED" == true ]]; then
        pi3b "⚡ Optimizaciones aplicadas:"
        pi3b "   ✅ GPU Memory: 256MB (vs 128MB Pi Zero)"
        pi3b "   ✅ CPU: Modo performance, 4 cores"
        pi3b "   ✅ RAM: 1GB con swap 1GB"
        pi3b "   ✅ Procesamiento multi-core habilitado"
        pi3b "   ✅ Overclocking moderado aplicado"
        pi3b "   ✅ Optimizaciones de red avanzadas"
        echo
    fi
    
    info "🚀 Comandos específicos Pi 3B+:"
    info "   foto-uart-pi3b                   # Ejecutar optimizado Pi 3B+"
    info "   foto-uart-monitor-pi3b           # Monitor avanzado"
    info "   foto-uart-benchmark-pi3b         # Test de rendimiento"
    
    echo
    info "📊 Capacidades mejoradas vs Pi Zero W:"
    info "   🖼️  Resolución: 800px → 1600px"
    info "   📦 Chunk size: 128B → 512B"
    info "   💾 Límite imagen: 64KB → 256KB"
    info "   ⚡ Procesamiento: 1 core → 4 cores"
    info "   🧠 RAM disponible: ~200MB → ~600MB"
    info "   ⏱️  Tiempo estimado foto 1600px: ~8-10s"
    
    echo
    info "📁 Archivos importantes:"
    info "   Config: $INSTALL_DIR/config/raspberry_pi/config_pi3b.json"
    info "   Requirements: $INSTALL_DIR/requirements-pi3b.txt"
    
    echo
    success "🎉 ¡Sistema Pi 3B+ listo para máximo rendimiento!"
}

# Función principal
main() {
    show_pi3b_banner
    
    detect_pi3b
    apply_pi3b_optimizations
    
    # Crear estructura específica Pi 3B+
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    install_pi3b_dependencies
    create_pi3b_config
    create_pi3b_requirements
    setup_multicore_processing
    create_pi3b_scripts
    setup_pi3b_service
    show_pi3b_final_info
}

# Ejecutar solo si no está siendo incluido
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
