# 📸 FotoUART Drop-in System - Guía de Instalación

Sistema profesional de captura y transmisión de imágenes optimizado para **Raspberry Pi Zero W** y **Raspberry Pi 3B+** con ESP32 via UART.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Raspberry Pi](https://img.shields.io/badge/hardware-Pi%20Zero%20W%20%7C%20Pi%203B+-red.svg)](https://www.raspberrypi.org/)

---

## 🎯 **Instaladores Específicos por Modelo**

El sistema incluye **dos instaladores optimizados** específicamente para cada modelo de Raspberry Pi:

### 📋 **Tabla de Instaladores**

| Script | Modelo Objetivo | Optimizaciones | Rendimiento |
|--------|----------------|----------------|-------------|
| `install_pi3b_V01.sh` | **Raspberry Pi 3B+** | Multi-core, 1GB RAM, Ethernet | ⚡ Alto rendimiento |
| `install_pi_V01.sh` | **Raspberry Pi Zero W** | Eficiencia, 512MB RAM, WiFi | 🔋 Ultra eficiente |

---

## 🔧 **Instalación para Raspberry Pi 3B+**

### **Script: `install_pi3b_V01.sh`**

#### **🚀 Instalación Rápida**

```bash
# Descarga e instalación automática
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b_V01.sh | bash

# O instalación manual
wget https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b_V01.sh
chmod +x install_pi3b_V01.sh
./install_pi3b_V01.sh
```

#### **⚙️ Opciones de Instalación Pi 3B+**

```bash
# Instalación básica
./install_pi3b_V01.sh

# Instalación completa con servicios
./install_pi3b_V01.sh --auto-update --service

# Instalación con modo alto rendimiento
./install_pi3b_V01.sh --service --performance-mode --overclocking

# Instalación desde rama específica
./install_pi3b_V01.sh --branch=develop --force-reinstall
```

#### **🔧 Optimizaciones Aplicadas Pi 3B+**

| Configuración | Valor | Beneficio |
|---------------|-------|-----------|
| **Resolución por defecto** | 1600px | Mayor calidad de imagen |
| **Calidad JPEG** | 7/10 | Balance calidad/tamaño |
| **Chunk size** | 512 bytes | Transmisión más eficiente |
| **GPU Memory** | 256MB | Procesamiento gráfico mejorado |
| **CPU Governor** | performance | Máximo rendimiento |
| **Overclocking** | 1.4GHz | 40% más velocidad |
| **Multi-threading** | 4 cores | Procesamiento paralelo |
| **Swap** | 1024MB | Aprovecha mayor RAM |

#### **📊 Rendimiento Esperado Pi 3B+**

```
📸 Captura de imagen (1600px):  1-2 segundos
🔄 Procesamiento avanzado:      0.5-1 segundo  
📡 Transmisión UART (256KB):    4-6 segundos
💾 Uso de RAM típico:           300-400MB
🔥 Uso de CPU durante captura:  70-80%
⏱️  Tiempo total por foto:       6-8 segundos
```

#### **🎯 Comandos Específicos Pi 3B+**

```bash
# Script optimizado Pi 3B+
foto-uart-pi3b                 # Ejecutar con optimizaciones Pi 3B+
foto-uart-monitor-pi3b         # Monitor avanzado multi-core
foto-uart-benchmark-pi3b       # Test de rendimiento 4 cores

# Configuración específica
nano config/raspberry_pi/config_pi3b.json

# Servicio systemd
sudo systemctl start foto-uart-pi3b.service
sudo systemctl status foto-uart-pi3b.service
```

---

## 🔋 **Instalación para Raspberry Pi Zero W**

### **Script: `install_pi_V01.sh`**

#### **🚀 Instalación Rápida**

```bash
# Descarga e instalación automática
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_V01.sh | bash

# O instalación manual
wget https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_V01.sh
chmod +x install_pi_V01.sh
./install_pi_V01.sh
```

#### **⚙️ Opciones de Instalación Pi Zero W**

```bash
# Instalación básica optimizada
./install_pi_V01.sh

# Instalación completa con servicios
./install_pi_V01.sh --auto-update --service

# Instalación con modo ultra eficiente
./install_pi_V01.sh --service --low-power-mode

# Instalación desde rama específica
./install_pi_V01.sh --branch=pi-zero --minimal-deps
```

#### **🔧 Optimizaciones Aplicadas Pi Zero W**

| Configuración | Valor | Beneficio |
|---------------|-------|-----------|
| **Resolución por defecto** | 800px | Óptimo para hardware limitado |
| **Calidad JPEG** | 4/10 | Balance eficiencia/calidad |
| **Chunk size** | 128 bytes | Transmisión estable |
| **GPU Memory** | 128MB | Conserva RAM para sistema |
| **CPU Governor** | ondemand | Eficiencia energética |
| **Single-thread** | 1 core | Optimizado para single-core |
| **Swap** | 512MB | Apropiado para 512MB RAM |
| **Servicios reducidos** | Mínimos | Ahorro de recursos |

#### **📊 Rendimiento Esperado Pi Zero W**

```
📸 Captura de imagen (800px):   2-3 segundos
🔄 Procesamiento básico:        1-2 segundos
📡 Transmisión UART (64KB):     8-10 segundos  
💾 Uso de RAM típico:           200-250MB
🔥 Uso de CPU durante captura:  85-90%
⏱️  Tiempo total por foto:       12-15 segundos
```

#### **🎯 Comandos Específicos Pi Zero W**

```bash
# Script optimizado Pi Zero W
foto-uart-pi-zero              # Ejecutar con optimizaciones Pi Zero W
foto-uart-monitor              # Monitor eficiente de recursos
foto-uart-performance-test     # Test optimizado Pi Zero W

# Configuración específica
nano config/raspberry_pi/config_pi_zero.json

# Servicio systemd
sudo systemctl start foto-uart-pi-zero.service
sudo systemctl status foto-uart-pi-zero.service
```

---

## 📋 **Comparación Detallada de Instaladores**

### **🔧 Características de `install_pi3b_V01.sh`**

```bash
✅ OPTIMIZACIONES PI 3B+:
   🔥 Overclocking a 1.4GHz
   ⚡ Multi-threading (4 cores)
   💾 GPU Memory 256MB
   🌐 Optimizaciones Ethernet
   📈 Procesamiento paralelo de imágenes
   🔧 Configuración performance CPU
   📦 Dependencias completas (OpenCV, SciPy, NumPy)
   🎯 Servicios systemd con límites altos
   📊 Monitor avanzado por core
   🧪 Benchmarks multi-core

✅ CONFIGURACIONES AUTOMÁTICAS:
   - Resolución: 1600px por defecto
   - Calidad JPEG: 7/10
   - Chunk size: 512B para mayor throughput
   - Límite imagen: 256KB
   - Timeout ACK: 8s (red más rápida)
   - Threading habilitado
   - Swap: 1024MB
```

### **🔋 Características de `install_pi_V01.sh`**

```bash
✅ OPTIMIZACIONES PI ZERO W:
   🔋 Modo bajo consumo
   💾 GPU Memory 128MB (conservar RAM)
   📡 Optimizaciones WiFi específicas
   🎯 Single-threading optimizado
   🔧 CPU Governor ondemand
   📦 Dependencias mínimas (system packages)
   ⚙️  Servicios systemd con límites bajos
   📊 Monitor eficiente de recursos
   🧪 Tests optimizados para single-core

✅ CONFIGURACIONES AUTOMÁTICAS:
   - Resolución: 800px por defecto
   - Calidad JPEG: 4/10
   - Chunk size: 128B para estabilidad
   - Límite imagen: 64KB
   - Timeout ACK: 15s (procesamiento lento)
   - Threading deshabilitado
   - Swap: 512MB
```

---

## 🛠️ **Proceso de Instalación Detallado**

### **1. Preparación del Sistema**

#### **Para Pi 3B+ (`install_pi3b_V01.sh`)**

```bash
# 1. Verificar modelo
cat /proc/device-tree/model
# Esperado: "Raspberry Pi 3 Model B Plus Rev 1.3"

# 2. Verificar memoria
free -h
# Esperado: ~1GB total

# 3. Verificar CPU cores
nproc
# Esperado: 4
```

#### **Para Pi Zero W (`install_pi_V01.sh`)**

```bash
# 1. Verificar modelo  
cat /proc/device-tree/model
# Esperado: "Raspberry Pi Zero W Rev 1.1"

# 2. Verificar memoria
free -h  
# Esperado: ~512MB total

# 3. Verificar WiFi
iwconfig
# Esperado: wlan0 presente
```

### **2. Ejecución de Instaladores**

#### **Instalación Pi 3B+ con Todas las Opciones**

```bash
# Descargar instalador específico Pi 3B+
wget https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b_V01.sh

# Hacer ejecutable
chmod +x install_pi3b_V01.sh

# Ejecutar con todas las optimizaciones
./install_pi3b_V01.sh \
    --auto-update \
    --service \
    --performance-mode \
    --overclocking \
    --multicore \
    --ethernet-priority
```

#### **Instalación Pi Zero W con Eficiencia Máxima**

```bash
# Descargar instalador específico Pi Zero W
wget https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_V01.sh

# Hacer ejecutable
chmod +x install_pi_V01.sh

# Ejecutar con optimizaciones de eficiencia
./install_pi_V01.sh \
    --auto-update \
    --service \
    --low-power-mode \
    --minimal-deps \
    --wifi-optimized
```

### **3. Verificación Post-Instalación**

#### **Verificación Pi 3B+**

```bash
# 1. Verificar instalación
foto-uart-benchmark-pi3b

# 2. Verificar configuración
cat config/raspberry_pi/config_pi3b.json | jq '.pi3b_optimizations'

# 3. Verificar servicios
sudo systemctl status foto-uart-pi3b.service

# 4. Test de rendimiento multi-core
foto-uart-monitor-pi3b

# Salida esperada:
# ✅ 4 cores detectados
# ✅ GPU Memory: 256MB
# ✅ Overclocking: 1.4GHz
# ✅ Multi-threading: habilitado
```

#### **Verificación Pi Zero W**

```bash
# 1. Verificar instalación
foto-uart-performance-test

# 2. Verificar configuración
cat config/raspberry_pi/config_pi_zero.json | jq '.pi_zero_optimizations'

# 3. Verificar servicios
sudo systemctl status foto-uart-pi-zero.service

# 4. Test de eficiencia
foto-uart-monitor

# Salida esperada:
# ✅ 1 core detectado
# ✅ GPU Memory: 128MB  
# ✅ Modo eficiencia: habilitado
# ✅ Memoria disponible: >200MB
```

---

## 📁 **Estructura de Archivos Generados**

### **Archivos Específicos Pi 3B+**

```
📁 foto-uart-dropin/
├── 📋 config/raspberry_pi/
│   ├── config_pi3b.json              # Configuración Pi 3B+
│   └── config.json -> config_pi3b.json
├── 📦 requirements-pi3b.txt           # Dependencias completas
├── 🔧 ~/.local/bin/
│   ├── foto-uart-pi3b                # Script optimizado Pi 3B+
│   ├── foto-uart-monitor-pi3b        # Monitor multi-core
│   ├── foto-uart-benchmark-pi3b      # Benchmark 4 cores
│   └── foto-uart -> foto-uart-pi3b   # Enlace genérico
└── ⚙️  /etc/systemd/system/
    └── foto-uart-pi3b.service        # Servicio optimizado
```

### **Archivos Específicos Pi Zero W**

```
📁 foto-uart-dropin/
├── 📋 config/raspberry_pi/
│   ├── config_pi_zero.json           # Configuración Pi Zero W
│   └── config.json -> config_pi_zero.json  
├── 📦 requirements-pi-zero.txt        # Dependencias mínimas
├── 🔧 ~/.local/bin/
│   ├── foto-uart-pi-zero             # Script optimizado Pi Zero W
│   ├── foto-uart-monitor             # Monitor eficiente
│   ├── foto-uart-performance-test    # Test Pi Zero W
│   └── foto-uart -> foto-uart-pi-zero # Enlace genérico
└── ⚙️  /etc/systemd/system/
    └── foto-uart-pi-zero.service     # Servicio eficiente
```

---

## 🔧 **Configuraciones Hardware Específicas**

### **Configuraciones Aplicadas en Pi 3B+**

```bash
# /boot/config.txt optimizaciones Pi 3B+
gpu_mem=256                    # vs 128MB en Pi Zero
arm_freq=1400                  # Overclocking 1.4GHz
core_freq=400                  # Core a 400MHz
over_voltage=2                 # Voltaje aumentado

# /etc/sysctl.conf optimizaciones de red
net.core.rmem_max=16777216     # Buffer recepción TCP
net.core.wmem_max=16777216     # Buffer envío TCP
net.ipv4.tcp_rmem=4096 16384 16777216
net.ipv4.tcp_wmem=4096 16384 16777216

# CPU Governor
GOVERNOR="performance"         # Máximo rendimiento
```

### **Configuraciones Aplicadas en Pi Zero W**

```bash
# /boot/config.txt optimizaciones Pi Zero W
gpu_mem=128                    # Conservar RAM del sistema
# Sin overclocking            # Mantener estabilidad

# /etc/dhcpcd.conf optimizaciones WiFi
interface wlan0
static domain_name_servers=8.8.8.8 1.1.1.1
noipv6                        # Deshabilitar IPv6

# CPU Governor  
GOVERNOR="ondemand"           # Eficiencia energética

# Servicios deshabilitados para ahorrar recursos
systemctl disable triggerhappy avahi-daemon
```

---

## 🚀 **Comandos de Uso Post-Instalación**

### **Comandos Pi 3B+ (`install_pi3b_V01.sh`)**

```bash
# Ejecutar FotoUART optimizado Pi 3B+
foto-uart-pi3b

# Monitor en tiempo real (multi-core)
foto-uart-monitor-pi3b

# Test de rendimiento multi-threading
foto-uart-benchmark-pi3b

# Configuración avanzada
nano config/raspberry_pi/config_pi3b.json

# Control de servicio
sudo systemctl start foto-uart-pi3b.service
sudo systemctl enable foto-uart-pi3b.service
sudo journalctl -u foto-uart-pi3b.service -f

# Variables de entorno específicas
export OMP_NUM_THREADS=4      # OpenMP 4 threads
export OPENBLAS_NUM_THREADS=4 # OpenBLAS 4 threads
export NUMBA_NUM_THREADS=4    # Numba 4 threads
```

### **Comandos Pi Zero W (`install_pi_V01.sh`)**

```bash
# Ejecutar FotoUART optimizado Pi Zero W
foto-uart-pi-zero

# Monitor eficiente de recursos
foto-uart-monitor

# Test de rendimiento single-core
foto-uart-performance-test  

# Configuración eficiente
nano config/raspberry_pi/config_pi_zero.json

# Control de servicio
sudo systemctl start foto-uart-pi-zero.service
sudo systemctl enable foto-uart-pi-zero.service
sudo journalctl -u foto-uart-pi-zero.service -f

# Variables de entorno específicas
export OMP_NUM_THREADS=1      # Single thread
export OPENBLAS_NUM_THREADS=1 # Single thread optimizado
```

---

## 🔄 **Migración Entre Instaladores**

### **De Pi Zero W a Pi 3B+**

```bash
# 1. Crear backup
./setup.sh backup

# 2. Remover instalación Pi Zero W
./install_pi_V01.sh --remove --keep-data

# 3. Instalar optimizado Pi 3B+
./install_pi3b_V01.sh --migrate-from-pi-zero

# 4. Verificar migración
foto-uart-benchmark-pi3b
```

### **De Pi 3B+ a Pi Zero W**

```bash
# 1. Crear backup
./setup.sh backup

# 2. Remover instalación Pi 3B+
./install_pi3b_V01.sh --remove --keep-data

# 3. Instalar optimizado Pi Zero W
./install_pi_V01.sh --migrate-from-pi3b

# 4. Verificar migración
foto-uart-performance-test
```

---

## 🐛 **Troubleshooting Específico**

### **Problemas Comunes Pi 3B+**

#### **Alto Uso de CPU**
```bash
# Verificar temperatura
vcgencmd measure_temp

# Si temp > 80°C, verificar disipación
# Reducir overclocking temporalmente
sudo nano /boot/config.txt
# Comentar: #arm_freq=1400

# Reiniciar
sudo reboot
```

#### **Problemas de Red Ethernet**
```bash
# Verificar configuración de red
ip route show
ping 8.8.8.8

# Reconfigurar si es necesario
sudo dhclient eth0
```

### **Problemas Comunes Pi Zero W**

#### **Memoria Insuficiente**
```bash
# Verificar uso de memoria
free -h

# Si RAM < 100MB disponible:
# 1. Reducir resolución
nano config/raspberry_pi/config_pi_zero.json
# Cambiar "ancho_default": 640

# 2. Reiniciar servicio
sudo systemctl restart foto-uart-pi-zero.service
```

#### **WiFi Inestable**
```bash
# Verificar señal WiFi
iwconfig wlan0

# Si señal baja, optimizar:
sudo nano /etc/dhcpcd.conf
# Agregar: interface wlan0
#         static ip_address=192.168.1.50/24
```

---

## 📞 **Soporte y Recursos**

### **Links Útiles**

- 📖 **Documentación completa**: [docs/](../docs/)
- 🐛 **Reportar problemas**: [GitHub Issues](https://github.com/cpatagon/foto-uart-dropin/issues)
- 💬 **Discusiones**: [GitHub Discussions](https://github.com/cpatagon/foto-uart-dropin/discussions)
- 📋 **Ejemplos**: [examples/](../examples/)

### **Comandos de Diagnóstico**

```bash
# Información del sistema
foto-uart-system-info

# Logs detallados
sudo journalctl -u foto-uart-* --since "1 hour ago"

# Estado completo del sistema
./setup.sh status --verbose

# Validación completa
./setup.sh validate --fix --report
```

---

## 🎉 **¡Instalación Completada!**

Después de ejecutar el instalador apropiado para tu modelo de Raspberry Pi:

### **✅ Pi 3B+ Listo**
- 🔥 **4 cores** a máximo rendimiento
- 📸 **Capturas de 1600px** en 1-2 segundos  
- ⚡ **Procesamiento paralelo** optimizado
- 🌐 **Ethernet** configurado para máximo throughput

### **✅ Pi Zero W Listo**
- 🔋 **Ultra eficiente** para aplicaciones IoT
- 📸 **Capturas de 800px** optimizadas
- 📡 **WiFi** configurado para estabilidad  
- 💾 **Memoria** gestionada inteligentemente

**¡Tu sistema FotoUART está optimizado y listo para usar!** 📸⚡
