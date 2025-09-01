# FOTO-UART-DROPIN

**Sistema de Captura de Imágenes Compatible por UART**

Un sistema drop-in replacement para captura, procesamiento y transmisión de imágenes via protocolo UART, diseñado para mantener compatibilidad total con receptores ESP32 existentes.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Protocolo de Comunicación](#protocolo-de-comunicación)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [Casos de Prueba](#casos-de-prueba)
- [Troubleshooting](#troubleshooting)
- [Contribución](#contribución)
- [Licencia](#licencia)

## 🎯 Características

### Principales
- **Compatibilidad total** con sistemas ESP32 existentes
- **Protocolo UART robusto** con handshake READY/ACK/DONE
- **Captura de alta resolución** con Camera Module 3 Wide (IMX708)
- **Procesamiento automático** de imágenes (CLAHE, Unsharp Mask)
- **Transmisión por chunks** de 256 bytes para eficiencia de memoria
- **Reintentos automáticos** ante fallos de transmisión
- **Configuración JSON** flexible

### Técnicas
- **Puerto UART**: 115200 baudios, 8N1
- **Formatos soportados**: JPEG con calidad configurable (10-100)
- **Resoluciones**: Desde 100px hasta 4608px de ancho
- **Tiempo de respuesta**: < 5 segundos comando a header
- **Almacenamiento**: Original full-res + versión procesada

## 🏗️ Arquitectura del Sistema

```
┌─────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────┐
│ Cámara  │───▶│  Procesador  │◄──▶│Almacenamiento│    │ ESP32   │
│ CM3/USB │    │  de Imagen   │    │    Local     │    │Receptor │
└─────────┘    └──────┬───────┘    └──────────────┘    └────▲────┘
                      │                                      │
                      ▼                                      │
               ┌─────────────┐                               │
               │ Interfaz    │──────────────────────────────┘
               │    UART     │
               └─────────────┘
```

## 📡 Protocolo de Comunicación

### Secuencia Completa

```
ESP32/PC          UART            Raspberry Pi
    │               │                   │
    ├─ "foto\n" ────▶│──────────────────▶│
    │               │                   ├─ Captura imagen
    │               │                   ├─ Procesa imagen
    │               │                   ├─ Redimensiona
    │◄─ Header ──────│◄──────────────────┤
    │   "YYYYMMDD_HHMMSS|size\n"        │
    ├─ "READY\n" ───▶│──────────────────▶│
    │◄─ [256 bytes] ─│◄──────────────────┤
    ├─ "ACK\n" ─────▶│──────────────────▶│
    │◄─ [256 bytes] ─│◄──────────────────┤
    │    (repetir)    │        ...        │
    ├─ "DONE\n" ────▶│──────────────────▶│
    │               │                   │
```

### Comandos Soportados

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `foto` | Captura con configuración por defecto | `foto\n` |
| `foto [ancho]` | Captura con ancho específico | `foto 800\n` |
| `foto [ancho] [calidad]` | Captura con ancho y calidad | `foto 1200 7\n` |

**Parámetros:**
- **Ancho**: 100-4608 píxeles (default: 1024)
- **Calidad**: 1-10 (mapeado a JPEG 10-100, default: 5)

## 🚀 Instalación

### Requisitos del Sistema

#### Raspberry Pi
```bash
# Habilitar cámara
sudo raspi-config
# Interface Options → Camera → Enable

# Instalar dependencias
sudo apt update
sudo apt install -y python3-picamera2 python3-pil python3-opencv python3-serial
```

#### Verificación de Cámara
```bash
# Verificar detección
vcgencmd get_camera
# Debe mostrar: supported=1 detected=1, libcamera interfaces=1

# Prueba rápida
libcamera-still -n -o test.jpg --timeout 1000
```

### Configuración USB Gadget (opcional)

Para pruebas con PC via USB:

```bash
# Editar /boot/config.txt
echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt

# Editar /boot/cmdline.txt (agregar después de rootwait)
sudo sed -i 's/rootwait/rootwait modules-load=dwc2,g_serial/' /boot/cmdline.txt

# Agregar módulos
echo "dwc2" | sudo tee -a /etc/modules
echo "g_serial" | sudo tee -a /etc/modules

# Reiniciar
sudo reboot
```

### Instalación del Software

```bash
# Clonar repositorio
git clone https://github.com/usuario/foto-uart-dropin.git
cd foto-uart-dropin

# Ejecutar script de instalación
chmod +x install.sh
./install.sh

# O instalación manual
pip3 install -r requirements.txt
```

## ⚙️ Configuración

### Archivo config.json

```json
{
  "serial": {
    "puerto": "/dev/ttyAMA0",
    "baudrate": 115200,
    "timeout": 1
  },
  "imagen": {
    "ancho_default": 1024,
    "calidad_default": 5,
    "chunk_size": 256,
    "ack_timeout": 10
  },
  "almacenamiento": {
    "directorio_fullres": "storage/fullres",
    "directorio_enhanced": "storage/enhanced",
    "mantener_originales": true
  },
  "procesamiento": {
    "aplicar_mejoras": true,
    "unsharp_mask": true,
    "clahe_enabled": true
  }
}
```

### Puertos Serie Comunes

| Sistema | Puerto | Descripción |
|---------|--------|-------------|
| Raspberry Pi | `/dev/ttyAMA0` | UART GPIO (pins 8/10) |
| Raspberry Pi | `/dev/serial0` | UART primario |
| Raspberry Pi | `/dev/ttyGS0` | USB Gadget mode |
| ESP32 | `Serial2` | UART2 (GPIO 16/17) |
| PC Linux | `/dev/ttyUSB0` | Adaptador USB-TTL |
| PC Windows | `COM3, COM4...` | Puerto COM |

## 📱 Uso

### Ejecución del Sistema

```bash
# Ejecución básica
python3 captura_serial.py

# Con puerto específico
python3 captura_serial.py --port /dev/ttyUSB0

# Con configuración personalizada
python3 captura_serial.py --config mi_config.json

# Modo debug
python3 captura_serial.py --debug
```

### Comandos desde ESP32

```cpp
// En el código ESP32
fileSerial.println("foto");           // Captura básica
fileSerial.println("foto 800");       // Ancho 800px
fileSerial.println("foto 1200 8");    // Ancho 1200px, calidad 80
```

### Comandos desde PC (testing)

```bash
# Usando screen
screen /dev/ttyACM0 115200

# Dentro de screen:
foto
foto 800 7

# Usando echo
echo "foto" > /dev/ttyACM0
```

## ✅ Casos de Prueba

### Verificación de Protocolo

```bash
# Test básico de compatibilidad
python3 test_protocolo.py --test basic

# Test con ESP32 real
python3 test_protocolo.py --test esp32 --port /dev/ttyAMA0

# Test de rendimiento
python3 test_protocolo.py --test performance

# Test de recuperación ante errores
python3 test_protocolo.py --test recovery
```

### Resultados Esperados

| Test | Entrada | Resultado Esperado |
|------|---------|-------------------|
| **Comando básico** | `foto\n` | Header válido + imagen 1024px |
| **Con parámetros** | `foto 800 7\n` | Header + imagen 800px, calidad 70 |
| **Timeout recovery** | Sin ACK por 10s | Reintento automático |
| **ESP32 real** | Protocolo completo | Imagen recibida en ESP32 |

## 🔧 Troubleshooting

### Problemas Comunes

#### Cámara no detectada
```bash
# Verificar detección
vcgencmd get_camera

# Si muestra supported=0 detected=0:
sudo raspi-config  # Habilitar cámara
sudo reboot

# Verificar conexión ribbon cable
sudo i2cdetect -y 1  # Debe mostrar dirección 1a
```

#### Puerto serie no disponible
```bash
# Verificar permisos
sudo usermod -a -G dialout $USER
# Logout y login nuevamente

# Verificar puertos disponibles
ls -la /dev/tty*
dmesg | grep tty
```

#### Timeouts en transmisión
```bash
# Verificar baudrate
stty -F /dev/ttyAMA0 115200

# Verificar conexión física
# GPIO 14 (TX) pin 8 -> ESP32 RX
# GPIO 15 (RX) pin 10 -> ESP32 TX
# GND pin 6 -> ESP32 GND
```

### Logs y Diagnóstico

```bash
# Ver logs del sistema
tail -f storage/logs/captura_$(date +%Y%m%d).log

# Diagnóstico completo
python3 diagnostico.py

# Test de conectividad
python3 test_conectividad.py --port /dev/ttyAMA0
```

## 📊 Especificaciones Técnicas

### Rendimiento
- **Tiempo de captura**: < 2 segundos
- **Tiempo total**: < 10 segundos (para imágenes ≤ 110KB)
- **Chunk size**: 256 bytes exactos
- **Timeout ACK**: 10 segundos
- **Reintentos**: 1 automático

### Formato de Imágenes
- **Entrada**: Resolución completa del sensor
- **Salida**: JPEG redimensionado y optimizado
- **Almacenamiento**: Original + procesada
- **Mejoras**: Unsharp Mask + CLAHE (opcional)

### Protocolo UART
- **Velocidad**: 115200 baudios
- **Formato**: 8N1 (8 bits, sin paridad, 1 stop bit)
- **Control de flujo**: Ninguno
- **Encoding**: UTF-8

## 🗂️ Estructura del Proyecto

```
foto-uart-dropin/
├── README.md                    # Este archivo
├── LICENSE                      # Licencia MIT
├── requirements.txt             # Dependencias Python
├── install.sh                   # Script de instalación
├── config.json                  # Configuración por defecto
├── src/
│   ├── captura_serial.py       # Script principal
│   ├── procesador_imagen.py    # Módulo de procesamiento
│   ├── protocolo_uart.py       # Manejo del protocolo
│   └── utils/
│       ├── diagnostico.py      # Herramientas de diagnóstico
│       └── logger.py           # Sistema de logging
├── tests/
│   ├── test_protocolo.py       # Tests del protocolo
│   ├── test_imagen.py          # Tests de procesamiento
│   └── emulador_esp32.py       # Emulador para testing
├── docs/
│   ├── protocolo.md            # Documentación del protocolo
│   ├── configuracion.md        # Guía de configuración
│   └── requerimientos.pdf      # Documento técnico completo
└── storage/
    ├── fullres/                # Imágenes originales
    ├── enhanced/               # Imágenes procesadas
    └── logs/                   # Logs del sistema
```

## 🤝 Contribución

### Desarrollo
1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -m 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Testing
```bash
# Ejecutar tests completos
python3 -m pytest tests/

# Test específico
python3 tests/test_protocolo.py

# Coverage
python3 -m pytest --cov=src tests/
```

### Requisitos para Pull Requests
- [ ] Tests pasan completamente
- [ ] Compatibilidad con ESP32 verificada
- [ ] Documentación actualizada
- [ ] Protocolo UART no modificado

## 📄 Documentación Técnica

### Especificaciones Completas
Ver [`docs/requerimientos.pdf`](docs/requerimientos.pdf) para:
- Especificaciones técnicas detalladas (IEEE 830-1998)
- Matriz de trazabilidad REQ → TEST
- Casos de prueba obligatorios
- Configuraciones de hardware soportadas

### Protocolos
Ver [`docs/protocolo.md`](docs/protocolo.md) para:
- Secuencia de handshake detallada
- Formato exacto de comandos y respuestas
- Manejo de errores y timeouts
- Ejemplos de implementación

## 🛠️ Configuración de Hardware

### Raspberry Pi + Camera Module 3
```bash
# /boot/config.txt
camera_auto_detect=1
dtparam=i2c_arm=on
gpu_mem=128
dtoverlay=imx708
```

### Conexión UART
```
Raspberry Pi      ESP32
GPIO 14 (TX) ──── RX (GPIO 16)
GPIO 15 (RX) ──── TX (GPIO 17)  
GND          ──── GND
```

### Configuración USB Gadget (testing)
```bash
# /boot/cmdline.txt
rootwait modules-load=dwc2,g_serial

# /etc/modules
dwc2
g_serial
```

## 📈 Casos de Uso

### Monitoreo Ambiental
- Captura automática cada hora
- Transmisión vía LTE con SIM7600
- Almacenamiento en servidor remoto

### Vigilancia Remota
- Activación por comando manual
- Transmisión inmediata
- Procesamiento local de imágenes

### Testing y Desarrollo
- Conexión USB directa PC ↔ Raspberry Pi
- Emulación ESP32 desde PC
- Validación de protocolo

## ⚡ Quick Start

### Para Raspberry Pi
```bash
# 1. Instalar
git clone https://github.com/usuario/foto-uart-dropin.git
cd foto-uart-dropin
./install.sh

# 2. Verificar cámara
vcgencmd get_camera

# 3. Ejecutar
python3 src/captura_serial.py

# 4. Desde otro terminal o ESP32
echo "foto" > /dev/ttyAMA0
```

### Para Testing con PC
```bash
# 1. Configurar USB gadget en Raspberry Pi
sudo ./setup_usb_gadget.sh
sudo reboot

# 2. En PC, detectar puerto
python3 tests/emulador_esp32.py

# 3. Enviar comando
➤ foto
```

## 📋 Requisitos del Sistema

### Hardware Mínimo
- **Raspberry Pi Zero W** o superior
- **Camera Module 3** (IMX708) o webcam USB compatible
- **Puerto UART** disponible o capacidad USB gadget
- **Tarjeta SD** 8GB+ (para almacenamiento de imágenes)

### Software
- **Raspberry Pi OS** (Bookworm recomendado)
- **Python 3.9+**
- **libcamera** instalado
- **Bibliotecas**: picamera2, PIL, OpenCV, pyserial

### Red (opcional)
- **WiFi/Ethernet** para configuración remota
- **LTE/SIM7600** para transmisión (si se usa con ESP32)

## 🔍 Verificación y Testing

### Test Rápido de Funcionamiento
```bash
# Verificar todo el stack
python3 tests/test_completo.py

# Resultado esperado:
✅ Cámara detectada y funcional
✅ Puerto UART disponible  
✅ Protocolo de handshake correcto
✅ Transmisión de imagen exitosa
✅ Almacenamiento local correcto
```

### Compatibilidad ESP32
```bash
# Con ESP32 real conectado
python3 tests/test_esp32_real.py --port /dev/ttyAMA0

# Debe mostrar:
📤 Comando enviado: foto
📨 Header recibido: 20250830_143052|87432
✅ Imagen transferida exitosamente
📁 Archivo guardado en ESP32: /1_20250830_143052.jpg
```

## 📊 Métricas de Performance

| Métrica | Valor | Condición |
|---------|-------|-----------|
| Tiempo captura | < 2s | Desde comando a inicio captura |
| Tiempo header | < 5s | Desde comando a envío header |
| Tiempo total | < 10s | Para imágenes ≤ 110KB |
| Throughput | ~23KB/s | A 115200 baudios con ACKs |
| Tasa de éxito | > 99% | En condiciones normales |

## 🐛 Conocidos Issues

### Limitaciones Actuales
- **Tamaño máximo eficiente**: ~110KB (por SLA de 10s)
- **Un reintento**: Sistema intenta solo una vez ante fallo
- **Single-threaded**: Un comando por vez
- **JPEG únicamente**: No soporta PNG/RAW

### Roadmap
- [ ] Soporte multi-threading para comandos concurrentes
- [ ] Compresión adaptativa según bandwidth
- [ ] Protocolos adicionales (I2C, SPI)
- [ ] Interfaz web para configuración remota

## 📞 Soporte

### Issues y Bug Reports
- Usar [GitHub Issues](https://github.com/usuario/foto-uart-dropin/issues)
- Incluir logs completos
- Especificar hardware utilizado
- Comandos exactos que fallan

### Contacto
- **Desarrollador**: Alejandro Rebolledo
- **Email**: contacto@ejemplo.com
- **Documentación**: [Wiki del proyecto](https://github.com/usuario/foto-uart-dropin/wiki)

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para detalles completos.

```
Copyright (c) 2025 Alejandro Rebolledo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

## 🙏 Reconocimientos

- **Proyecto original**: Basado en el sistema Raspberry Pi ↔ ESP32 desarrollado por Alejandro Rebolledo
- **Protocolo**: Compatible con especificaciones del proyecto WebCamRaspberryPi
- **Testing**: Centro de Investigación en Tecnologías para la Sociedad, UDD

---
