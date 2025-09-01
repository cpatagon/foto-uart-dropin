# FOTO-UART-DROPIN
## Sistema de Captura de Imágenes Compatible por UART

**Documento de Especificación de Requisitos del Sistema (ERS)**

Este repositorio contiene los requerimientos técnicos para el desarrollo de un sistema de captura y transmisión de imágenes que funcione como "drop-in replacement" manteniendo compatibilidad total con sistemas ESP32 existentes.

## Propósito

Definir los requisitos técnicos necesarios para desarrollar un sistema de captura y transmisión de imágenes compatible con el protocolo UART existente, permitiendo capturar, procesar y transmitir imágenes sin requerir modificaciones en el hardware receptor.

## Ámbito del Sistema

**FOTO-UART-DROPIN** (Sistema de Captura de Imágenes Compatible por UART) debe:
- Capturar imágenes y aplicar mejoras opcionales
- Transmitir por UART usando protocolo de handshake robusto
- Mantener compatibilidad total con receptores ESP32 existentes
- Funcionar como reemplazo directo sin modificaciones del receptor

**Exclusiones**: No incluye mantenimiento post-implementación, actualizaciones de firmware remotas, ni soporte técnico continuo.

## Definiciones Técnicas

| Término | Descripción |
|---------|-------------|
| **ACK** | Confirmación de recepción correcta de un chunk (`ACK\n`) |
| **CLAHE** | Contrast Limited Adaptive Histogram Equalization |
| **CM3** | Camera Module 3 (IMX708), cámara oficial de Raspberry Pi con autofoco |
| **UART** | Puerto serie asíncrono (8N1 @ 115200 baudios) |
| **USB Gadget** | Modo CDC-ACM para pruebas via USB |

## Protocolo de Comunicación UART

### Secuencia Obligatoria

1. **Comando inicial**: Receptor envía `foto\n`
2. **Preparación**: Sistema captura y procesa imagen
3. **Header**: Sistema envía `YYYYMMDD_HHMMSS|tamaño_bytes\n`
4. **Confirmación**: Receptor responde `READY\n`
5. **Transmisión**: Sistema envía chunks de 256 bytes
6. **ACK**: Receptor confirma cada chunk con `ACK\n`
7. **Finalización**: Receptor envía `DONE\n`

### Comandos Soportados

| Formato | Descripción | Parámetros |
|---------|-------------|------------|
| `foto\n` | Configuración por defecto | Ancho: 1024px, Calidad: 5 |
| `foto [ancho]\n` | Ancho específico | Ancho: 100-4608px |
| `foto [ancho] [calidad]\n` | Ancho y calidad | Calidad: 1-10 → JPEG 10-100 |

## Requisitos Específicos

### Interfaces Externas

| Código | Descripción | Prioridad |
|--------|-------------|-----------|
| **RS01-REQ01** | UART a 115200 baudios (8N1) | Esencial, Alta |
| **RS01-REQ02** | Comando `foto\n` con variantes opcionales, UTF-8, terminador LF | Esencial, Alta |
| **RS01-REQ03** | Header exacto: `YYYYMMDD_HHMMSS\|tamaño_bytes\n` | Esencial, Alta |
| **RS01-REQ04** | Handshake completo: READY/ACK/DONE con chunks de 256 bytes | Esencial, Alta |

### Funciones del Sistema

| Código | Descripción | Prioridad |
|--------|-------------|-----------|
| **RS01-REQ05** | Captura full-res y generación de versión procesada para UART | Esencial, Alta |
| **RS01-REQ06** | Mejoras opcionales (CLAHE, unsharp) configurables | Condicional, Media |
| **RS01-REQ07** | Redimensionado manteniendo aspect ratio, ancho por defecto 1024px | Esencial, Alta |
| **RS01-REQ08** | Almacenamiento: original en `fullres/`, procesada en `enhanced/` | Esencial, Alta |
| **RS01-REQ09** | Reintento automático único ante timeout/NACK_TIMEOUT | Esencial, Alta |

### Requisitos de Rendimiento (SLA)

| Código | Descripción | Especificación | Prioridad |
|--------|-------------|----------------|-----------|
| **RS01-REQ10** | SLA de tiempo (≤ 110 KB) | Comando→header ≤ 5s, total ≤ 10s | Esencial, Alta |
| **RS01-REQ11** | Chunks exactos | 256 bytes (último puede ser menor), timeout ACK = 10s | Esencial, Alta |
| **RS01-REQ12** | Compatibilidad tamaños mayores | Sin garantía de SLA 10s | Opcional, Media |
| **RS01-REQ13** | Parámetros válidos | Ancho [100,4608]px, calidad [1,10] | Esencial, Alta |

### Restricciones de Diseño

| Código | Descripción | Especificación | Prioridad |
|--------|-------------|----------------|-----------|
| **RS01-REQ14** | Formato timestamps | `YYYYMMDD_HHMMSS` | Esencial, Alta |
| **RS01-REQ15** | Formato de imagen | JPEG con calidad configurable | Esencial, Alta |
| **RS01-REQ16** | Mapeo de calidad | `jpeg_quality = clamp(quality_param,1,10) * 10` | Esencial, Alta |
| **RS01-REQ17** | Estructura directorios | `storage/fullres`, `storage/enhanced`, `storage/logs` | Esencial, Alta |

### Atributos del Sistema

