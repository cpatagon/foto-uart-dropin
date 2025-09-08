# Guía de Troubleshooting

## Problemas Comunes Pi Zero W

### 1. Memoria Insuficiente
**Síntomas**: Sistema lento, proceso killed
**Solución**: Ajustar config_pi_zero.json

### 2. UART No Funciona  
**Síntomas**: No hay comunicación con ESP32
**Solución**: Verificar conexiones GPIO 14/15

### 3. Cámara No Detectada
**Síntomas**: Error import picamera2
**Solución**: Habilitar cámara en raspi-config
