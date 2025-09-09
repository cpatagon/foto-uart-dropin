#!/bin/bash
#
# Script de Diagnóstico y Reparación - FotoUART Drop-in
# ====================================================
# Soluciona problemas comunes de cámara y UART en Pi Zero W + Pi 3B+
#

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Detectar modelo de Pi
detect_pi_model() {
    local model=""
    if [[ -f /proc/device-tree/model ]]; then
        model=$(tr -d '\0' < /proc/device-tree/model)
        echo "$model"
    else
        echo "Unknown"
    fi
}

# 1. DIAGNÓSTICO COMPLETO
diagnostic_complete() {
    info "🔍 Ejecutando diagnóstico completo..."
    echo
    
    local pi_model=$(detect_pi_model)
    info "📟 Modelo detectado: $pi_model"
    
    # Verificar procesos que usan la cámara
    info "📷 Verificando procesos de cámara..."
    local camera_processes=$(ps aux | grep -E "(camera|libcamera|picamera)" | grep -v grep || true)
    if [[ -n "$camera_processes" ]]; then
        warn "⚠️  Procesos de cámara activos:"
        echo "$camera_processes"
    else
        success "✅ No hay procesos de cámara conflictivos"
    fi
    
    # Verificar puertos serie
    info "🔌 Verificando puertos serie disponibles..."
    for port in /dev/ttyS* /dev/ttyAMA*; do
        if [[ -e "$port" ]]; then
            local perm=$(ls -la "$port" | awk '{print $1 " " $3 " " $4}')
            info "   $port: $perm"
        fi
    done
    
    # Verificar configuración de boot
    info "⚙️  Verificando configuración de boot..."
    if grep -q "enable_uart=1" /boot/config.txt 2>/dev/null; then
        success "✅ UART habilitado en config.txt"
    else
        warn "⚠️  UART no habilitado en config.txt"
    fi
    
    if grep -q "camera_auto_detect=1" /boot/config.txt 2>/dev/null; then
        success "✅ Cámara habilitada en config.txt"
    else
        warn "⚠️  Cámara no habilitada en config.txt"
    fi
    
    # Verificar grupos de usuario
    info "👤 Verificando permisos de usuario..."
    local groups=$(groups)
    if echo "$groups" | grep -q "video"; then
        success "✅ Usuario en grupo video"
    else
        warn "⚠️  Usuario NO en grupo video"
    fi
    
    if echo "$groups" | grep -q "dialout"; then
        success "✅ Usuario en grupo dialout"
    else
        warn "⚠️  Usuario NO en grupo dialout"
    fi
    
    # Test de cámara
    info "📸 Probando detección de cámara..."
    if command -v libcamera-hello &> /dev/null; then
        if timeout 10 libcamera-hello --list-cameras &> /dev/null; then
            success "✅ Cámara detectada correctamente"
        else
            error "❌ Error detectando cámara"
        fi
    else
        warn "⚠️  libcamera-hello no disponible"
    fi
}

# 2. REPARAR CONFLICTOS DE CÁMARA
fix_camera_conflicts() {
    info "🔧 Reparando conflictos de cámara..."
    
    # Terminar procesos conflictivos
    info "🛑 Terminando procesos de cámara conflictivos..."
    pkill -f "python.*camera" 2>/dev/null || true
    pkill -f "libcamera" 2>/dev/null || true
    pkill -f "picamera" 2>/dev/null || true
    
    # Esperar a que se liberen los recursos
    sleep 3
    
    # Verificar módulos de cámara
    info "📦 Verificando módulos de cámara..."
    if lsmod | grep -q "bcm2835_v4l2"; then
        warn "⚠️  Módulo legacy bcm2835_v4l2 cargado, removiendo..."
        sudo modprobe -r bcm2835_v4l2 2>/dev/null || true
    fi
    
    # Recargar driver de cámara
    info "🔄 Recargando driver de cámara..."
    sudo modprobe -r bcm2835_isp 2>/dev/null || true
    sudo modprobe -r bcm2835_codec 2>/dev/null || true
    sleep 2
    sudo modprobe bcm2835_isp
    sudo modprobe bcm2835_codec
    
    success "✅ Conflictos de cámara resueltos"
}