| Código | Descripción | Prioridad |
|--------|-------------|-----------|
| **RS01-REQ18** | Logging con rotación: operaciones, timestamps, errores, reintentos | Esencial, Alta |
| **RS01-REQ19** | Robustez ante desconexiones: timeouts y recuperación automática | Esencial, Alta |
| **RS01-REQ20** | Validación de comandos, respuesta a malformados (`ERR_CMD\n`) | Esencial, Alta |
| **RS01-REQ21** | Indicadores de estado durante captura y transmisión | Condicional, Media |

### Otros Requisitos

| Código | Descripción | Prioridad |
|--------|-------------|-----------|
| **RS01-REQ22** | Configuración por JSON: puerto, rutas y cámara/perfiles | Esencial, Alta |
| **RS01-REQ23** | Diagnóstico: verificación de cámara y puerto UART | Esencial, Alta |
| **RS01-REQ24** | Plataformas: Raspberry Pi OS, Ubuntu, Debian con libcamera/OpenCV | Esencial, Alta |

## Manejo de Errores

**Entradas inválidas**: Comandos malformados (ej. `foto abc` o calidad fuera de rango) generan `ERR_CMD\n`, se registra en log y el sistema permanece esperando el siguiente comando válido.

## Matriz de Trazabilidad

| Requisito | Descripción | Caso de Prueba |
|-----------|-------------|----------------|
| RS01-REQ01 | UART 115200 8N1 exacto | CP-PROTO-01 |
| RS01-REQ04 | READY/ACK/DONE exactos | CP-PROTO-01, CP-TIMEOUT-02 |
| SLA | ≤ 10s hasta 110 KB | CP-REN-01 |
| Chunks | 256 bytes exactos | CP-CHNK-01 |
| Almacenamiento | fullres + enhanced | CP-IO-02 |

## Casos de Prueba Obligatorios

| Caso | Entrada | Resultado Esperado |
|------|---------|-------------------|
| **CP-PROTO-01** | `foto\n` | Header + transmisión completa |
| **CP-REN-01** | `foto 1024 5\n` | t_header ≤ 5s, t_total ≤ 10s |
| **CP-CHNK-01** | Flujo normal | 256 bytes exactos por chunk |
| **CP-TIMEOUT-02** | Sin READY o sin ACK | Reintento total único + nuevo header |
| **CP-IO-02** | N/A | Guardado en `fullres/`+`enhanced/` |

## Configuración de Ejemplo

### JSON de Configuración
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
    "directorio_fullres": "storage/fullres",
    "directorio_enhanced": "storage/enhanced",
    "mantener_originales": true,
    "logs_dir": "storage/logs"
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

## Entornos de Prueba Especificados

### USB Gadget (CDC-ACM)
- Habilitar `dwc2,g_serial` en `/boot/cmdline.txt`
- RPi expone `/dev/ttyGS0`, PC ve `/dev/ttyACM0`

### UART TTL
- Dongle USB-TTL (3.3V) en `/dev/serial0` (RPi) y `/dev/ttyUSB0` (PC)

### Simulador Host (PC)
- Envía `foto[ [ancho][ calidad]]\n`
- Espera header, responde `READY\n`
- Confirma chunks con `ACK\n` 
- Finaliza con `DONE\n`
- Soporta `NACK_TIMEOUT`

## Especificaciones Técnicas Críticas

### Protocolo UART
- **Velocidad**: 115200 baudios obligatorio
- **Formato**: 8N1 (8 bits, sin paridad, 1 stop bit)
- **Encoding**: UTF-8
- **Control de flujo**: Ninguno

### Rendimiento
- **Tiempo captura→header**: ≤ 5 segundos
- **Tiempo total**: ≤ 10 segundos (imágenes ≤ 110KB)
- **Chunk size**: 256 bytes exactos
- **Timeout ACK**: 10 segundos
- **Reintentos**: 1 automático únicamente

### Formato de Datos
- **Timestamps**: `YYYYMMDD_HHMMSS`
- **Header**: `timestamp|tamaño_bytes\n`
- **Imágenes**: JPEG únicamente
- **Mapeo calidad**: `jpeg_quality = clamp(quality_param,1,10) * 10`

## Criterios de Aceptación

Para que una implementación sea considerada conforme debe:

1. **Respetar protocolo exacto**: Comandos, respuestas y secuencias según especificación
2. **Cumplir SLA de rendimiento**: Tiempos de respuesta dentro de límites establecidos
3. **Pasar casos de prueba**: Todos los casos CP-PROTO-01 a CP-IO-02
4. **Mantener compatibilidad ESP32**: Funcionar sin modificaciones en receptor
5. **Implementar manejo de errores**: Timeouts, reintentos y validación de comandos

## Clasificación de Requisitos

### Por Prioridad
- **Esencial**: RS01-REQ01, 02, 03, 04, 05, 07, 08, 09, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24
- **Condicional**: RS01-REQ06, 21
- **Opcional**: RS01-REQ12

### Por Estabilidad
- **Alta**: Protocolo UART, formatos de datos, interfaces críticas
- **Media**: Funciones de procesamiento, configuraciones opcionales
- **Baja**: Características futuras no especificadas

## Documentación Técnica Completa

El documento de requerimientos completo (IEEE 830-1998) se encuentra en:
- **Archivo fuente**: `docs/TP1_FOTO_UART_DROPIN_REC01.tex`
- **PDF compilado**: `docs/requerimientos.pdf`

**Nota**: La implementación debe cumplir todos los requisitos marcados como "Esencial" para ser considerada válida y compatible con el ecosistema existente.
