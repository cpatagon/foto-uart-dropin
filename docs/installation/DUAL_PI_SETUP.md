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
Pi Zero W                     Pi 3B+
┌─────────┐                  ┌─────────┐
│ GPIO 14 │────────────────►│ GPIO 15 │ (TX Zero → RX Pi3B+)
│ GPIO 15 │◄────────────────│ GPIO 14 │ (RX Zero ← TX Pi3B+)
│   GND   │────────────────►│   GND   │ (Tierra común)
└─────────                    ─────────