# 3. CONFIGURAR UART CORRECTAMENTE
fix_uart_config() {
    info "🔧 Configurando UART correctamente..."
    
    # Backup de configuración
    sudo cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)
    
    # Configurar UART en config.txt
    if ! grep -q "enable_uart=1" /boot/config.txt; then
        echo "enable_uart=1" | sudo tee -a /boot/config.txt
        info "📝 UART habilitado en config.txt"
    fi
    
    # Deshabilitar Bluetooth para liberar UART (Pi Zero W)
    local pi_model=$(detect_pi_model)
    if echo "$pi_model" | grep -q "Pi Zero"; then
        if ! grep -q "dtoverlay=disable-bt" /boot/config.txt; then
            echo "dtoverlay=disable-bt" | sudo tee -a /boot/config.txt
            info "📝 Bluetooth deshabilitado para liberar UART"
        fi
        
        # Deshabilitar servicios de Bluetooth
        sudo systemctl disable hciuart 2>/dev/null || true
        sudo systemctl disable bluetooth 2>/dev/null || true
    fi
    
    # Verificar cmdline.txt
    if grep -q "console=serial0" /boot/cmdline.txt; then
        warn "⚠️  Console serial habilitado, deshabilitando..."
        sudo sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
    fi
    
    # Configurar permisos
    sudo usermod -a -G dialout "$(whoami)" 2>/dev/null || true
    sudo usermod -a -G video "$(whoami)" 2>/dev/null || true
    
    success "✅ UART configurado correctamente"
}

# 4. TEST DE COMUNICACIÓN UART
test_uart_communication() {
    info "🧪 Probando comunicación UART..."
    
    # Detectar puerto UART correcto
    local uart_port=""
    for port in /dev/ttyS0 /dev/ttyAMA0 /dev/serial0; do
        if [[ -e "$port" ]] && [[ -r "$port" ]] && [[ -w "$port" ]]; then
            uart_port="$port"
            break
        fi
    done
    
    if [[ -z "$uart_port" ]]; then
        error "❌ No se encontró puerto UART válido"
        return 1
    fi
    
    info "📍 Usando puerto UART: $uart_port"
    
    # Test básico de lectura/escritura
    info "📡 Probando comunicación básica..."
    
    # Crear script de test temporal
    cat > /tmp/uart_test.py << 'EOF'
#!/usr/bin/env python3
import serial
import time
import sys

def test_uart(port):
    try:
        print(f"🔗 Abriendo {port}...")
        ser = serial.Serial(port, 115200, timeout=2)
        
        print("📤 Enviando comando test...")
        ser.write(b"TEST\n")
        
        print("👂 Esperando respuesta...")
        response = ser.readline()
        
        if response:
            print(f"📥 Respuesta: {response.decode().strip()}")
            return True
        else:
            print("❌ Sin respuesta")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        if 'ser' in locals():
            ser.close()

if __name__ == "__main__":
    port = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyS0"
    success = test_uart(port)
    sys.exit(0 if success else 1)
EOF
    
    if python3 /tmp/uart_test.py "$uart_port"; then
        success "✅ Puerto UART funcional"
    else
        warn "⚠️  Puerto UART no responde (normal si no hay dispositivo conectado)"
    fi
    
    rm -f /tmp/uart_test.py
}

