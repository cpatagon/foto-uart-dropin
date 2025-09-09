# 📷 Sistema UART Camera Drop-in

Sistema completo de control remoto de cámara via UART para Raspberry Pi Zero. Permite tomar fotografías mediante comandos serie con respuestas estructuradas y cambio dinámico de configuración.

## 🚀 Inicio Rápido

```bash
# 1. Clonar repositorio
git clone https://github.com/usuario/foto-uart-dropin.git
cd foto-uart-dropin

# 2. Instalar dependencias
sudo apt install python3-picamera2 python3-serial

# 3. Configurar UART
sudo ./scripts/setup/configurar_uart.sh

# 4. Ejecutar sistema
cd src/raspberry_pi
python3 camara_uart.py
```

## 📁 Estructura del Proyecto

```
foto-uart-dropin/
├── src/
│   ├── raspberry_pi/           # Código principal Pi Zero
│   │   ├── camara_uart.py     # Sistema UART Camera
│   │   └── models/            # Modelos de datos
│   ├── esp32/                 # Código para ESP32
│   ├── server/                # Servidor web (opcional)
│   └── shared/                # Código compartido
├── docs/                      # Documentación completa
│   ├── installation/          # Guías de instalación
│   ├── pi-zero/              # Documentación Pi Zero
│   └── troubleshooting/       # Resolución de problemas
├── examples/
│   └── basic_setup/           # Ejemplos de uso
├── scripts/
│   ├── setup/                 # Scripts de configuración
│   └── monitoring/            # Scripts de monitoreo
├── config/
│   └── raspberry_pi/          # Configuraciones Pi
├── tests/                     # Tests unitarios
└── README.md                  # Este archivo
```

## 🔧 Características Principales

- ✅ **Control UART bidireccional** - Comandos y respuestas estructuradas
- ✅ **Cambio dinámico de velocidad** - 9600 a 115200 baudios
- ✅ **Múltiples resoluciones** - Desde VGA hasta Full HD
- ✅ **Respuestas detalladas** - Incluye tamaño de archivo y rutas
- ✅ **Sistema robusto** - Manejo de errores y reconexión automática
- ✅ **Compatible Pi Zero** - Optimizado para recursos limitados

## 📡 Protocolo UART

### Comandos Disponibles

| Comando | Descripción | Ejemplo | Respuesta |
|---------|-------------|---------|-----------|
| `foto` | Toma fotografía | `foto` | `OK\|filename\|bytes\|path` |
| `estado` | Estado del sistema | `estado` | `STATUS:ACTIVO\|puerto\|velocidad` |
| `resolucion` | Consulta resolución | `resolucion` | `RESOLUCION\|WIDTHxHEIGHT\|MP` |
| `res:WxH` | Cambia resolución | `res:1920x1080` | `OK:Resolucion WxH` |
| `baudrate:SPEED` | Cambia velocidad | `baudrate:115200` | `BAUDRATE_CHANGED\|speed` |
| `salir` | Termina programa | `salir` | `CAMERA_OFFLINE` |

### Formato de Respuestas

```
# Inicio del sistema
CAMERA_READY

# Foto exitosa
OK|20250909_095246.jpg|117373|fotos/20250909_095246.jpg

# Estado del sistema
STATUS:ACTIVO|/dev/ttyS0|9600

# Resolución actual
RESOLUCION|1920x1080|2.1MP

# Cambio de velocidad
OK:Cambiando a 115200 en 3 segundos
BAUDRATE_CHANGED|115200

# Error
ERROR:mensaje descriptivo

# Cierre del sistema
CAMERA_OFFLINE
```

## 🔌 Configuración de Hardware

### Conexiones GPIO (Pi a Pi)
```
Pi con Cámara    ←→    Pi Controladora
GPIO 14 (TX)     ←→    GPIO 15 (RX)  [Pin 8 ←→ Pin 10]
GPIO 15 (RX)     ←→    GPIO 14 (TX)  [Pin 10 ←→ Pin 8]
GND              ←→    GND           [Pin 6 ←→ Pin 6]
```

### Adaptador USB-Serial
```
Adaptador USB    ←→    Pi con Cámara
TX               ←→    GPIO 15 (RX)  [Pin 10]
RX               ←→    GPIO 14 (TX)  [Pin 8]
GND              ←→    GND           [Pin 6]
```

## 💻 Uso del Sistema

### Desde Terminal (Método Simple)
```bash
# Tomar una foto
echo "foto" > /dev/ttyS0

# Ver estado del sistema
echo "estado" > /dev/ttyS0

# Consultar resolución
echo "resolucion" > /dev/ttyS0

# Cambiar resolución
echo "res:1280x720" > /dev/ttyS0

# Cambiar velocidad UART
echo "baudrate:115200" > /dev/ttyS0
sleep 3
stty -F /dev/ttyS0 115200
```

### Con Screen (Interactivo)
```bash
# Conectar
screen /dev/ttyS0 9600

# Enviar comandos
foto
estado
resolucion

# Salir: Ctrl+A, K, Y
```

### Con Script Automatizado
```bash
# Usar script incluido
./scripts/monitoring/enviar_comando.py foto
./scripts/monitoring/enviar_comando.py estado

# Cambiar velocidad
./scripts/setup/cambiar_velocidad.sh 115200
```

