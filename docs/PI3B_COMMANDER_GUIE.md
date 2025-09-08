# 📡 Guía Completa del Pi 3B+ Commander

Manual detallado para usar Raspberry Pi 3B+ como commander y storage del sistema foto-uart-dropin.

## 🎯 **Descripción General**

El **Pi 3B+ Commander** es el cerebro del sistema dual Pi que:
- 📡 **Controla** Pi Zero W via comandos UART
- 💾 **Almacena** imágenes recibidas localmente
- 🌐 **Sirve** web gallery para acceso remoto
- 🔄 **Gestiona** backups automáticos
- 📊 **Monitorea** el sistema completo

## ⚡ **Instalación**

### **🚀 Instalación Rápida:**
```bash
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b.sh | bash -s -- --web-gallery --auto-start --backup-usb
```

### **🔧 Instalación Manual:**
```bash
# Clonar repositorio
git clone https://github.com/cpatagon/foto-uart-dropin.git
cd foto-uart-dropin

# Ejecutar script de instalación
chmod +x scripts/setup/install_pi3b.sh
./scripts/setup/install_pi3b.sh --web-gallery
```

## 🎮 **Comandos Principales**

### **📸 Captura de Imágenes**

#### **Captura Única:**
```bash
# Captura básica con configuración por defecto
foto-uart-commander

# Con parámetros específicos
foto-uart-commander --width 1024 --quality 8

# Con configuración personalizada
foto-uart-commander --width 800 --quality 6
```

#### **Captura Continua:**
```bash
# Cada 5 minutos (300 segundos)
foto-uart-commander --continuous --interval 300

# Cada hora
foto-uart-commander --continuous --interval 3600

# Con logging detallado
foto-uart-commander --continuous --interval 60 --verbose
```

#### **Parámetros Disponibles:**
```bash
foto-uart-commander [opciones]

Opciones:
  --width WIDTH          Ancho de imagen (320-4096px, default: 1024)
  --quality QUALITY      Calidad JPEG (1-10, default: 6)
  --continuous           Modo captura continua
  --interval SECONDS     Intervalo entre capturas (default: 300)
  --info                 Mostrar información de almacenamiento
  --config FILE          Archivo de configuración personalizado
  --verbose              Logging detallado
  --test-speed           Test de velocidad de transferencia
```

### **📊 Información y Monitoreo**

#### **Estado del Sistema:**
```bash
# Información completa del almacenamiento
foto-uart-commander --info

# Output ejemplo:
# 📊 Almacenamiento Pi 3B+:
#    📁 Directorio: /home/pi/foto-uart-dropin/data/images/received
#    📷 Imágenes: 127
#    💾 Tamaño total: 15.3 MB
#    🕐 Última captura: 20241225_143022_received.jpg
```

#### **Monitor en Tiempo Real:**
```bash
# Monitor completo del sistema
foto-uart-monitor-pi3b

# Output en tiempo real:
# === Monitor Pi 3B+ Commander ===
# Fecha: 2024-12-25 14:30:45
# ✅ UART: /dev/ttyS0 disponible
# 💾 Almacenamiento: 28GB/32GB libre
# 📷 Imágenes: 127
# 🖥️  Sistema:
#    RAM: 245MB/1GB
#    CPU: 15%
#    Temp: 42°C
```

#### **Logs del Sistema:**
```bash
# Ver logs en tiempo real
tail -f ~/foto-uart-dropin/data/logs/pi3b_commander_*.log

# Logs específicos de transfers
tail -f ~/foto-uart-dropin/data/logs/uart_transfers.log

# Buscar errores
grep "ERROR" ~/foto-uart-dropin/data/logs/*.log
```

## 🌐 **Web Gallery**

### **🖥️ Acceso a la Galería:**

#### **Encontrar IP del Pi 3B+:**
```bash
hostname -I
# Output: 192.168.1.100
```

#### **Acceder desde Navegador:**
```
http://192.168.1.100:8080
```

### **📱 Funcionalidades Web:**

#### **🖼️ Galería de Imágenes:**
- ✅ **Vista de miniatura** de todas las imágenes
- ✅ **Vista completa** al hacer click
- ✅ **Ordenamiento** por fecha/nombre
- ✅ **Filtros** por periodo de tiempo
- ✅ **Descarga** individual o en lote

#### **📊 Panel de Control:**
- ✅ **Estadísticas** del sistema
- ✅ **Captura remota** via web
- ✅ **Configuración** de parámetros
- ✅ **Estado UART** en tiempo real
- ✅ **Logs** del sistema

#### **🔧 Configuración Web:**
- ✅ **Intervalo** de captura automática
- ✅ **Calidad y resolución** por defecto
- ✅ **Backup automático** enable/disable
- ✅ **Cleanup** automático de imágenes

### **🛡️ Seguridad Web:**
```bash
# Configurar autenticación (opcional)
nano config/raspberry_pi/config.json
# Modificar sección "security"
```

