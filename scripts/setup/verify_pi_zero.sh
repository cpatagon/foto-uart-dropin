#!/bin/bash
# Verificación específica para Pi Zero W

set -euo pipefail

info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

info "🔍 Verificando instalación para Pi Zero W..."

# Verificar modelo de Pi
if [[ -f /proc/device-tree/model ]]; then
    model=$(tr -d '\0' < /proc/device-tree/model)
    if echo "$model" | grep -q "Pi Zero"; then
        success "✅ Raspberry Pi Zero detectada: $model"
    else
        warn "⚠️  Modelo detectado: $model (esperado Pi Zero)"
    fi
fi

# Verificar memoria
mem_total=$(free -m | awk 'NR==2{print $2}')
if [[ $mem_total -lt 600 ]]; then
    success "✅ Memoria limitada detectada: ${mem_total}MB (típico de Pi Zero)"
else
    warn "⚠️  Memoria: ${mem_total}MB (mayor a lo esperado para Pi Zero)"
fi

# Verificar configuración GPU
if grep -q "gpu_mem=128" /boot/config.txt 2>/dev/null; then
    success "✅ GPU memory configurada correctamente"
else
    warn "⚠️  GPU memory no configurada para Pi Zero"
fi

# Verificar swap
swap_total=$(free -m | awk 'NR==3{print $2}')
if [[ $swap_total -eq 512 ]]; then
    success "✅ Swap configurado para Pi Zero: ${swap_total}MB"
else
    warn "⚠️  Swap: ${swap_total}MB (recomendado 512MB para Pi Zero)"
fi

# Verificar temperatura
if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    if [[ $temp -lt 70 ]]; then
        success "✅ Temperatura OK: ${temp}°C"
    else
        warn "⚠️  Temperatura elevada: ${temp}°C"
    fi
fi

# Verificar configuración específica Pi Zero
if [[ -f config/raspberry_pi/config_pi_zero.json ]]; then
    success "✅ Configuración Pi Zero encontrada"
    
    # Verificar parámetros específicos
    python3 -c "
import json
with open('config/raspberry_pi/config_pi_zero.json') as f:
    config = json.load(f)

# Verificaciones específicas
checks = [
    (config['imagen']['ancho_default'] <= 800, 'Resolución por defecto'),
    (config['imagen']['chunk_size'] <= 128, 'Chunk size'),
    (config['limites']['max_jpeg_bytes'] <= 65536, 'Límite JPEG'),
    (not config['almacenamiento']['mantener_originales'], 'No mantener originales'),
    (config['pi_zero_optimizations']['enabled'], 'Optimizaciones habilitadas')
]

for check, name in checks:
    if check:
        print(f'✅ {name}: OK')
    else:
        print(f'⚠️  {name}: No optimizado')
"
else
    warn "⚠️  Configuración Pi Zero no encontrada"
fi

success "🎉 Verificación completada"
