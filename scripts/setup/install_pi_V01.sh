#!/bin/bash
#
# Instalador Universal con Auto-Detección
# =======================================
# Detecta automáticamente el modelo de Pi y aplica optimizaciones específicas
#
# Uso:
#     curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/install_auto.sh | bash
#

set -euo pipefail

# Configuración
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
INSTALL_DIR="$HOME/$PROJECT_NAME"

# Variables de detección
PI_MODEL=""
PI_OPTIMIZATION=""
MEMORY_MB=0
CPU_CORES=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Funciones de utilidad
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
detect() { echo -e "${CYAN}[DETECT]${NC} $*"; }

# Banner principal
show_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║        📸 FotoUART Drop-in System - Instalador Universal            ║
    ║                                                                      ║
    ║        🔍 Auto-detección de modelo Raspberry Pi                     ║
    ║        ⚡ Optimizaciones específicas automáticas                    ║
    ║        📦 Configuración adaptativa de rendimiento                   ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Detectar modelo específico de Raspberry Pi
detect_pi_model() {
    detect "🔍 Detectando modelo de Raspberry Pi..."
    
    # Detectar por archivo de modelo
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(tr -d '\0' < /proc/device-tree/model)
        detect "   Hardware detectado: $model"
        
        # Clasificar modelo
        if echo "$model" | grep -q "Pi Zero W"; then
            PI_MODEL="Pi Zero W"
            PI_OPTIMIZATION="pi_zero_w"
        elif echo "$model" | grep -q "Pi Zero"; then
            PI_MODEL="Pi Zero"
            PI_OPTIMIZATION="pi_zero"
        elif echo "$model" | grep -q "Pi 3 Model B Plus"; then
            PI_MODEL="Pi 3B+"
            PI_OPTIMIZATION="pi3b_plus"
        elif echo "$model" | grep -q "Pi 3"; then
            PI_MODEL="Pi 3B"
            PI_OPTIMIZATION="pi3b"
        elif echo "$model" | grep -q "Pi 4"; then
            PI_MODEL="Pi 4"
            PI_OPTIMIZATION="pi4"
        elif echo "$model" | grep -q "Pi 5"; then
            PI_MODEL="Pi 5"
            PI_OPTIMIZATION="pi5"
        else
            PI_MODEL="Generic Pi"
            PI_OPTIMIZATION="generic"
        fi
    else
        warn "   No se puede detectar modelo específico"
        PI_MODEL="Unknown"
        PI_OPTIMIZATION="generic"
    fi
    
    # Detectar memoria RAM
    MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
    
    # Detectar núcleos de CPU
    CPU_CORES=$(nproc)
    
    # Refinar detección basada en especificaciones
    if [[ $MEMORY_MB -lt 600 ]]; then
        if [[ "$PI_MODEL" == "Generic Pi" ]]; then
            PI_MODEL="Pi Zero/W (by RAM)"
            PI_OPTIMIZATION="pi_zero_w"
        fi
    elif [[ $MEMORY_MB -gt 800 ]] && [[ $MEMORY_MB -lt 1200 ]]; then
        if [[ "$PI_MODEL" == "Generic Pi" ]]; then
            PI_MODEL="Pi 3B/B+ (by RAM)"
            PI_OPTIMIZATION="pi3b_plus"
        fi
    elif [[ $MEMORY_MB -gt 1800 ]]; then
        if [[ "$PI_MODEL" == "Generic Pi" ]]; then
            PI_MODEL="Pi 4/5 (by RAM)"
            PI_OPTIMIZATION="pi4"
        fi
    fi
    
    success "✅ Modelo detectado: $PI_MODEL"
    info "   💾 RAM: ${MEMORY_MB}MB"
    info "   🔥 CPU cores: $CPU_CORES"
    info "   ⚡ Optimización: $PI_OPTIMIZATION"
}

