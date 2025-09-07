# 📸 FotoUART Drop-in System

[![Tests](https://github.com/cpatagon/foto-uart-dropin/workflows/Tests/badge.svg)](https://github.com/cpatagon/foto-uart-dropin/actions)
[![Documentation](https://readthedocs.org/projects/foto-uart-dropin/badge/?version=latest)](https://foto-uart-dropin.readthedocs.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

Sistema profesional de captura y transmisión de imágenes entre **Raspberry Pi** y **ESP32** via UART con protocolo robusto de handshake.

## 🚀 Características Principales

- **📷 Captura Avanzada**: Picamera2 con procesamiento en tiempo real
- **🔧 Procesamiento Inteligente**: CLAHE + Unsharp Mask configurable
- **📡 Transmisión Robusta**: Protocolo UART con ACK/NACK y reintentos
- **⚙️ Configuración Flexible**: Archivo JSON con validación completa
- **📊 Logging Avanzado**: Sistema de logs con rotación automática
- **🛡️ Manejo de Errores**: Recuperación automática y diagnósticos detallados
- **🐳 Docker Ready**: Contenedores para desarrollo y producción

## 📋 Tabla de Contenidos

- [Instalación Rápida](#-instalación-rápida)
- [Uso Básico](#-uso-básico)
- [Configuración](#-configuración)
- [Arquitectura](#-arquitectura)
- [Desarrollo](#-desarrollo)
- [Documentación](#-documentación)
- [Contribución](#-contribución)

## ⚡ Instalación Rápida

### Raspberry Pi

```bash
# Clonar repositorio
git clone https://github.com/cpatagon/foto-uart-dropin.git
cd foto-uart-dropin

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar
cp config/raspberry_pi/config.example.json config/raspberry_pi/config.json
# Editar config.json según tu hardware

# Ejecutar
python -m src.raspberry_pi.foto_uart
```

### ESP32

```bash
# Abrir en Arduino IDE o PlatformIO
# Cargar: src/esp32/main/main.ino
# Configurar pines y constantes según tu hardware
# Compilar y subir
```

### Servidor

```bash
# Instalar dependencias del servidor
pip install flask flask-cors requests python-dotenv

# Configurar
cp config/server/.env.example config/server/.env
# Editar variables de entorno

# Ejecutar servidor
python -m src.server.app
```

## 📖 Uso Básico

### 1. **Captura Manual**

```python
from src.raspberry_pi.foto_uart import FotoUART

# Uso con context manager (recomendado)
with FotoUART("config/raspberry_pi/config.json") as foto:
    # Capturar imagen 1024px, calidad 8
    timestamp, jpeg_data = foto.capture_image(1024, 8)
    
    # Enviar via UART
    success = foto.send_image(jpeg_data, timestamp)
    print(f"Envío {'exitoso' if success else 'falló'}")
```

### 2. **Servidor Continuo**

```bash
# Ejecutar servidor que escucha comandos UART
python -m src.raspberry_pi.foto_uart

# El ESP32 puede enviar:
# "foto"           -> Usar configuración por defecto
# "foto 800"       -> Ancho 800px, calidad por defecto
# "foto 800 7"     -> Ancho 800px, calidad 7
```

### 3. **Protocolo de Comunicación**

```
Raspberry Pi                    ESP32
============                    =====
                         <--    "foto 1024 8"
"20241225_120000|45678"  -->    
                         <--    "READY"
[chunk de 256 bytes]     -->    
                         <--    "ACK"
[chunk de 256 bytes]     -->    
                         <--    "ACK"
...
                         <--    "DONE"
```

## ⚙️ Configuración

### Archivo Principal: `config/raspberry_pi/config.json`

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
    "ack_timeout": 10,
    "jpeg_progressive": true
  },
  "almacenamiento": {
    "directorio_fullres": "data/images/raw",
    "directorio_enhanced": "data/images/processed", 
    "mantener_originales": true,
    "logs_dir": "data/logs"
  },
  "procesamiento": {
    "aplicar_mejoras": true,
    "unsharp_mask": true,
    "clahe_enabled": true
  },
  "limites": {
    "max_jpeg_bytes": 112640,
    "fallback_quality_drop": 10
  }
}
```

### Configuraciones Importantes

| Parámetro | Descripción | Valores |
|-----------|-------------|---------|
| `chunk_size` | Tamaño de chunk para UART | 128, 256, 512 bytes |
| `ack_timeout` | Timeout para ACK | 5-30 segundos |
| `max_jpeg_bytes` | Límite de tamaño JPEG | Bytes (ej: 112640) |
| `aplicar_mejoras` | Habilitar procesamiento | true/false |
| `mantener_originales` | Guardar versión raw | true/false |

## 🏗️ Arquitectura

```
┌─────────────────┐    UART     ┌─────────────────┐    LTE      ┌─────────────────┐
│   Raspberry Pi  │◄────────────┤     ESP32       │────────────►│     Servidor    │
│                 │   115200bps │                 │   HTTP POST │                 │
│ ┌─────────────┐ │             │ ┌─────────────┐ │             │ ┌─────────────┐ │
│ │  Picamera2  │ │             │ │   SIM7600   │ │             │ │    Flask    │ │
│ │   Capture   │ │             │ │     LTE     │ │             │ │   Server    │ │
│ └─────────────┘ │             │ └─────────────┘ │             │ └─────────────┘ │
│ ┌─────────────┐ │             │ ┌─────────────┐ │             │ ┌─────────────┐ │
│ │   OpenCV    │ │             │ │  SD Storage │ │             │ │  Database   │ │
│ │ Processing  │ │             │ │   Manager   │ │             │ │   Storage   │ │
│ └─────────────┘ │             │ └─────────────┘ │             │ └─────────────┘ │
└─────────────────┘             └─────────────────┘             └─────────────────┘
```

### Flujo de Datos

1. **Captura**: Picamera2 → OpenCV processing → JPEG encoding
2. **Transmisión**: UART chunks con protocol handshake
3. **Almacenamiento**: ESP32 SD card + opcional backup local
4. **Envío**: HTTP POST via SIM7600 a servidor remoto

## 🔧 Desarrollo

### Setup del Entorno

```bash
# Clonar e instalar dependencias de desarrollo
git clone https://github.com/cpatagon/foto-uart-dropin.git
cd foto-uart-dropin
python -m venv venv
source venv/bin/activate
pip install -r requirements/development.txt

# Configurar pre-commit hooks
pre-commit install
```

### Ejecutar Tests

```bash
# Tests unitarios
pytest tests/unit/

# Tests de integración (requiere hardware)
pytest tests/integration/ -m hardware

# Tests con cobertura
pytest --cov=src --cov-report=html
```

### Formato y Linting

```bash
# Formatear código
black src/ tests/
isort src/ tests/

# Linting
flake8 src/ tests/
mypy src/
```

### Estructura del Proyecto

```
foto-uart-dropin/
├── src/                    # Código fuente
│   ├── raspberry_pi/       # Módulos Raspberry Pi
│   ├── esp32/             # Firmware ESP32  
│   └── server/            # Aplicación servidor
├── config/                # Configuraciones
├── tests/                 # Suite de tests
├── docs/                  # Documentación
├── scripts/               # Scripts de utilidad
└── examples/              # Ejemplos de uso
```

## 📚 Documentación

- **[Guía de Instalación](docs/installation/)** - Setup completo paso a paso
- **[Manual de Usuario](docs/user-guide/)** - Configuración y uso
- **[Documentación API](docs/api/)** - Referencias técnicas
- **[Guía de Desarrollo](docs/development/)** - Contribución y arquitectura

### Generar Documentación

```bash
# Instalar dependencias de documentación
pip install -r requirements/docs.txt

# Generar documentación con Sphinx
cd docs/
make html
```

## 🤝 Contribución

¡Las contribuciones son bienvenidas! Por favor lee:

1. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Guías de contribución
2. **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Código de conducta
3. **[Abrir un Issue](https://github.com/cpatagon/foto-uart-dropin/issues)** - Reportar bugs o solicitar características

### Proceso de Contribución

```bash
# 1. Fork del repositorio
# 2. Crear rama de característica
git checkout -b feature/nueva-caracteristica

# 3. Hacer cambios y commitear
git commit -m "feat: agregar nueva característica"

# 4. Ejecutar tests
pytest

# 5. Push y crear Pull Request
git push origin feature/nueva-caracteristica
```

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Reconocimientos

- **Alejandro Rebolledo** - Proyecto original y arquitectura base
- **Comunidad Raspberry Pi** - Soporte técnico y documentación
- **Comunidad ESP32** - Bibliotecas y ejemplos de hardware

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/cpatagon/foto-uart-dropin/issues)
- **Documentación**: [ReadTheDocs](https://foto-uart-dropin.readthedocs.io)
- **Email**: support@foto-uart-dropin.com

---

<div align="center">

**[⬆ Volver al inicio](#-fotouart-drop-in-system)**

Hecho con ❤️ para la comunidad IoT

</div>
