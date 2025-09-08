# 🔗 Guía de Configuración Sistema Dual Pi

Sistema completo **Pi Zero W** (captura) + **Pi 3B+** (comando/almacenamiento) con comunicación UART.

## 🎯 **Visión General del Sistema**

```
┌─────────────────┐    UART     ┌─────────────────┐
│   Pi Zero W     │◄──────────►│   Pi 3B+        │
│                 │  115200bps  │                 │
│ 📸 Captura      │             │ 📡 Commander    │
│ 🔧 Procesa      │             │ 💾 Storage      │
│ 📤 Transmite    │             │ 🌐 Web Gallery  │
└─────────────────┘             └─────────────────┘
```

### **Roles de Cada Dispositivo:**

| Dispositivo | Función Principal | Recursos |
|-------------|-------------------|----------|
| **Pi Zero W** | 📸 Captura + Procesamiento | 512MB RAM, CPU limitado |
| **Pi 3B+** | 📡 Comando + 💾 Almacenamiento | 1GB RAM, CPU potente |

## ⚡ **Instalación Rápida**

### **🚀 Setup Automático Completo:**
```bash
# Descargar script de setup dual
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/setup_dual_pi_system.sh | bash
```

### **📋 Setup Manual Paso a Paso:**

#### **1. En Pi Zero W (Device de Captura):**
```bash
# Instalar Pi Zero W optimizado
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash -s -- --auto-update --service

# Verificar instalación
foto-uart-performance-test
```

#### **2. En Pi 3B+ (Commander + Storage):**
```bash
# Instalar Pi 3B+ commander
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b.sh | bash -s -- --web-gallery --auto-start

# Verificar instalación
foto-uart-info
```

## 🔌 **Conexiones Físicas**

### **Diagrama de Conexión:**
```
Pi Zero W                    Pi 3B+
┌─────────┐                 ┌─────────┐
│ GPIO 14 │────────────────►│ GPIO 15 │ (TX Zero → RX Pi3B+)
│ GPIO 15 │◄────────────────│ GPIO 14 │ (RX Zero ← TX Pi3B+)
│   GND   │────────────────►│   GND   │ (Tierra común)
└─────────┘                 └─────────┘
```

### **⚠️ Conexiones Críticas:**
- **TX Zero (GPIO 14) → RX Pi3B+ (GPIO 15)**
- **RX Zero (GPIO 15) ← TX Pi3B+ (GPIO 14)**  
- **GND común entre ambas Pi**
- **Usar cables cortos y de calidad**

### **🔧 Verificación de Conexiones:**
```bash
# En ambas Pi, verificar puertos UART
ls -la /dev/ttyS0

# Test de continuidad (con multímetro)
# GPIO 14 Zero ↔ GPIO 15 Pi3B+ = 0Ω
# GPIO 15 Zero ↔ GPIO 14 Pi3B+ = 0Ω
# GND Zero ↔ GND Pi3B+ = 0Ω
```

## 🚀 **Configuración y Uso**

### **🔧 Configuración UART (Automática en Scripts)**

#### **En ambas Pi:**
```bash
# Habilitar UART
sudo raspi-config
# Interface Options > Serial Port > Enable UART: YES
# Enable login shell over serial: NO

# Verificar configuración
grep enable_uart /boot/config.txt  # Debe mostrar: enable_uart=1
grep console /boot/cmdline.txt     # NO debe mostrar console=serial0
```

### **📱 Uso del Sistema Dual Pi**

#### **1. Iniciar Pi Zero W (Receptor):**
```bash
# En Pi Zero W
cd ~/foto-uart-dropin
python3 src/raspberry_pi/foto_uart.py

# Output esperado:
# 📷 Pi Zero W - Cámara Final
# 👂 Esperando comandos...
```

#### **2. Comandar desde Pi 3B+ (Commander):**
```bash
# En Pi 3B+ - Captura única
foto-uart-commander

# Con parámetros específicos
foto-uart-commander --width 800 --quality 7

# Modo continuo (cada 5 minutos)
foto-uart-commander --continuous --interval 300

# Ver información de almacenamiento
foto-uart-commander --info
```

## 📊 **Rendimiento del Sistema Dual**

### **📈 Métricas de Performance:**

| Operación | Tiempo | Pi Zero W | Pi 3B+ | Total |
|-----------|--------|-----------|--------|-------|
| Comando UART | ~100ms | - | 📡 | 100ms |
| Captura + Proceso | 2-3s | 📸 | - | 2-3s |
| Transferencia 64KB | 8-10s | 📤 | 📥 | 8-10s |
| Almacenamiento | ~500ms | - | 💾 | 500ms |
| **TOTAL** | **~12s** | **3s** | **9s** | **12s** |

### **💾 Uso de Recursos:**