# Mostrar tabla de comparación de modelos
show_comparison_table() {
    echo
    info "📊 Comparación de Modelos Raspberry Pi:"
    echo
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "Modelo" "RAM" "Cores" "Resolución" "Chunk Size" "Características"
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "-------" "----" "-----" "----------" "-----------" "---------------"
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "Pi Zero W" "512MB" "1" "800px" "128B" "Ultra eficiente"
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "Pi 3B+" "1GB" "4" "1600px" "512B" "Multi-core, Ethernet"
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "Pi 4" "2-8GB" "4" "2048px" "1024B" "Alto rendimiento"
    printf "%-15s %-8s %-8s %-12s %-15s %-20s\n" "Pi 5" "4-8GB" "4" "2048px" "1024B" "Última generación"
    echo
    
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            success "👉 Tu modelo ($PI_MODEL) es ideal para aplicaciones IoT compactas"
            ;;
        "pi3b_plus"|"pi3b")
            success "👉 Tu modelo ($PI_MODEL) ofrece excelente balance rendimiento/consumo"
            ;;
        "pi4"|"pi5")
            success "👉 Tu modelo ($PI_MODEL) permite máximo rendimiento y resoluciones altas"
            ;;
        *)
            info "👉 Usando configuración genérica para tu modelo ($PI_MODEL)"
            ;;
    esac
}

# Configuración específica por modelo
get_model_config() {
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            echo '{
                "imagen": {
                    "ancho_default": 800,
                    "calidad_default": 4,
                    "chunk_size": 128,
                    "ack_timeout": 15
                },
                "limites": {
                    "max_jpeg_bytes": 65536,
                    "fallback_quality_drop": 15
                },
                "procesamiento": {
                    "unsharp_mask": false,
                    "clahe_enabled": true,
                    "parallel_processing": false
                },
                "optimizations": {
                    "gpu_memory": 128,
                    "swap_mb": 512,
                    "cpu_governor": "ondemand"
                }
            }'
            ;;
        "pi3b_plus"|"pi3b")
            echo '{
                "imagen": {
                    "ancho_default": 1600,
                    "calidad_default": 7,
                    "chunk_size": 512,
                    "ack_timeout": 8
                },
                "limites": {
                    "max_jpeg_bytes": 262144,
                    "fallback_quality_drop": 10
                },
                "procesamiento": {
                    "unsharp_mask": true,
                    "clahe_enabled": true,
                    "parallel_processing": true,
                    "max_workers": 4
                },
                "optimizations": {
                    "gpu_memory": 256,
                    "swap_mb": 1024,
                    "cpu_governor": "performance"
                }
            }'
            ;;
        "pi4"|"pi5")
            echo '{
                "imagen": {
                    "ancho_default": 2048,
                    "calidad_default": 8,
                    "chunk_size": 1024,
                    "ack_timeout": 5
                },
                "limites": {
                    "max_jpeg_bytes": 524288,
                    "fallback_quality_drop": 5
                },
                "procesamiento": {
                    "unsharp_mask": true,
                    "clahe_enabled": true,
                    "parallel_processing": true,
                    "max_workers": 8
                },
                "optimizations": {
                    "gpu_memory": 512,
                    "swap_mb": 2048,
                    "cpu_governor": "performance"
                }
            }'
            ;;
        *)
            echo '{
                "imagen": {
                    "ancho_default": 1024,
                    "calidad_default": 6,
                    "chunk_size": 256,
                    "ack_timeout": 10
                },
                "limites": {
                    "max_jpeg_bytes": 131072,
                    "fallback_quality_drop": 10
                },
                "procesamiento": {
                    "unsharp_mask": true,
                    "clahe_enabled": true,
                    "parallel_processing": false
                },
                "optimizations": {
                    "gpu_memory": 256,
                    "swap_mb": 512,
                    "cpu_governor": "ondemand"
                }
            }'
            ;;
    esac
}

