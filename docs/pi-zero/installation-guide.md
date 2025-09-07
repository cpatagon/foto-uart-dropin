# Guía de Instalación Pi Zero W

## Preparación del Hardware

### 1. Configurar Pi Zero W
```bash
# Habilitar cámara y UART
sudo raspi-config
# Interface Options > Camera > Enable
# Interface Options > Serial Port > Enable UART, Disable login shell
```

### 2. Configurar WiFi
```bash
# Si no está configurado durante la instalación del OS
sudo raspi-config
# System Options > Wireless LAN
```

## Instalación Automática

```bash
# Instalación básica
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash

# Instalación completa con servicios
curl -sSL https://raw.githubusercontent.com/cpatagon/foto-uart-dropin/main/scripts/setup/install_pi_zero.sh | bash -s -- --auto-update --service --performance-mode
```

## Instalación Manual

### 1. Clonar Repositorio
```bash
git clone https://github.com/cpatagon/foto-uart-dropin.git
cd foto-uart-dropin
```

### 2. Ejecutar Script
```bash
chmod +x scripts/setup/install_pi_zero.sh
./scripts/setup/install_pi_zero.sh --auto-update --service
```

### 3. Verificar Instalación
```bash
./scripts/setup/verify_pi_zero.sh
foto-uart-performance-test
```

## Post-Instalación

### Configurar Hardware
1. Conectar cámara al puerto CSI
2. Conectar ESP32 a GPIO 14/15 (UART)
3. Verificar conexiones con multímetro

### Verificar Funcionamiento
```bash
# Test básico
foto-uart-test

# Monitor en tiempo real
foto-uart-monitor

# Ejecutar servidor
sudo systemctl start foto-uart-pi-zero.service
sudo systemctl status foto-uart-pi-zero.service
```

## Troubleshooting

### Problemas Comunes

1. **Cámara no detectada**
   ```bash
   # Verificar conexión
   libcamera-hello --list-cameras
   
   # Verificar configuración
   grep camera /boot/config.txt
   ```

2. **UART no funciona**
   ```bash
   # Verificar configuración
   grep enable_uart /boot/config.txt
   
   # Test de loopback
   minicom -D /dev/ttyAMA0 -b 115200
   ```

3. **Memoria insuficiente**
   ```bash
   # Verificar uso de memoria
   free -h
   
   # Ajustar configuración
   nano config/raspberry_pi/config_pi_zero.json
   # Reducir ancho_default a 640
   ```