| Dispositivo | RAM | CPU | Storage | Red |
|-------------|-----|-----|---------|-----|
| **Pi Zero W** | ~230MB | ~90% | Temporal | UART |
| **Pi 3B+** | ~150MB | ~30% | Permanente | UART + WiFi |

## 🌐 **Web Gallery (Opcional)**

Si instalaste con `--web-gallery`:

### **📱 Acceso Web:**
```bash
# URL de acceso
http://[IP-de-Pi3B+]:8080

# Encontrar IP de Pi 3B+
hostname -I
```

### **🖼️ Funciones Web:**
- ✅ **Galería de imágenes** capturadas
- ✅ **Metadata** de cada captura  
- ✅ **Control remoto** de capturas
- ✅ **Estadísticas** del sistema
- ✅ **Descarga** de imágenes

## 🔧 **Troubleshooting**

### **❌ Problema: "Sin respuesta UART"**

#### **Diagnóstico:**
```bash
# En ambas Pi
sudo chmod 666 /dev/ttyS0
python3 uart_ping_test.py sender    # En Pi 3B+
python3 uart_ping_test.py receiver  # En Pi Zero W
```

#### **Soluciones:**
1. **Verificar permisos UART**
2. **Revisar conexiones físicas**
3. **Reiniciar ambas Pi**
4. **Verificar configuración UART**

### **❌ Problema: "Imágenes corruptas"**

#### **Síntomas:** Caracteres extraños en lugar de imágenes
#### **Solución:** Reducir baudrate
```bash
# En configuración, cambiar de 115200 a 57600
nano config/raspberry_pi/config.json
# "baudrate": 57600
```

### **❌ Problema: "Pi Zero W no responde"**

#### **Diagnóstico:**
```bash
# Verificar que no hay console serial activo
sudo systemctl status serial-getty@ttyS0.service
# Debe estar: inactive/disabled
```

#### **Solución:**
```bash
sudo systemctl disable serial-getty@ttyS0.service
sudo systemctl mask serial-getty@ttyS0.service
sudo reboot
```

## 📋 **Comandos de Monitoreo**

### **🔍 Monitor Sistema Completo:**
```bash
# En Pi 3B+ - Monitor integrado
foto-uart-monitor-pi3b

# Output:
# === Monitor Pi 3B+ Commander ===
# ✅ UART: /dev/ttyS0 disponible
# 💾 Almacenamiento: 15GB disponible
# 📷 Imágenes: 42
# 🖥️  RAM: 120MB/1GB
```

### **📊 Estadísticas Detalladas:**
```bash
# Info completa del sistema
foto-uart-info

# Logs en tiempo real
tail -f ~/foto-uart-dropin/data/logs/*.log

# Test de velocidad
foto-uart-commander --test-speed
```

## 🔄 **Automatización**

### **⏰ Captura Automática:**
```bash
# Cron para captura cada hora
(crontab -l; echo "0 * * * * /home/pi/.local/bin/foto-uart-commander") | crontab -

# Servicio systemd (si instalado con --auto-start)
sudo systemctl start foto-uart-pi3b-commander.service
sudo systemctl enable foto-uart-pi3b-commander.service
```

### **💾 Backup Automático:**
```bash
# Si instalado con --backup-usb
# Backup diario automático a USB a las 2:00 AM
# Ver logs: ~/foto-uart-dropin/data/logs/usb_backup.log
```

## 🎯 **Casos de Uso Avanzados**

### **📹 Sistema de Timelapse:**
```bash
# Captura cada 30 segundos
foto-uart-commander --continuous --interval 30

# Generar video desde imágenes
ffmpeg -r 30 -pattern_type glob -i '*.jpg' -c:v libx264 timelapse.mp4
```

### **🔔 Detección de Movimiento:**
```bash
# Con integración externa
foto-uart-commander --trigger-external /path/to/motion_detector.py
```

### **☁️ Upload Automático:**
```bash
# Script personalizado post-captura
foto-uart-commander --post-capture-script /path/to/upload_cloud.sh
```

## 📈 **Escalabilidad**

### **🔗 Sistema Multi-Pi:**
- **1x Pi 3B+ Commander** puede controlar **múltiples Pi Zero W**
- **Protocolo UART** soporta direccionamiento
- **Web Gallery** centralizada

### **🌐 Integración Cloud:**
- **API REST** en Pi 3B+ para integración
- **Webhooks** para notificaciones
- **MQTT** para IoT integration

## 🏆 **Ventajas del Sistema Dual Pi**

✅ **Especialización:** Cada Pi optimizada para su función  
✅ **Escalabilidad:** Fácil agregar más Pi Zero W  
✅ **Redundancia:** Almacenamiento centralizado robusto  
✅ **Flexibilidad:** Control remoto y automatización  
✅ **Costo-Eficiencia:** Uso óptimo de recursos de hardware  
✅ **Mantenimiento:** Updates y configuración centralizados  

¡Tu sistema dual Pi está listo para casos de uso profesionales! 🚀