# Aplicar optimizaciones específicas del modelo
apply_model_optimizations() {
    info "⚙️  Aplicando optimizaciones específicas para $PI_MODEL..."
    
    local config=$(get_model_config)
    local gpu_memory=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['optimizations']['gpu_memory'])")
    local swap_mb=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['optimizations']['swap_mb'])")
    local cpu_governor=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['optimizations']['cpu_governor'])")
    
    # Configurar GPU memory
    if ! grep -q "gpu_mem=$gpu_memory" /boot/config.txt 2>/dev/null; then
        echo "# FotoUART optimization for $PI_MODEL" | sudo tee -a /boot/config.txt
        echo "gpu_mem=$gpu_memory" | sudo tee -a /boot/config.txt
        info "   GPU memory configurada: ${gpu_memory}MB"
    fi
    
    # Configurar swap
    if [[ -f /etc/dphys-swapfile ]]; then
        sudo sed -i "s/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$swap_mb/" /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
        info "   Swap configurado: ${swap_mb}MB"
    fi
    
    # Configurar CPU governor
    echo "GOVERNOR=\"$cpu_governor\"" | sudo tee /etc/default/cpufrequtils > /dev/null 2>&1 || true
    info "   CPU governor: $cpu_governor"
    
    # Optimizaciones específicas por modelo
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            # Deshabilitar servicios innecesarios en Pi Zero
            local services_to_disable=("triggerhappy" "avahi-daemon")
            for service in "${services_to_disable[@]}"; do
                if systemctl is-enabled "$service" &>/dev/null; then
                    sudo systemctl disable "$service" 2>/dev/null || true
                    info "   Servicio $service deshabilitado para ahorrar recursos"
                fi
            done
            ;;
        "pi3b_plus"|"pi3b")
            # Habilitar overclocking moderado en Pi 3B+
            if ! grep -q "arm_freq=" /boot/config.txt 2>/dev/null; then
                echo "arm_freq=1400" | sudo tee -a /boot/config.txt
                echo "core_freq=400" | sudo tee -a /boot/config.txt
                echo "over_voltage=2" | sudo tee -a /boot/config.txt
                info "   Overclocking moderado aplicado (1.4GHz)"
            fi
            ;;
        "pi4"|"pi5")
            # Optimizaciones de red para Pi 4/5
            cat > /tmp/network_opts.conf << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
EOF
            if ! grep -q "net.core.rmem_max" /etc/sysctl.conf; then
                sudo tee -a /etc/sysctl.conf < /tmp/network_opts.conf > /dev/null
                info "   Optimizaciones de red aplicadas"
            fi
            rm -f /tmp/network_opts.conf
            ;;
    esac
    
    success "✅ Optimizaciones aplicadas para $PI_MODEL"
}