# 5. CREAR SCRIPT DE CAPTURA MEJORADO
create_improved_capture_script() {
    info "📝 Creando script de captura mejorado..."
    
    local script_dir="$HOME/foto-uart-dropin/src/raspberry_pi"
    mkdir -p "$script_dir"
    
    cat > "$script_dir/foto_uart_fixed.py" << 'EOF'
#!/usr/bin/env python3
"""
FotoUART - Versión Corregida
===========================
Soluciona problemas de cámara y UART detectados.
"""

import json
import os
import logging
import time
import signal
import sys
from datetime import datetime
from typing import Tuple, Optional
import serial
import cv2
import numpy as np

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CameraManager:
    """Gestor de cámara con manejo robusto de errores."""
    
    def __init__(self):
        self.camera = None
        self.camera_available = False
        
    def initialize_camera(self):
        """Inicializa la cámara con múltiples métodos."""
        logger.info("🔄 Inicializando cámara...")
        
        # Método 1: Picamera2 (preferido)
        try:
            from picamera2 import Picamera2
            
            # Liberar cualquier instancia previa
            try:
                if hasattr(self, 'camera') and self.camera:
                    self.camera.stop()
                    self.camera.close()
            except:
                pass
            
            # Esperar un momento
            time.sleep(2)
            
            self.camera = Picamera2()
            config = self.camera.create_still_configuration()
            self.camera.configure(config)
            self.camera.start()
            
            # Test de captura
            test_image = self.camera.capture_array()
            if test_image is not None:
                self.camera_available = True
                logger.info("✅ Picamera2 inicializada correctamente")
                return True
                
        except Exception as e:
            logger.warning(f"⚠️  Picamera2 falló: {e}")
        
        # Método 2: OpenCV como fallback
        try:
            logger.info("🔄 Intentando OpenCV como fallback...")
            self.camera = cv2.VideoCapture(0)
            
            if self.camera.isOpened():
                # Test de captura
                ret, frame = self.camera.read()
                if ret and frame is not None:
                    self.camera_available = True
                    logger.info("✅ OpenCV camera inicializada")
                    return True
            
        except Exception as e:
            logger.error(f"❌ OpenCV también falló: {e}")
        
        logger.error("❌ No se pudo inicializar ninguna cámara")
        return False
    
    def capture_image(self, width: int = 800, quality: int = 4) -> Tuple[str, bytes]:
        """Captura imagen con el método disponible."""
        if not self.camera_available:
            raise Exception("Cámara no disponible")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        try:
            if hasattr(self.camera, 'capture_array'):
                # Picamera2
                image = self.camera.capture_array()
            else:
                # OpenCV
                ret, image = self.camera.read()
                if not ret:
                    raise Exception("Error capturando con OpenCV")
            
            # Redimensionar
            h, w = image.shape[:2]
            new_w = width
            new_h = int(h * width / w)
            resized = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
            
            # Codificar JPEG
            jpeg_quality = min(max(quality * 10, 10), 100)
            success, encoded = cv2.imencode('.jpg', resized, 
                                          [cv2.IMWRITE_JPEG_QUALITY, jpeg_quality])
            
            if not success:
                raise Exception("Error codificando JPEG")
            
            jpeg_data = encoded.tobytes()
            logger.info(f"📸 Imagen capturada: {new_w}x{new_h}, {len(jpeg_data)} bytes")
            
            return timestamp, jpeg_data
            
        except Exception as e:
            logger.error(f"❌ Error en captura: {e}")
            raise
    
    def cleanup(self):
        """Limpia recursos de cámara."""
        try:
            if self.camera:
                if hasattr(self.camera, 'stop'):
                    self.camera.stop()
                if hasattr(self.camera, 'close'):
                    self.camera.close()
                elif hasattr(self.camera, 'release'):
                    self.camera.release()
        except:
            pass

class UARTManager:
    """Gestor de UART con detección automática de puerto."""
    
    def __init__(self):
        self.serial = None
        self.port = None
        
    def find_uart_port(self):
        """Encuentra el puerto UART correcto."""
        ports_to_try = ['/dev/ttyS0', '/dev/ttyAMA0', '/dev/serial0']
        
        for port in ports_to_try:
            try:
                if os.path.exists(port):
                    # Verificar permisos
                    if os.access(port, os.R_OK | os.W_OK):
                        logger.info(f"✅ Puerto encontrado: {port}")
                        return port
                    else:
                        logger.warning(f"⚠️  Sin permisos para {port}")
            except:
                continue
        
        return None
    
    def initialize_uart(self):
        """Inicializa comunicación UART."""
        self.port = self.find_uart_port()
        
        if not self.port:
            raise Exception("No se encontró puerto UART válido")
        
        try:
            self.serial = serial.Serial(
                self.port,
                115200,
                timeout=2,
                write_timeout=2
            )
            logger.info(f"📡 UART inicializado: {self.port}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error inicializando UART: {e}")
            raise
    
    def send_image(self, data: bytes, timestamp: str) -> bool:
        """Envía imagen usando protocolo robusto."""
        if not self.serial:
            return False
        
        try:
            # Enviar header
            header = f"{timestamp}|{len(data)}\n"
            self.serial.write(header.encode('utf-8'))
            logger.info(f"📤 Header enviado: {header.strip()}")
            
            # Esperar READY con timeout
            response = self.serial.readline().decode().strip()
            if response != "READY":
                logger.error(f"❌ Respuesta inesperada: '{response}'")
                return False
            
            logger.info("✅ READY recibido")
            
            # Enviar datos en chunks
            chunk_size = 256
            for i in range(0, len(data), chunk_size):
                chunk = data[i:i+chunk_size]
                self.serial.write(chunk)
                
                # Esperar ACK
                ack = self.serial.readline().decode().strip()
                if ack != "ACK":
                    logger.error(f"❌ ACK no recibido en offset {i}")
                    return False
                
                if i % (chunk_size * 10) == 0:
                    progress = min(100, (i * 100) // len(data))
                    logger.info(f"📊 Progreso: {progress}%")
            
            # Esperar DONE
            done = self.serial.readline().decode().strip()
            if done == "DONE":
                logger.info("✅ Transmisión completada")
                return True
            else:
                logger.error(f"❌ DONE no recibido: '{done}'")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error en transmisión: {e}")
            return False
    
    def cleanup(self):
        """Limpia recursos UART."""
        try:
            if self.serial and self.serial.is_open:
                self.serial.close()
        except:
            pass

class FotoUARTFixed:
    """Sistema FotoUART con correcciones aplicadas."""
    
    def __init__(self):
        self.camera_mgr = CameraManager()
        self.uart_mgr = UARTManager()
        self.running = True
        
        # Configurar manejo de señales
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Maneja señales de interrupción."""
        logger.info("🛑 Señal de interrupción recibida")
        self.running = False
    
    def initialize(self):
        """Inicializa todos los componentes."""
        logger.info("🚀 Inicializando FotoUART Fixed...")
        
        # Inicializar cámara
        if not self.camera_mgr.initialize_camera():
            raise Exception("No se pudo inicializar la cámara")
        
        # Inicializar UART
        self.uart_mgr.initialize_uart()
        
        logger.info("✅ Inicialización completada")
    
    def run(self):
        """Ejecuta el loop principal."""
        logger.info("🎬 Iniciando loop principal...")
        
        try:
            while self.running:
                try:
                    # Leer comando
                    if not self.uart_mgr.serial:
                        break
                    
                    cmd = self.uart_mgr.serial.readline().decode().strip()
                    if not cmd:
                        continue
                    
                    logger.info(f"📨 Comando recibido: '{cmd}'")
                    
                    # Procesar comando
                    parts = cmd.split()
                    if not parts:
                        continue
                    
                    if parts[0].lower() == "foto":
                        # Extraer parámetros
                        width = 800
                        quality = 4
                        
                        if len(parts) >= 2:
                            try:
                                width = int(parts[1])
                            except ValueError:
                                self.uart_mgr.serial.write(b"ERR_WIDTH\n")
                                continue
                        
                        if len(parts) >= 3:
                            try:
                                quality = int(parts[2])
                            except ValueError:
                                self.uart_mgr.serial.write(b"ERR_QUALITY\n")
                                continue
                        
                        # Capturar y enviar
                        try:
                            timestamp, jpeg_data = self.camera_mgr.capture_image(width, quality)
                            success = self.uart_mgr.send_image(jpeg_data, timestamp)
                            
                            if success:
                                logger.info(f"✅ Imagen {timestamp} enviada exitosamente")
                            else:
                                logger.error(f"❌ Error enviando imagen {timestamp}")
                                
                        except Exception as e:
                            logger.error(f"❌ Error procesando foto: {e}")
                            self.uart_mgr.serial.write(b"ERR_CAPTURE\n")
                    
                    else:
                        # Comando desconocido
                        self.uart_mgr.serial.write(b"ERR_CMD\n")
                        logger.warning(f"⚠️  Comando desconocido: '{cmd}'")
                
                except Exception as e:
                    logger.error(f"❌ Error en loop: {e}")
                    time.sleep(1)
                    
        except KeyboardInterrupt:
            logger.info("🛑 Interrupción por teclado")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Limpia todos los recursos."""
        logger.info("🧹 Limpiando recursos...")
        self.camera_mgr.cleanup()
        self.uart_mgr.cleanup()
        logger.info("✅ Limpieza completada")

def main():
    """Punto de entrada principal."""
    try:
        foto_uart = FotoUARTFixed()
        foto_uart.initialize()
        foto_uart.run()
        
    except Exception as e:
        logger.error(f"❌ Error fatal: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$script_dir/foto_uart_fixed.py"
    success "✅ Script de captura mejorado creado"
}

# 6. CREAR SCRIPT DE COMANDO PARA PI 3B+
create_pi3b_commander() {
    info "📝 Creando commander mejorado para Pi 3B+..."
    
    local script_dir="$HOME/foto-uart-dropin/src/raspberry_pi"
    mkdir -p "$script_dir"
    
    cat > "$script_dir/pi3b_commander_fixed.py" << 'EOF'
#!/usr/bin/env python3
"""
Pi 3B+ Commander - Versión Corregida
===================================
Comando mejorado para controlar Pi Zero W.
"""

import serial
import time
import logging
import os
import sys
from datetime import datetime

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class Pi3BCommander:
    """Commander mejorado para Pi 3B+."""
    
    def __init__(self):
        self.serial = None
        self.port = None
        
    def find_uart_port(self):
        """Encuentra puerto UART disponible."""
        ports = ['/dev/ttyS0', '/dev/ttyAMA0', '/dev/serial0']
        
        for port in ports:
            if os.path.exists(port) and os.access(port, os.R_OK | os.W_OK):
                logger.info(f"✅ Puerto encontrado: {port}")
                return port
        
        return None
    
    def initialize_uart(self):
        """Inicializa UART."""
        self.port = self.find_uart_port()
        
        if not self.port:
            raise Exception("No se encontró puerto UART válido")
        
        try:
            self.serial = serial.Serial(
                self.port,
                115200,
                timeout=30,  # Timeout más largo
                write_timeout=5
            )
            
            # Limpiar buffer
            self.serial.reset_input_buffer()
            self.serial.reset_output_buffer()
            
            logger.info(f"📡 UART inicializado: {self.port}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error inicializando UART: {e}")
            raise
    
    def send_command(self, command: str) -> bool:
        """Envía comando y verifica conexión."""
        try:
            logger.info(f"📤 Enviando comando: {command}")
            
            # Enviar comando
            self.serial.write(f"{command}\n".encode())
            
            # Verificar si hay respuesta inmediata (error)
            time.sleep(1)
            if self.serial.in_waiting > 0:
                response = self.serial.readline().decode().strip()
                if response.startswith("ERR"):
                    logger.error(f"❌ Error del Pi Zero: {response}")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error enviando comando: {e}")
            return False
    
    def receive_image(self) -> bool:
        """Recibe imagen del Pi Zero W."""
        try:
            logger.info("👂 Esperando header...")
            
            # Leer header con timeout
            start_time = time.time()
            header_line = ""
            
            while time.time() - start_time < 30:  # 30 segundos timeout
                if self.serial.in_waiting > 0:
                    char = self.serial.read(1).decode()
                    if char == '\n':
                        break
                    header_line += char
                time.sleep(0.1)
            
            if not header_line:
                logger.error("❌ Timeout esperando header")
                return False
            
            logger.info(f"📋 Header recibido: {header_line}")
            
            # Parsear header
            try:
                parts = header_line.split('|')
                if len(parts) != 2:
                    logger.error(f"❌ Header inválido: '{header_line}'")
                    return False
                
                timestamp = parts[0]
                size = int(parts[1])
                
                logger.info(f"📊 Imagen: {timestamp}, {size} bytes")
                
            except Exception as e:
                logger.error(f"❌ Error parseando header: {e}")
                return False
            
            # Enviar READY
            self.serial.write(b"READY\n")
            logger.info("✅ READY enviado")
            
            # Recibir datos
            received_data = bytearray()
            chunk_size = 256
            
            while len(received_data) < size:
                # Calcular bytes a leer
                bytes_to_read = min(chunk_size, size - len(received_data))
                
                # Leer chunk con timeout
                start_time = time.time()
                chunk = b""
                
                while len(chunk) < bytes_to_read and time.time() - start_time < 10:
                    remaining = bytes_to_read - len(chunk)
                    data = self.serial.read(remaining)
                    if data:
                        chunk += data
                    else:
                        time.sleep(0.01)
                
                if len(chunk) != bytes_to_read:
                    logger.error(f"❌ Timeout recibiendo chunk")
                    return False
                
                received_data.extend(chunk)
                
                # Enviar ACK
                self.serial.write(b"ACK\n")
                
                # Mostrar progreso
                progress = (len(received_data) * 100) // size
                if len(received_data) % (chunk_size * 10) == 0:
                    logger.info(f"📊 Progreso: {progress}%")
            
            # Enviar DONE
            self.serial.write(b"DONE\n")
            
            # Guardar imagen
            os.makedirs("data/images/received", exist_ok=True)
            filename = f"data/images/received/{timestamp}_received.jpg"
            
            with open(filename, 'wb') as f:
                f.write(received_data)
            
            logger.info(f"✅ Imagen guardada: {filename}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error recibiendo imagen: {e}")
            return False
    
    def capture_single_image(self, width: int = 800, quality: int = 4) -> bool:
        """Captura una sola imagen."""
        try:
            # Enviar comando foto
            command = f"foto {width} {quality}"
            if not self.send_command(command):
                return False
            
            # Recibir imagen
            return self.receive_image()
            
        except Exception as e:
            logger.error(f"❌ Error en captura: {e}")
            return False
    
    def cleanup(self):
        """Limpia recursos."""
        try:
            if self.serial and self.serial.is_open:
                self.serial.close()
                logger.info("🔒 Conexión UART cerrada")
        except:
            pass

def main():
    """Función principal."""
    try:
        commander = Pi3BCommander()
        
        logger.info("🚀 Pi 3B+ Commander Fixed - Iniciando...")
        
        # Inicializar
        commander.initialize_uart()
        
        logger.info("📸 Pi 3B+ → Pi Zero W (Captura única)")
        
        # Capturar imagen
        success = commander.capture_single_image(width=800, quality=5)
        
        if success:
            logger.info("🎉 ¡Captura exitosa!")
        else:
            logger.error("❌ Error en captura")
            
    except Exception as e:
        logger.error(f"❌ Error fatal: {e}")
    finally:
        if 'commander' in locals():
            commander.cleanup()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$script_dir/pi3b_commander_fixed.py"
    success "✅ Commander Pi 3B+ mejorado creado"
}

# 7. FUNCIÓN PRINCIPAL
main() {
    echo "🔧 === DIAGNÓSTICO Y REPARACIÓN FOTO-UART ==="
    echo
    
    # Ejecutar diagnóstico
    diagnostic_complete
    echo
    
    # Preguntar si continuar con reparaciones
    read -p "¿Ejecutar reparaciones automáticas? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🛠️ === EJECUTANDO REPARACIONES ==="
        echo
        
        fix_camera_conflicts
        fix_uart_config
        test_uart_communication
        create_improved_capture_script
        create_pi3b_commander
        
        echo
        success "🎉 === REPARACIONES COMPLETADAS ==="
        echo
        
        info "📋 Scripts creados:"
        info "   Pi Zero W: ~/foto-uart-dropin/src/raspberry_pi/foto_uart_fixed.py"
        info "   Pi 3B+:    ~/foto-uart-dropin/src/raspberry_pi/pi3b_commander_fixed.py"
        echo
        
        info "🚀 Comandos para probar:"
        info "   Pi Zero W: python3 ~/foto-uart-dropin/src/raspberry_pi/foto_uart_fixed.py"
        info "   Pi 3B+:    python3 ~/foto-uart-dropin/src/raspberry_pi/pi3b_commander_fixed.py"
        echo
        
        warn "⚠️  IMPORTANTE: Reiniciar ambas Pi para aplicar cambios de configuración"
        warn "   sudo reboot"
        
    else
        info "ℹ️  Reparaciones canceladas. Solo se ejecutó el diagnóstico."
    fi
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