## 💾 **Gestión de Almacenamiento**

### **📁 Estructura de Directorios:**
```
~/foto-uart-dropin/data/
├── images/
│   ├── received/           # Imágenes recibidas desde Pi Zero W
│   ├── processed/          # Imágenes post-procesadas (opcional)
│   └── backup/             # Backup local antes de limpiar
├── logs/                   # Logs del sistema
└── temp/                   # Archivos temporales
```

### **🧹 Limpieza Automática:**

#### **Configuración:**
```json
// En config/raspberry_pi/config.json
{
  "pi3b_commander": {
    "auto_cleanup": true,
    "max_images": 500,
    "cleanup_interval_hours": 24
  }
}
```

#### **Limpieza Manual:**
```bash
# Limpiar imágenes antiguas (mantener 100 más recientes)
foto-uart-commander --cleanup --keep 100

# Limpiar por fecha (mantener últimos 7 días)
foto-uart-commander --cleanup --days 7

# Ver qué se eliminará sin borrar
foto-uart-commander --cleanup --dry-run
```

### **💿 Backup a USB:**

#### **Configuración Automática:**
```bash
# Instalar con backup USB
./scripts/setup/install_pi3b.sh --backup-usb
```

#### **Backup Manual:**
```bash
# Ejecutar backup inmediato
~/foto-uart-dropin/scripts/backup_to_usb.sh

# Ver log de backups
tail -f ~/foto-uart-dropin/data/logs/usb_backup.log
```

#### **Configurar Dispositivo USB:**
```bash
# Encontrar dispositivo USB
lsblk

# Montar USB manualmente
sudo mkdir -p /media/usb
sudo mount /dev/sda1 /media/usb

# Configurar automount (opcional)
echo "/dev/sda1 /media/usb auto defaults,user,rw 0 0" | sudo tee -a /etc/fstab
```

## 🔧 **Configuración Avanzada**

### **⚙️ Archivo de Configuración:**
```bash
# Editar configuración principal
nano ~/foto-uart-dropin/config/raspberry_pi/config.json
```

#### **🎛️ Parámetros Principales:**
```json
{
  "serial": {
    "puerto": "/dev/ttyS0",
    "baudrate": 115200,
    "timeout": 30,
    "retry_attempts": 3
  },
  "imagen": {
    "ancho_default": 1024,
    "calidad_default": 6,
    "chunk_size": 256,
    "ack_timeout": 15
  },
  "pi3b_commander": {
    "enabled": true,
    "max_images": 500,
    "auto_cleanup": true,
    "web_gallery_enabled": true,
    "web_gallery_port": 8080,
    "continuous_mode": false,
    "capture_interval_seconds": 300
  }
}
```

### **🔄 Servicios Systemd:**

#### **Servicio Principal:**
```bash
# Estado del servicio
sudo systemctl status foto-uart-pi3b-commander.service

# Iniciar/detener servicio
sudo systemctl start foto-uart-pi3b-commander.service
sudo systemctl stop foto-uart-pi3b-commander.service

# Ver logs del servicio
sudo journalctl -u foto-uart-pi3b-commander.service -f
```

#### **Configuración del Servicio:**
```bash
# Editar configuración del servicio
sudo nano /etc/systemd/system/foto-uart-pi3b-commander.service

# Recargar después de cambios
sudo systemctl daemon-reload
sudo systemctl restart foto-uart-pi3b-commander.service
```

### **📡 Configuración UART:**

#### **Verificar UART:**
```bash
# Estado del puerto
ls -la /dev/ttyS0

# Permisos correctos
sudo chmod 666 /dev/ttyS0

# Test básico
python3 -c "import serial; s=serial.Serial('/dev/ttyS0', 115200, timeout=1); print('UART OK'); s.close()"
```

#### **Optimizar UART:**
```bash
# Verificar configuración
grep enable_uart /boot/config.txt

# Verificar que no hay console serial
grep console /boot/cmdline.txt

# Deshabilitar servicios conflictivos
sudo systemctl disable serial-getty@ttyS0.service
```

## 📈 **Performance y Optimización**

### **⚡ Métricas de Performance:**

#### **Test de Velocidad:**
```bash
# Test completo de transferencia
foto-uart-commander --test-speed

# Output ejemplo:
# 🧪 Test de Velocidad UART:
#    📏 Imagen test: 64KB
#    ⏱️  Tiempo total: 8.3s
#    📊 Velocidad: 7.7 KB/s
#    ✅ Latencia promedio: 120ms
```

#### **Monitoreo Continuo:**
```bash
# Stats en tiempo real durante captura continua
foto-uart-commander --continuous --interval 60 --stats

# Output:
# [14:30:15] 📸 Captura #15: 1024x768, 8.2s, 7.8KB/s ✅
# [14:31:15] 📸 Captura #16: 1024x768, 7.9s, 8.1KB/s ✅
```

### **🔧 Optimizaciones:**

