# Documentación Pi Zero W

## Guías Específicas

- [Guía de Instalación](installation-guide.md)
- [Optimización de Rendimiento](performance-optimization.md)
- [Troubleshooting](troubleshooting.md)
- [Configuración Avanzada](advanced-configuration.md)

## Configuraciones Recomendadas

### Hardware
- **Modelo**: Raspberry Pi Zero W
- **Memoria RAM**: 512MB
- **Almacenamiento**: microSD 16GB+ Clase 10
- **Conectividad**: WiFi 2.4GHz

### Software
- **OS**: Raspberry Pi OS Lite (recomendado)
- **Python**: 3.9+ (incluido en Pi OS)
- **Configuración**: config_pi_zero.json

## Rendimiento Esperado

| Métrica | Valor | Notas |
|---------|-------|-------|
| Tiempo captura | 2-3s | 800px, calidad 4 |
| Uso RAM | ~230MB | Pico durante captura |
| Uso CPU | 85-90% | Durante procesamiento |
| Transmisión UART | 8-10s | 64KB @ 115200 bps |

## Scripts Útiles

```bash
# Verificar instalación
./scripts/setup/verify_pi_zero.sh

# Monitor de sistema
foto-uart-monitor

# Test de rendimiento
foto-uart-performance-test
```