# Crear configuración adaptativa
create_adaptive_config() {
    info "📋 Creando configuración adaptativa para $PI_MODEL..."
    
    local config_dir="$INSTALL_DIR/config/raspberry_pi"
    mkdir -p "$config_dir"
    
    local model_config=$(get_model_config)
    
    # Configuración base completa
    cat > "$config_dir/config_${PI_OPTIMIZATION}.json" << EOF
{
  "_comment": "Configuración optimizada para $PI_MODEL",
  "_version": "1.0.0-$PI_OPTIMIZATION",
  "_hardware": "$PI_MODEL",
  "_auto_generated": true,
  "_generation_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  
  "serial": {
    "puerto": "/dev/ttyAMA0",
    "baudrate": 115200,
    "timeout": $(echo "$model_config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['imagen']['ack_timeout'] / 2)")
  },
  
  $(echo "$model_config" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Extraer secciones y formatear
for key in ['imagen', 'limites', 'procesamiento']:
    if key in data:
        print(f'  \"{key}\": {json.dumps(data[key], indent=4).replace(chr(10), chr(10) + \"  \")},')
")
  
  "almacenamiento": {
    "directorio_fullres": "data/images/raw",
    "directorio_enhanced": "data/images/processed",
    "mantener_originales": $([ "$PI_OPTIMIZATION" = "pi_zero_w" ] && echo "false" || echo "true"),
    "logs_dir": "data/logs",
    "max_log_files": $([ "$PI_OPTIMIZATION" = "pi_zero_w" ] && echo "5" || echo "10"),
    "max_images_local": $([ "$PI_OPTIMIZATION" = "pi_zero_w" ] && echo "100" || echo "500")
  },
  
  "hardware_info": {
    "model": "$PI_MODEL",
    "optimization": "$PI_OPTIMIZATION",
    "memory_mb": $MEMORY_MB,
    "cpu_cores": $CPU_CORES,
    "detected_capabilities": {
      "multicore": $([ $CPU_CORES -gt 1 ] && echo "true" || echo "false"),
      "high_memory": $([ $MEMORY_MB -gt 800 ] && echo "true" || echo "false"),
      "ethernet": $([ "$PI_OPTIMIZATION" != "pi_zero_w" ] && echo "true" || echo "false")
    }
  },
  
  "update": {
    "enabled": true,
    "check_interval_hours": $([ "$PI_OPTIMIZATION" = "pi_zero_w" ] && echo "12" || echo "6"),
    "auto_update": false,
    "update_time": "03:00",
    "allow_uart_update": true,
    "backup_before_update": true,
    "max_backups": $([ "$PI_OPTIMIZATION" = "pi_zero_w" ] && echo "3" || echo "5")
  }
}
EOF

    # Crear enlace a configuración activa
    ln -sf "config_${PI_OPTIMIZATION}.json" "$config_dir/config.json"
    
    success "✅ Configuración adaptativa creada: config_${PI_OPTIMIZATION}.json"
    info "   Enlace activo: config.json → config_${PI_OPTIMIZATION}.json"
}

# Crear requirements adaptativo
create_adaptive_requirements() {
    info "📦 Creando requirements adaptativo para $PI_MODEL..."
    
    # Requirements base
    cat > "$INSTALL_DIR/requirements-${PI_OPTIMIZATION}.txt" << 'EOF'
# Requirements adaptativo generado automáticamente
# Optimizado para: $PI_MODEL

# Core dependencies
picamera2>=0.3.12
pyserial>=3.5
requests>=2.31.0
python-dotenv>=1.0.0
gitpython>=3.1.0
python-dateutil>=2.8.0

# Flask para servidor
flask>=2.3.0
flask-cors>=4.0.0
EOF

    # Agregar dependencias específicas por modelo
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            cat >> "$INSTALL_DIR/requirements-${PI_OPTIMIZATION}.txt" << 'EOF'

# Pi Zero W - dependencias mínimas
numpy>=1.21.0,<1.25.0
# Usar opencv del sistema: sudo apt install python3-opencv
EOF
            ;;
        "pi3b_plus"|"pi3b")
            cat >> "$INSTALL_DIR/requirements-${PI_OPTIMIZATION}.txt" << 'EOF'

# Pi 3B+ - dependencias completas
numpy>=1.21.0
opencv-python>=4.8.0
scipy>=1.10.0
Pillow>=9.0.0
scikit-image>=0.21.0
numba>=0.58.0
psutil>=5.9.0
EOF
            ;;
        "pi4"|"pi5")
            cat >> "$INSTALL_DIR/requirements-${PI_OPTIMIZATION}.txt" << 'EOF'

# Pi 4/5 - dependencias avanzadas
numpy>=1.21.0
opencv-python>=4.8.0
scipy>=1.10.0
Pillow>=9.0.0
scikit-image>=0.21.0
matplotlib>=3.6.0
numba>=0.58.0
psutil>=5.9.0
aiohttp>=3.8.0
gunicorn>=21.0.0
sqlite3
EOF
            ;;
        *)
            cat >> "$INSTALL_DIR/requirements-${PI_OPTIMIZATION}.txt" << 'EOF'

