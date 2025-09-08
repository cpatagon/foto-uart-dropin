# 📸 FotoUART Drop-in System v2.0

[![Tests](https://github.com/cpatagon/foto-uart-dropin/workflows/Tests/badge.svg)](https://github.com/cpatagon/foto-uart-dropin/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Raspberry Pi](https://img.shields.io/badge/hardware-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)

Sistema profesional de captura, transmisión y almacenamiento de imágenes con soporte para **múltiples configuraciones** de hardware Raspberry Pi y ESP32.

## 🎯 **Configuraciones Soportadas**

### **🔥 NUEVO: Sistema Dual Raspberry Pi**
- **📸 Raspberry Pi Zero W**: Captura de imágenes optimizada
- **📡 Raspberry Pi 3B+**: Comando via UART + Almacenamiento robusto
- **🔗 Comunicación**: UART bidireccional @ 115200 bps
- **⚡ Performance**: ~12s captura + transferencia completa

### **🚀 Sistema Original ESP32** 
- **📸 Raspberry Pi Zero W**: Captura y procesamiento
- **📡 ESP32 + SIM7600**: Transmisión LTE + almacenamiento SD
- **🔗 Comunicación**: UART + HTTP upload

### **🔧 Sistema Híbrido**
- **📸 Pi Zero W + Pi 3B+ + ESP32**: Máxima flexibilidad y redundancia

---

## ⚡ **Instalación Rápida**

### **🛠️ Sistema Dual Pi (RECOMENDADO):**

#### **Setup Automático Completo:**
```bash
# Una sola línea instala todo el sistema dual
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/setup_dual_pi_system.sh | bash
```

#### **Setup Individual por Dispositivo:**

**En Pi Zero W (Captura):**
```bash
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash -s -- --auto-update --service
```

**En Pi 3B+ (Commander + Storage):**
```bash
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi3b.sh | bash -s -- --web-gallery --auto-start
```

### **🔌 Conexiones Físicas:**
```
Pi Zero W GPIO 14 (TX) ↔ Pi 3B+ GPIO 15 (RX)
Pi Zero W GPIO 15 (RX) ↔ Pi 3B+ GPIO 14 (TX)  
Pi Zero W GND        ↔ Pi 3B+ GND
```

---

## 📊 **Performance del Sistema Dual Pi**

| Operación | Tiempo | Memoria RAM | Dispositivo |
|-----------|--------|-------------|-------------|
| Comando UART | ~100ms | +5MB | Pi 3B+ |
| Captura 800px | 2-3s | ~180MB | Pi Zero W |
| Transferencia 64KB | 8-10s | +20MB | Ambas |
| Almacenamiento | ~500ms | +10MB | Pi 3B+ |
| **TOTAL** | **~12s** | **~230MB** | **Sistema** |

---

## 🚀 **Uso del Sistema**

### **📱 Comandos Principales:**

#### **Pi Zero W** (Automático):
```bash
# Se ejecuta automáticamente como servicio
# O manualmente:
python3 src/raspberry_pi/foto_uart.py
```

#### **Pi 3B+** (Commander):
```bash
# Captura única
foto-uart-commander

# Con parámetros específicos  
foto-uart-commander --width 1024 --quality 8

# Modo continuo (cada 5 minutos)
foto-uart-commander --continuous --interval 300

# Ver imágenes almacenadas
foto-uart-commander --info
```

### **🌐 Web Gallery** (Si habilitada):
```bash
# Acceder desde navegador
http://[IP-de-Pi3B+]:8080
```

### **📊 Monitoreo:**
```bash
# Monitor en tiempo real
foto-uart-monitor-pi3b

# Información del sistema
foto-uart-info
```

---

## 🛠️ **Casos de Uso**

### **🏠 Vigilancia Doméstica:**
```bash
# Captura automática cada hora
foto-uart-commander --continuous --interval 3600
```

### **📹 Sistema Timelapse:**
```bash
# Captura cada 30 segundos
foto-uart-commander --continuous --interval 30
```

### **🔔 Detección de Eventos:**
```bash
# Trigger por script externo
foto-uart-commander --trigger-external motion_detector.py
```

### **☁️ Backup Automático:**
```bash
# Si instalado con --backup-usb
# Backup diario automático a USB
```

---

## 📋 **Características Principales**

### **🔧 Sistema Dual Pi:**
- ✅ **Protocolo UART robusto** (READY/ACK/DONE)
- ✅ **Optimización por hardware** (Pi Zero W + Pi 3B+) 
- ✅ **Almacenamiento centralizado** en Pi 3B+
- ✅ **Web gallery integrada** para acceso remoto
- ✅ **Auto-actualización** preservando configuraciones
- ✅ **Backup automático** a USB
- ✅ **Monitoreo en tiempo real**
- ✅ **API REST** para integración

### **⚡ Optimizaciones Pi Zero W:**
- 🎯 **Resolución por defecto**: 800px (optimizada)
- 🎯 **Chunk size**: 128 bytes (eficiente)
- 🎯 **Límite imagen**: 64KB (transferencia rápida)
- 🎯 **GPU Memory**: 128MB (configurado automáticamente)
- 🎯 **Auto-cleanup**: Gestión inteligente de memoria

### **💾 Almacenamiento Pi 3B+:**
- 🗂️ **Storage robusto**: 1GB+ RAM disponible
- 🗂️ **Auto-organización**: Por timestamp y metadata
- 🗂️ **Backup automático**: USB y cloud-ready
- 🗂️ **Web interface**: Galería y control remoto
- 🗂️ **API access**: Integración con sistemas externos

---

## 📖 **Documentación Completa**

- **[🔗 Guía Setup Sistema Dual Pi](docs/DUAL_PI_SETUP.md)**: Configuración paso a paso
- **[📡 Manual Pi 3B+ Commander](docs/PI3B_COMMANDER_GUIDE.md)**: Uso avanzado
- **[🔧 Troubleshooting UART](docs/UART_TROUBLESHOOTING.md)**: Solución de problemas
- **[⚡ Optimización Pi Zero W](docs/PI_ZERO_PERFORMANCE.md)**: Performance tuning
- **[🌐 Web Gallery Setup](docs/WEB_GALLERY_GUIDE.md)**: Interface web

---

## 🧪 **Testing y Diagnóstico**

### **🔍 Test Comunicación UART:**
```bash
# Test ping-pong entre Pi
python3 tests/uart_ping_test.py sender      # En Pi 3B+
python3 tests/uart_ping_test.py receiver    # En Pi Zero W
```

### **📊 Test Performance:**
```bash
# Test velocidad transferencia
foto-uart-commander --test-speed

# Test calidad imagen
python3 tests/test_image_quality.py
```

### **🔧 Diagnóstico Sistema:**
```bash
# Diagnóstico completo
python3 tools/system_diagnostics.py

# Test hardware
python3 tools/hardware_test.py
```

---

## 🏗️ **Arquitectura del Sistema**

```
                    Sistema Dual Pi
                    ===============

┌─────────────────┐    UART     ┌─────────────────┐
│   Pi Zero W     │◄──────────►│   Pi 3B+        │
│                 │  115200bps  │                 │
│ 📸 Captura      │             │ 📡 Commander    │
│ 🔧 Procesa      │             │ 💾 Storage      │
│ 📤 Transmite    │             │ 🌐 Web Gallery  │
│                 │             │ ☁️  Backup      │
└─────────────────┘             └─────────────────┘
      512MB RAM                       1GB RAM
      ARM11 CPU                    Cortex-A53 CPU
```

### **🔄 Flujo de Datos:**
1. **Pi 3B+** envía comando `foto` via UART
2. **Pi Zero W** captura y procesa imagen
3. **Pi Zero W** transmite imagen via protocolo READY/ACK/DONE
4. **Pi 3B+** almacena imagen con metadata
5. **Web Gallery** disponible para acceso remoto
6. **Backup automático** a USB (opcional)

---

## 🛡️ **Compatibilidad y Requisitos**

### **📱 Hardware Soportado:**
- ✅ **Raspberry Pi Zero W** (captura optimizada)
- ✅ **Raspberry Pi 3B+** (comando/storage)
- ✅ **Raspberry Pi 4** (compatible con scripts Pi 3B+)
- ✅ **ESP32 + SIM7600** (sistema original)

### **💻 Software:**
- ✅ **Raspberry Pi OS** (recomendado)
- ✅ **Python 3.8+** (incluido en Pi OS)
- ✅ **Picamera2** (cámara moderna)
- ✅ **Flask** (web gallery opcional)

### **🔌 Conexiones:**
- ✅ **UART** (GPIO 14/15)
- ✅ **Cámara Pi** (CSI)
- ✅ **WiFi** (Pi Zero W)
- ✅ **USB** (backup opcional)

---

## 🤝 **Contribuir**

### **🔧 Desarrollo:**
```bash
# Clonar repositorio
git clone https://github.com/cpatagon/foto-uart-dropin.git
cd foto-uart-dropin

# Setup desarrollo
./scripts/setup/setup_development.sh

# Ejecutar tests
python3 -m pytest tests/

# Verificar código
black src/ tests/
flake8 src/ tests/
```

### **📝 Contribuciones Bienvenidas:**
- 🆕 **Nuevas configuraciones** de hardware
- ⚡ **Optimizaciones** de performance  
- 🐛 **Bug fixes** y mejoras
- 📖 **Documentación** y ejemplos
- 🧪 **Tests** y validación

---

## 📄 **Licencia**

Este proyecto está bajo la [Licencia MIT](LICENSE) - ver archivo para detalles.

---

## 🏆 **Versiones**

- **v2.0.0**: Sistema Dual Pi + Pi 3B+ Commander + Web Gallery
- **v1.5.0**: Optimizaciones Pi Zero W + Auto-actualización  
- **v1.0.0**: Sistema original Pi Zero W + ESP32

---

## 📞 **Soporte**

- **🐛 Issues**: [GitHub Issues](https://github.com/cpatagon/foto-uart-dropin/issues)
- **💬 Discusiones**: [GitHub Discussions](https://github.com/cpatagon/foto-uart-dropin/discussions)
- **📖 Documentación**: [Wiki](https://github.com/cpatagon/foto-uart-dropin/wiki)

---

**¡Construye tu sistema de cámara profesional con Raspberry Pi! 📸🚀**
