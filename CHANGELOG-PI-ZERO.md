# Changelog - Pi Zero W Edition

## [1.0.0-pi-zero] - 2024-12-XX

### Agregado
- ✅ Optimización específica para Raspberry Pi Zero W
- ✅ Configuración automática de hardware limitado
- ✅ Script de instalación `install_pi_zero.sh`
- ✅ Configuración `config_pi_zero.json` optimizada
- ✅ Requirements ligero `requirements-pi-zero.txt`
- ✅ Documentación específica Pi Zero W
- ✅ Scripts de conveniencia y monitoreo
- ✅ GitHub Actions para testing Pi Zero W
- ✅ Servicio systemd con protecciones de memoria

### Optimizado
- ⚡ Resolución por defecto: 1024px → 800px
- ⚡ Chunk size: 256 bytes → 128 bytes
- ⚡ Calidad JPEG: 5 → 4
- ⚡ Límite imagen: 112KB → 64KB
- ⚡ Timeout ACK: 10s → 15s
- ⚡ GPU Memory: auto → 128MB
- ⚡ Swap: auto → 512MB

### Configurado
- 🔧 CPU Governor: ondemand
- 🔧 Servicios innecesarios deshabilitados
- 🔧 Configuración de red optimizada
- 🔧 Monitor térmico automático
- 🔧 Limpieza automática de imágenes

### Documentado
- 📖 Guía de instalación Pi Zero W
- 📖 Guía de optimización de rendimiento
- 📖 Troubleshooting específico
- 📖 Configuración avanzada
- 📖 Scripts de utilidad

## Comandos Nuevos

```bash
# Instalación optimizada
curl -sSL .../install_pi_zero.sh | bash

# Scripts de conveniencia
foto-uart-pi-zero           # Ejecutar optimizado
foto-uart-monitor           # Monitor de sistema
foto-uart-performance-test  # Test de rendimiento
```

## Migración desde Versión Anterior

1. Ejecutar script de migración: `./migrate_to_pi_zero.sh --backup`
2. Verificar instalación: `./scripts/setup/verify_pi_zero.sh`
3. Actualizar configuración: usar `config_pi_zero.json`
4. Reiniciar para aplicar optimizaciones de hardware
