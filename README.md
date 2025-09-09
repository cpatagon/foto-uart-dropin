# Sistema de Cámara UART para Raspberry Pi

Un sistema de control remoto para tomar fotografías con una Raspberry Pi Zero mediante comandos UART. Ideal para proyectos de control remoto, sistemas embebidos y automatización.

## 📋 Características

- Control remoto de cámara via UART
- Nombres de archivo con timestamp automático
- Respuestas estructuradas con información detallada
- Múltiples comandos de control
- Manejo robusto de errores
- Compatible con minicom, screen y comandos directos

## 🔧 Requisitos

### Hardware
- Raspberry Pi Zero con módulo de cámara
- Conexión UART (GPIO o adaptador USB-Serial)
- Raspberry Pi controladora (opcional)

### Software
```bash
sudo apt update
sudo apt install python3-serial python3-picamera2
sudo pip3 install pyserial
```

## ⚙️ Configuración

### 1. Habilitar UART en Raspberry Pi Zero

Editar `/boot/config.txt`:
```bash
sudo nano /boot/config.txt
```

Agregar al final:
```
enable_uart=1
dtoverlay=disable-bt
```

### 2. Configurar puerto serie

```bash
sudo raspi-config
# Interface Options → Serial Port → No (login shell) → Yes (serial interface)
```

### 3. Reiniciar
```bash
sudo reboot
```

## 🔌 Conexiones

### GPIO a GPIO (entre dos Raspberry Pi)
```
Pi con Cámara    ←→    Pi Controladora
GPIO 14 (TX)     ←→    GPIO 15 (RX)
GPIO 15 (RX)     ←→    GPIO 14 (TX)
GND              ←→    GND
```

### Adaptador USB-Serial
```
Adaptador        ←→    Pi con Cámara
TX               ←→    GPIO 15 (RX)
RX               ←→    GPIO 14 (TX)
GND              ←→    GND
```

## 🚀 Uso

### Iniciar el sistema
```bash
python3 camara_uart.py
```

### Comandos disponibles

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `foto` | Toma una fotografía | `foto` |
| `estado` | Muestra estado del sistema | `estado` |
| `res:WIDTHxHEIGHT` | Cambia resolución | `res:1920x1080` |
| `salir` | Termina el programa | `salir` |

## 📱 Métodos de envío

### 1. Comando directo
```bash
echo "foto" > /dev/ttyS0
```

### 2. Con Screen
```bash
screen /dev/ttyS0 9600
foto
# Salir: Ctrl+A, K, Y
```

### 3. Con Minicom
```bash
minicom -D /dev/ttyS0 -b 9600
foto
```

### 4. Script personalizado
```bash
#!/bin/bash
stty -F /dev/ttyS0 9600 cs8 -cstopb -parenb
echo "foto" > /dev/ttyS0
```

## 📤 Protocolo de respuestas

### Formato de respuesta exitosa
```
OK|YYYYMMDD_HHMMSS.jpg|tamaño_bytes|ruta_completa
```

### Respuestas del sistema

| Tipo | Formato | Descripción |
|------|---------|-------------|
| Inicio | `CAMERA_READY` | Sistema iniciado |
| Foto exitosa | `OK\|filename\|bytes\|path` | Foto tomada correctamente |
| Error | `ERROR:mensaje` | Error al procesar comando |
| Estado | `STATUS:información` | Estado del sistema |
| Cierre | `CAMERA_OFFLINE` | Sistema desconectado |

## 💡 Ejemplos de uso

### Sesión típica de uso
```
CAMERA_READY
OK|20250909_095246.jpg|117373|fotos/20250909_095246.jpg
OK|20250909_095301.jpg|117548|fotos/20250909_095301.jpg
CAMERA_OFFLINE
CAMERA_READY
OK|20250909_095502.jpg|116956|fotos/20250909_095502.jpg
STATUS:Sistema activo - Directorio: fotos
```

### Comando desde terminal
```bash
# Tomar una foto
echo "foto" > /dev/ttyS0

# Ver estado
echo "estado" > /dev/ttyS0

# Cambiar resolución
echo "res:1280x720" > /dev/ttyS0
```

### Script de automatización
```bash
#!/bin/bash
# Tomar 5 fotos con intervalo de 2 segundos

for i in {1..5}; do
    echo "foto" > /dev/ttyS0
    sleep 2
done
```

## 🔍 Resolución de problemas

### Error: "Device or resource busy"
```bash
# Verificar qué proceso usa el puerto
sudo lsof /dev/ttyS0

# Matar proceso si es necesario
sudo kill -9 PID_NUMBER
```

### Puerto no encontrado
```bash
# Verificar puertos disponibles
ls -la /dev/tty*

# Verificar configuración UART
dmesg | grep tty
```

### Permisos insuficientes
```bash
# Agregar usuario al grupo dialout
sudo usermod -a -G dialout $USER

# Logout y login nuevamente
```

## 📁 Estructura de archivos

```
proyecto/
├── camara_uart.py          # Programa principal
├── fotos/                  # Directorio de fotos (se crea automáticamente)
│   ├── 20250909_095246.jpg
│   ├── 20250909_095301.jpg
│   └── 20250909_095502.jpg
└── README.md              # Este archivo
```

## ⚡ Configuración avanzada

### Cambiar puerto y velocidad
```python
# En el código principal
iniciar_camara_uart(
    puerto='/dev/ttyUSB0',  # Puerto personalizado
    baudrate=115200,        # Velocidad mayor
    directorio="mis_fotos"  # Directorio personalizado
)
```

### Resoluciones recomendadas
- `640x480` - VGA (rápido para Pi Zero)
- `1280x720` - HD (balance calidad/velocidad)
- `1920x1080` - Full HD (máxima calidad)

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo LICENSE para detalles.

## 🆘 Soporte

Para reportar bugs o solicitar features, abre un issue en el repositorio.

---

**Desarrollado para proyectos de automatización con Raspberry Pi** 🍓📷