# Configuración genérica
numpy>=1.21.0
opencv-python>=4.8.0
Pillow>=9.0.0
EOF
            ;;
    esac
    
    # Crear enlace a requirements activo
    ln -sf "requirements-${PI_OPTIMIZATION}.txt" "$INSTALL_DIR/requirements.txt"
    
    success "✅ Requirements adaptativo creado: requirements-${PI_OPTIMIZATION}.txt"
}

# Crear scripts específicos del modelo
create_model_scripts() {
    info "🔧 Creando scripts optimizados para $PI_MODEL..."
    
    mkdir -p "$HOME/.local/bin"
    
    # Script principal optimizado
    cat > "$HOME/.local/bin/foto-uart-$PI_OPTIMIZATION" << EOF
#!/bin/bash
# Script optimizado para $PI_MODEL
cd "$INSTALL_DIR"
source venv/bin/activate

# Variables de entorno específicas
export PYTHONPATH="$INSTALL_DIR/src:\$PYTHONPATH"
EOF

    # Configuraciones específicas por modelo
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            cat >> "$HOME/.local/bin/foto-uart-$PI_OPTIMIZATION" << 'EOF'

# Configuración Pi Zero W - conservar recursos
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

# Verificar temperatura antes de ejecutar
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp=$((temp / 1000))
    if [[ $temp -gt 75 ]]; then
        echo "⚠️  Temperatura alta: ${temp}°C - esperando..."
        sleep 30
    fi
fi
EOF
            ;;
        "pi3b_plus"|"pi3b")
            cat >> "$HOME/.local/bin/foto-uart-$PI_OPTIMIZATION" << 'EOF'

# Configuración Pi 3B+ - aprovechar multi-core
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MKL_NUM_THREADS=4
export NUMBA_NUM_THREADS=4

# Configurar afinidad de CPU
taskset -c 0-3 
EOF
            ;;
        "pi4"|"pi5")
            cat >> "$HOME/.local/bin/foto-uart-$PI_OPTIMIZATION" << 'EOF'

# Configuración Pi 4/5 - máximo rendimiento
export OMP_NUM_THREADS=4
export OPENBLAS_NUM_THREADS=4
export MKL_NUM_THREADS=4
export NUMBA_NUM_THREADS=4

# Prioridad alta para proceso
renice -10 $
EOF
            ;;
    esac
    
    # Finalizar script
    cat >> "$HOME/.local/bin/foto-uart-$PI_OPTIMIZATION" << EOF

# Ejecutar con configuración específica
python -m src.raspberry_pi.foto_uart \\
    --config config/raspberry_pi/config_${PI_OPTIMIZATION}.json "\$@"
EOF
    
    # Crear enlace genérico
    ln -sf "foto-uart-$PI_OPTIMIZATION" "$HOME/.local/bin/foto-uart"
    
    chmod +x "$HOME/.local/bin/foto-uart"*
    
    success "✅ Scripts optimizados creados para $PI_MODEL"
    info "   Script principal: foto-uart-$PI_OPTIMIZATION"
    info "   Enlace genérico: foto-uart"
}