## 🛠️ Instalación Detallada

### 1. Preparar Raspberry Pi Zero

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y python3-pip python3-picamera2 python3-serial git

# Instalar pyserial si es necesario
sudo pip3 install pyserial
```

### 2. Configurar UART

```bash
# Método automático
sudo ./scripts/setup/configurar_uart.sh

# O método manual:
sudo nano /boot/config.txt
# Agregar: enable_uart=1
# Agregar: dtoverlay=disable-bt

sudo raspi-config
# Interface Options → Serial Port → No (shell) → Yes (interface)

sudo reboot
```

### 3. Verificar Configuración

```bash
# Verificar puerto UART
ls -la /dev/ttyS*

# Verificar permisos
sudo usermod -a -G dialout $USER

# Verificar cámara
libcamera-hello --list-cameras
```

### 4. Ejecutar Sistema

```bash
cd src/raspberry_pi
python3 camara_uart.py
```

## 📊 Ejemplos de Sesión

### Sesión Típica
```bash
$ python3 camara_uart.py
Sistema de cámara UART iniciado
Puerto: /dev/ttyS0, Baudrate: 9600
Directorio: fotos
🎯 Sistema listo. Esperando comandos...

# Desde otro terminal:
$ echo "foto" > /dev/ttyS0
$ echo "estado" > /dev/ttyS0
$ echo "resolucion" > /dev/ttyS0
```

### Respuestas del Sistema
```
CAMERA_READY
OK|20250909_143025.jpg|2847392|fotos/20250909_143025.jpg
STATUS:ACTIVO|/dev/ttyS0|9600
RESOLUCION|1920x1080|2.1MP
```

### Cambio de Velocidad
```bash
# Comando de cambio
echo "baudrate:115200" > /dev/ttyS0

# Respuestas
OK:Cambiando a 115200 en 3 segundos
BAUDRATE_CHANGED|115200

# Ajustar terminal local
sleep 3
stty -F /dev/ttyS0 115200
```

## 🔧 Scripts Incluidos

### Setup y Configuración
```bash
scripts/setup/configurar_uart.sh      # Configurar UART automáticamente
scripts/setup/cambiar_velocidad.sh    # Cambiar velocidad UART
scripts/setup/instalar_dependencias.sh # Instalar todas las dependencias
```

### Monitoreo y Control
```bash
scripts/monitoring/enviar_comando.py    # Enviar comandos individuales
scripts/monitoring/automatizar_fotos.sh # Tomar múltiples fotos
scripts/monitoring/monitor_sistema.py   # Monitorear estado del sistema
```

## ⚙️ Configuración Avanzada

### Velocidades UART Soportadas
- **9600** - Estándar, muy confiable
- **19200** - Doble velocidad
- **38400** - Cuádruple velocidad
- **57600** - Velocidad media-alta
- **115200** - Alta velocidad (recomendado)

### Resoluciones Recomendadas
- **640x480** - VGA, ideal para Pi Zero (rápido)
- **1280x720** - HD, buen balance calidad/velocidad
- **1920x1080** - Full HD, máxima calidad (lento en Pi Zero)
- **2304x1296** - Resolución nativa sensor (si disponible)

### Personalización
```python
# En el código principal
camara = CamaraUART(
    puerto='/dev/ttyUSB0',          # Puerto personalizado
    baudrate=115200,                # Velocidad inicial
    directorio="fotos_proyecto"     # Directorio personalizado
)
```

## 🐛 Resolución de Problemas

### Error: "Device or resource busy"
```bash
# Verificar proceso que usa el puerto
sudo lsof /dev/ttyS0

# Terminar proceso si es necesario
sudo pkill -f camara_uart

# Reiniciar sistema si persiste
sudo reboot
```

### Puerto no encontrado
```bash
# Verificar UART habilitado
dmesg | grep tty

# Verificar configuración
sudo raspi-config
```

### Permisos insuficientes
```bash
# Agregar usuario a grupo dialout
sudo usermod -a -G dialout $USER

# Logout y login
exit
```

### Problemas de cámara
```bash
# Verificar módulo cámara
sudo raspi-config
# Interface Options → Camera → Enable

# Verificar detección
libcamera-hello --list-cameras
```

## 📚 Documentación Adicional

- **[Instalación Completa](docs/installation/README.md)** - Guía paso a paso
- **[Hardware Pi Zero](docs/pi-zero/)** - Configuración específica
- **[Troubleshooting](docs/troubleshooting/)** - Problemas comunes
- **[Ejemplos Avanzados](examples/)** - Casos de uso complejos

## 🤝 Contribución

1. Fork del repositorio
2. Crear rama para feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo MIT License - ver [LICENSE](LICENSE) para detalles.

## 🆘 Soporte

- **Issues**: [GitHub Issues](https://github.com/usuario/foto-uart-dropin/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/usuario/foto-uart-dropin/discussions)
- **Wiki**: [Documentación Wiki](https://github.com/usuario/foto-uart-dropin/wiki)

---

**Desarrollado para proyectos de automatización e IoT con Raspberry Pi** 🍓📷