#### **Reducir Latencia:**
```json
// En configuración
{
  "imagen": {
    "chunk_size": 128,        // Chunks más pequeños
    "ack_timeout": 10         // Timeout más corto
  }
}
```

#### **Mejorar Throughput:**
```json
// Para conexiones estables
{
  "imagen": {
    "chunk_size": 512,        // Chunks más grandes
    "ack_timeout": 20         // Timeout más largo
  }
}
```

#### **Modo Performance:**
```bash
# Deshabilitar servicios innecesarios
sudo systemctl disable bluetooth hciuart

# Configurar CPU governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## 🛠️ **Troubleshooting**

### **❌ Problemas Comunes:**

#### **1. "No se puede conectar a Pi Zero W"**
```bash
# Diagnóstico
python3 tests/uart_ping_test.py sender

# Soluciones:
sudo chmod 666 /dev/ttyS0                    # Permisos
sudo systemctl disable serial-getty@ttyS0    # Console serial
# Verificar conexiones físicas GPIO 14/15
```

#### **2. "Imágenes corruptas o incompletas"**
```bash
# Reducir baudrate
nano config/raspberry_pi/config.json
# "baudrate": 57600

# Aumentar timeouts
# "ack_timeout": 20
# "timeout": 45
```

#### **3. "Web gallery no accesible"**
```bash
# Verificar nginx
sudo systemctl status nginx

# Reiniciar servicios web
sudo systemctl restart nginx
sudo systemctl restart foto-uart-pi3b-commander.service

# Verificar puerto
netstat -tlnp | grep :8080
```

#### **4. "Almacenamiento lleno"**
```bash
# Verificar espacio
df -h ~/foto-uart-dropin/data

# Limpieza manual
foto-uart-commander --cleanup --keep 50

# Habilitar auto-cleanup
nano config/raspberry_pi/config.json
# "auto_cleanup": true
```

### **🔍 Diagnóstico Avanzado:**

#### **Test Completo del Sistema:**
```bash
# Diagnóstico integral
python3 tools/system_diagnostics.py

# Test específico Pi 3B+
python3 tests/test_pi3b_commander.py

# Verificar integridad de archivos
python3 tools/verify_image_integrity.py
```

#### **Logs Detallados:**
```bash
# Habilitar debug logging
export FOTO_UART_DEBUG=1
foto-uart-commander --verbose

# Analizar patterns de error
grep -A 5 -B 5 "ERROR" ~/foto-uart-dropin/data/logs/*.log
```

## 🚀 **Casos de Uso Avanzados**

### **📹 Sistema Timelapse:**
```bash
# Captura cada 30 segundos durante 24 horas
foto-uart-commander --continuous --interval 30 --duration 86400

# Generar video desde imágenes
cd ~/foto-uart-dropin/data/images/received
ffmpeg -r 30 -pattern_type glob -i '*.jpg' -c:v libx264 -pix_fmt yuv420p timelapse.mp4
```

### **🔔 Integración con Webhooks:**
```json
// En configuración
{
  "notifications": {
    "enabled": true,
    "webhook_on_capture": true,
    "webhook_url": "https://tu-servidor.com/webhook"
  }
}
```

### **☁️ Upload Automático a Cloud:**
```bash
# Script post-captura personalizado
nano ~/foto-uart-dropin/scripts/post_capture_hook.sh

#!/bin/bash
# Upload automático a cloud
IMAGE_PATH="$1"
METADATA_PATH="$2"

# Subir a Google Drive, Dropbox, etc.
rclone copy "$IMAGE_PATH" gdrive:fotos/
```

### **📊 API REST:**
```bash
# Endpoint disponibles (si web gallery habilitada)
curl http://localhost:8080/api/status          # Estado del sistema
curl http://localhost:8080/api/images          # Lista de imágenes
curl http://localhost:8080/api/capture         # Captura remota
curl http://localhost:8080/api/stats           # Estadísticas
```

## 🎯 **Mejores Prácticas**

### **🔧 Configuración Óptima:**
- ✅ **Usar intervalos** ≥ 60 segundos para captura continua
- ✅ **Habilitar auto-cleanup** para gestión automática de espacio
- ✅ **Configurar backup USB** para redundancia
- ✅ **Monitorear logs** regularmente
- ✅ **Testear conectividad** UART periódicamente

### **💾 Gestión de Datos:**
- ✅ **Backup regular** a almacenamiento externo
- ✅ **Limpieza programada** de imágenes antiguas
- ✅ **Verificación integridad** de archivos
- ✅ **Monitoreo espacio** en disco

### **🛡️ Seguridad:**
- ✅ **Cambiar puertos** por defecto si es necesario
- ✅ **Configurar firewall** para acceso web
- ✅ **Actualizar sistema** regularmente
- ✅ **Backup configuraciones** importantes

---

¡Tu Pi 3B+ Commander está listo para uso profesional! 🚀📸