# Mostrar resumen de instalación
show_installation_summary() {
    echo
    success "🎉 Instalación adaptativa completada para $PI_MODEL"
    echo
    
    info "📋 Configuración aplicada:"
    local config=$(get_model_config)
    local resolution=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['imagen']['ancho_default'])")
    local quality=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['imagen']['calidad_default'])")
    local chunk_size=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['imagen']['chunk_size'])")
    local max_bytes=$(echo "$config" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['limites']['max_jpeg_bytes'])")
    
    info "   🖼️  Resolución por defecto: ${resolution}px"
    info "   ⭐ Calidad JPEG: $quality/10"
    info "   📦 Chunk size: ${chunk_size}B"
    info "   💾 Límite imagen: $((max_bytes / 1024))KB"
    
    echo
    info "🚀 Comandos disponibles:"
    info "   foto-uart                        # Script genérico"
    info "   foto-uart-$PI_OPTIMIZATION      # Script optimizado específico"
    
    echo
    info "📁 Archivos específicos creados:"
    info "   config/raspberry_pi/config_${PI_OPTIMIZATION}.json"
    info "   requirements-${PI_OPTIMIZATION}.txt"
    
    echo
    info "⚡ Rendimiento estimado para $PI_MODEL:"
    case $PI_OPTIMIZATION in
        "pi_zero_w"|"pi_zero")
            info "   📸 Captura ${resolution}px: ~2-3s"
            info "   📡 Transmisión $((max_bytes / 1024))KB: ~8-10s"
            info "   💾 Uso RAM: ~200-250MB"
            ;;
        "pi3b_plus"|"pi3b")
            info "   📸 Captura ${resolution}px: ~1-2s"
            info "   📡 Transmisión $((max_bytes / 1024))KB: ~4-6s"
            info "   💾 Uso RAM: ~300-400MB"
            ;;
        "pi4"|"pi5")
            info "   📸 Captura ${resolution}px: ~0.5-1s"
            info "   📡 Transmisión $((max_bytes / 1024))KB: ~2-3s"
            info "   💾 Uso RAM: ~400-600MB"
            ;;
    esac
    
    echo
    info "📖 Próximos pasos:"
    info "   1. Conectar ESP32 a GPIO 14(TX)/15(RX)"
    info "   2. Conectar cámara al puerto CSI"
    info "   3. Ejecutar: foto-uart"
    info "   4. Verificar: $0 validate"
    
    if grep -q "Se requiere reiniciar\|gpu_mem\|arm_freq" /boot/config.txt 2>/dev/null; then
        echo
        warn "⚠️  REINICIO REQUERIDO para aplicar optimizaciones de hardware"
        warn "   Ejecutar: sudo reboot"
    fi
}

# Función principal
main() {
    show_banner
    
    # Detección automática
    detect_pi_model
    show_comparison_table
    
    # Confirmar detección
    echo
    read -p "¿Es correcta la detección de $PI_MODEL? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo
        info "📋 Modelos disponibles:"
        info "   1. Pi Zero W (512MB, 1 core)"
        info "   2. Pi 3B+ (1GB, 4 cores)"
        info "   3. Pi 4 (2-8GB, 4 cores)"
        info "   4. Pi 5 (4-8GB, 4 cores)"
        info "   5. Genérico"
        echo
        read -p "Seleccionar modelo (1-5): " choice
        
        case $choice in
            1) PI_MODEL="Pi Zero W"; PI_OPTIMIZATION="pi_zero_w" ;;
            2) PI_MODEL="Pi 3B+"; PI_OPTIMIZATION="pi3b_plus" ;;
            3) PI_MODEL="Pi 4"; PI_OPTIMIZATION="pi4" ;;
            4) PI_MODEL="Pi 5"; PI_OPTIMIZATION="pi5" ;;
            5) PI_MODEL="Generic Pi"; PI_OPTIMIZATION="generic" ;;
            *) error "❌ Selección inválida"; exit 1 ;;
        esac
        
        success "✅ Modelo seleccionado manualmente: $PI_MODEL"
    fi
    
    # Crear directorio de instalación
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Clonar repositorio si no existe
    if [[ ! -d ".git" ]]; then
        info "📥 Clonando repositorio FotoUART..."
        git clone "$REPO_URL" .
    fi
    
    # Aplicar configuraciones específicas
    apply_model_optimizations
    create_adaptive_config
    create_adaptive_requirements
    
    # Instalar dependencias
    info "📦 Instalando dependencias..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r "requirements-${PI_OPTIMIZATION}.txt"
    deactivate
    
    # Crear scripts optimizados
    create_model_scripts
    
    # Agregar al PATH si no está
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        info "💡 $HOME/.local/bin agregado al PATH en .bashrc"
    fi
    
    # Mostrar resumen
    show_installation_summary
}

# Ejecutar instalación
main "$@"
