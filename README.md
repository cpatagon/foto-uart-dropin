# 📸 FotoUART Drop-in System - Raspberry Pi Zero W Edition

[![Tests](https://github.com/cpatagon/foto-uart-dropin/workflows/Tests/badge.svg)](https://github.com/cpatagon/foto-uart-dropin/actions)
[![Pi Zero W Tests](https://github.com/cpatagon/foto-uart-dropin/workflows/Pi%20Zero%20W%20Tests/badge.svg)](https://github.com/cpatagon/foto-uart-dropin/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Raspberry Pi Zero W](https://img.shields.io/badge/hardware-Pi%20Zero%20W-red.svg)](https://www.raspberrypi.org/products/raspberry-pi-zero-w/)

Sistema profesional de captura y transmisión de imágenes **optimizado para Raspberry Pi Zero W** + ESP32 via UART con protocolo robusto de handshake.

## 🎯 **Optimizado para Raspberry Pi Zero W**

- **⚡ Rendimiento Optimizado**: Configuración específica para hardware limitado
- **📦 Instalación Ligera**: Dependencias mínimas y virtual environment eficiente  
- **🔧 Auto-Configuración**: Detección automática de Pi Zero W y optimizaciones
- **💾 Gestión de Memoria**: Límites inteligentes para 512MB RAM
- **🔄 Auto-Actualización**: Sistema de updates que preserva configuraciones

## ⚡ **Instalación Rápida para Pi Zero W**

```bash
# Instalación automática optimizada
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash

# Con servicios y auto-update
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash -s -- --auto-update --service
```

## 📊 **Rendimiento en Pi Zero W**

| Operación | Tiempo | Memoria RAM | CPU |
|-----------|--------|-------------|-----|
| Captura 800px | 2-3s | ~180MB | 85% |
| Transmisión 64KB | 8-10s | +20MB | 30% |
| **Total por foto** | **~12s** | **~230MB** | **Pico 90%** |

Para documentación completa, ver [DOCUMENTATION.md](DOCUMENTATION.md)
