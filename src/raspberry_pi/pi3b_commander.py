#!/usr/bin/env python3
"""
Raspberry Pi 3B+ UART Commander - Integración para foto-uart-dropin
===================================================================
Controla Pi Zero W via UART y almacena imágenes localmente.

Compatibilidad:
- Raspberry Pi 3B+ (Commander + Storage)
- Raspberry Pi Zero W (Camera Device) 
- Protocolo UART existente del repositorio
"""

import serial
import time
import os
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple, Dict, Any
import hashlib
import shutil


class Pi3BCommander:
    """Comandante Pi 3B+ compatible con el sistema foto-uart-dropin existente."""
    
    def __init__(self, config_path: str = "config/raspberry_pi/config.json"):
        """Inicializar comandante usando configuración existente del repo."""
        self.config = self._load_existing_config(config_path)
        self._setup_logging()
        self._setup_storage()
        self._setup_uart()
        
        self.logger.info("Pi 3B+ Commander integrado con foto-uart-dropin")
    
    def _load_existing_config(self, config_path: str) -> Dict[str, Any]:
        """Cargar configuración existente y adaptarla para Pi 3B+."""
        try:
            with open(config_path, 'r') as f:
                base_config = json.load(f)
            
            # Adaptar configuración para Pi 3B+ commander
            config = {
                "serial": base_config.get("serial", {}),
                "imagen": base_config.get("imagen", {}),
                "almacenamiento": base_config.get("almacenamiento", {}),
                "procesamiento": base_config.get("procesamiento", {}),
                "limites": base_config.get("limites", {}),
                
                # Configuración específica Pi 3B+ commander
                "pi3b_commander": {
                    "enabled": True,
                    "storage_mode": "local",
                    "max_images": 500,
                    "auto_cleanup": True,
                    "web_gallery": True,
                    "backup_to_usb": False
                }
            }
            
            # Ajustar rutas para Pi 3B+ (commander almacena, no genera)
            if "directorio_fullres" in config["almacenamiento"]:
                config["almacenamiento"]["directorio_received"] = config["almacenamiento"]["directorio_fullres"].replace("fullres", "received")
            
            return config
            
        except FileNotFoundError:
            # Si no existe config, usar defaults compatibles con repo existente
            return self._get_default_config()
    
    def _get_default_config(self) -> Dict[str, Any]:
        """Configuración por defecto compatible con el repo existente."""
        return {
            "serial": {
                "puerto": "/dev/ttyS0",  # Pi 3B+ usa ttyS0
                "baudrate": 115200,
                "timeout": 30
            },
            "imagen": {
                "ancho_default": 1024,
                "calidad_default": 6,
                "chunk_size": 256,
                "ack_timeout": 15
            },
            "almacenamiento": {
                "directorio_received": "data/images/received",
                "directorio_processed": "data/images/processed", 
                "mantener_originales": True,
                "logs_dir": "data/logs"
            },
            "limites": {
                "max_jpeg_bytes": 112640,
                "fallback_quality_drop": 10
            },
            "pi3b_commander": {
                "enabled": True,
                "storage_mode": "local",
                "max_images": 500,
                "auto_cleanup": True
            }
        }
    
    def _setup_logging(self):
        """Setup logging compatible con el sistema existente."""
        log_dir = self.config["almacenamiento"]["logs_dir"]
        os.makedirs(log_dir, exist_ok=True)
        
        log_file = os.path.join(log_dir, f"pi3b_commander_{datetime.now().strftime('%Y%m%d')}.log")
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def _setup_storage(self):
        """Configurar directorios de almacenamiento."""
        storage_config = self.config["almacenamiento"]
        
        # Crear directorios
        self.received_dir = Path(storage_config["directorio_received"])
        self.processed_dir = Path(storage_config["directorio_processed"])
        self.logs_dir = Path(storage_config["logs_dir"])
        
        for directory in [self.received_dir, self.processed_dir, self.logs_dir]:
            directory.mkdir(parents=True, exist_ok=True)
        
        self.logger.info(f"Almacenamiento configurado en: {self.received_dir}")
    
    def _setup_uart(self):
        """Configurar UART usando la configuración existente."""
        serial_config = self.config["serial"]
        
        try:
            self.serial = serial.Serial(
                port=serial_config["puerto"],
                baudrate=serial_config["baudrate"],
                timeout=serial_config["timeout"],
                write_timeout=serial_config["timeout"],
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                bytesize=serial.EIGHTBITS,
                rtscts=False,
                dsrdtr=False,
                xonxoff=False
            )
            
            # Limpiar buffers
            self.serial.reset_input_buffer()
            self.serial.reset_output_buffer()
            
            self.logger.info(f"UART Pi 3B+ configurado: {serial_config['puerto']} @ {serial_config['baudrate']} bps")
            
        except Exception as e:
            self.logger.error(f"Error configurando UART: {e}")
            raise
    
    def send_foto_command(self, width: int = None, quality: int = None) -> bool:
        """Enviar comando 'foto' compatible con Pi Zero W existente."""
        imagen_config = self.config["imagen"]
        
        # Usar valores por defecto del sistema existente
        if width is None:
            width = imagen_config["ancho_default"]
        if quality is None:
            quality = imagen_config["calidad_default"]
        
        try:
            # Comando compatible con el sistema existente
            if width == imagen_config["ancho_default"] and quality == imagen_config["calidad_default"]:
                command = "foto\n"  # Comando simple
            else:
                command = f"foto {width} {quality}\n"  # Comando con parámetros
            
            self.logger.info(f"📤 Enviando comando: {command.strip()}")
            
            self.serial.write(command.encode('utf-8'))
            self.serial.flush()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error enviando comando foto: {e}")
            return False
    
    def receive_image_uart(self) -> Optional[Tuple[str, bytes, Dict[str, Any]]]:
        """Recibir imagen usando el protocolo UART existente del repo."""
        try:
            # 1. Esperar header (formato: "timestamp|size")
            self.logger.info("👂 Esperando header...")
            header_line = self.serial.readline().decode('utf-8', errors='ignore').strip()
            
            if not header_line or '|' not in header_line:
                self.logger.error(f"❌ Header inválido: '{header_line}'")
                return None
            
            # Parsear header
            timestamp, size_str = header_line.split('|', 1)
            image_size = int(size_str)
            
            self.logger.info(f"📋 Header recibido: {timestamp}, {image_size} bytes")
            
            # 2. Enviar READY (protocolo existente)
            self.serial.write(b"READY\n")
            self.serial.flush()
            self.logger.debug("✅ READY enviado")
            
            # 3. Recibir imagen en chunks con protocolo ACK/DONE
            return self._receive_chunks_existing_protocol(timestamp, image_size)
            
        except Exception as e:
            self.logger.error(f"Error recibiendo imagen: {e}")
            return None
    
    def _receive_chunks_existing_protocol(self, timestamp: str, expected_size: int) -> Optional[Tuple[str, bytes, Dict[str, Any]]]:
        """Recibir chunks usando el protocolo ACK/DONE existente."""
        try:
            image_data = b""
            chunk_size = self.config["imagen"]["chunk_size"]
            ack_timeout = self.config["imagen"]["ack_timeout"]
            
            start_time = time.time()
            chunk_count = 0
            
            self.logger.info(f"📦 Recibiendo {expected_size} bytes en chunks de {chunk_size}B...")
            
            # Recibir chunks con protocolo ACK
            while len(image_data) < expected_size:
                remaining = expected_size - len(image_data)
                to_receive = min(chunk_size, remaining)
                
                # Recibir chunk
                chunk = self.serial.read(to_receive)
                
                if not chunk:
                    self.logger.error("⏰ Timeout recibiendo chunk")
                    return None
                
                image_data += chunk
                chunk_count += 1
                
                # Enviar ACK (protocolo existente)
                self.serial.write(b"ACK\n")
                self.serial.flush()
                
                # Log progreso cada 50 chunks
                if chunk_count % 50 == 0:
                    progress = (len(image_data) * 100) // expected_size
                    self.logger.info(f"📊 Progreso: {progress}% ({len(image_data)}/{expected_size} bytes)")
            
            # 4. Esperar DONE (protocolo existente)
            done_response = self.serial.readline().decode('utf-8', errors='ignore').strip()
            
            if done_response != "DONE":
                self.logger.warning(f"⚠️ Respuesta inesperada: '{done_response}' (esperaba 'DONE')")
            
            # 5. Enviar confirmación final
            self.serial.write(b"OK\n")
            self.serial.flush()
            
            transfer_time = time.time() - start_time
            speed_kbps = (len(image_data) / 1024) / transfer_time if transfer_time > 0 else 0
            
            metadata = {
                "timestamp": timestamp,
                "size_bytes": len(image_data),
                "expected_size": expected_size,
                "chunks_received": chunk_count,
                "transfer_time_seconds": round(transfer_time, 2),
                "speed_kbps": round(speed_kbps, 1),
                "checksum": hashlib.md5(image_data).hexdigest(),
                "source_device": "PiZeroW",
                "commander_device": "Pi3B+",
                "protocol": "UART_READY_ACK_DONE"
            }
            
            self.logger.info(f"✅ Imagen recibida: {len(image_data)} bytes en {transfer_time:.2f}s ({speed_kbps:.1f} KB/s)")
            
            return timestamp, image_data, metadata
            
        except Exception as e:
            self.logger.error(f"Error en recepción de chunks: {e}")
            return None
    
    def store_received_image(self, timestamp: str, image_data: bytes, metadata: Dict[str, Any]) -> bool:
        """Almacenar imagen recibida con metadatos."""
        try:
            # Guardar imagen
            image_filename = f"{timestamp}_received.jpg"
            image_path = self.received_dir / image_filename
            
            with open(image_path, 'wb') as f:
                f.write(image_data)
            
            # Guardar metadatos JSON
            metadata_filename = f"{timestamp}_metadata.json"
            metadata_path = self.received_dir / metadata_filename
            
            # Enriquecer metadatos
            metadata.update({
                "stored_at": datetime.now().isoformat(),
                "filename": image_filename,
                "file_path": str(image_path),
                "file_size_kb": round(len(image_data) / 1024, 2),
                "storage_device": "Pi3B+",
                "repo_version": "foto-uart-dropin-v2.0"
            })
            
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            self.logger.info(f"💾 Imagen almacenada: {image_path} ({len(image_data)/1024:.1f} KB)")
            
            # Auto-cleanup si está habilitado
            self._cleanup_old_images()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error almacenando imagen: {e}")
            return False
    
    def _cleanup_old_images(self):
        """Limpiar imágenes antiguas según configuración."""
        if not self.config["pi3b_commander"]["auto_cleanup"]:
            return
        
        max_images = self.config["pi3b_commander"]["max_images"]
        
        try:
            # Obtener imágenes ordenadas por fecha
            image_files = list(self.received_dir.glob("*_received.jpg"))
            image_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            # Eliminar las más antiguas
            for old_image in image_files[max_images:]:
                # También eliminar metadatos asociados
                timestamp = old_image.stem.replace("_received", "")
                metadata_file = self.received_dir / f"{timestamp}_metadata.json"
                
                old_image.unlink(missing_ok=True)
                metadata_file.unlink(missing_ok=True)
                
                self.logger.debug(f"🗑️ Imagen antigua eliminada: {old_image.name}")
                
        except Exception as e:
            self.logger.warning(f"Error en cleanup: {e}")
    
    def capture_and_store(self, width: int = None, quality: int = None) -> bool:
        """Proceso completo: comando + recepción + almacenamiento."""
        try:
            self.logger.info("🎬 Iniciando captura Pi Zero W desde Pi 3B+...")
            
            # 1. Enviar comando foto
            if not self.send_foto_command(width, quality):
                return False
            
            # 2. Recibir imagen
            result = self.receive_image_uart()
            if not result:
                return False
            
            timestamp, image_data, metadata = result
            
            # 3. Almacenar
            if self.store_received_image(timestamp, image_data, metadata):
                self.logger.info(f"🎉 Captura exitosa: {timestamp}")
                return True
            else:
                return False
                
        except Exception as e:
            self.logger.error(f"Error en captura completa: {e}")
            return False
    
    def get_storage_info(self) -> Dict[str, Any]:
        """Información del almacenamiento local."""
        try:
            image_files = list(self.received_dir.glob("*_received.jpg"))
            
            if not image_files:
                return {
                    "total_images": 0,
                    "total_size_mb": 0,
                    "storage_dir": str(self.received_dir),
                    "last_capture": None
                }
            
            total_size = sum(f.stat().st_size for f in image_files)
            latest_image = max(image_files, key=lambda x: x.stat().st_mtime)
            
            return {
                "total_images": len(image_files),
                "total_size_mb": round(total_size / (1024 * 1024), 2),
                "latest_image": latest_image.name,
                "latest_timestamp": datetime.fromtimestamp(latest_image.stat().st_mtime).isoformat(),
                "storage_dir": str(self.received_dir),
                "cleanup_enabled": self.config["pi3b_commander"]["auto_cleanup"],
                "max_images": self.config["pi3b_commander"]["max_images"]
            }
            
        except Exception as e:
            return {"error": str(e)}
    
    def close(self):
        """Cerrar recursos."""
        try:
            if hasattr(self, 'serial') and self.serial.is_open:
                self.serial.close()
                self.logger.info("🔒 Conexión UART cerrada")
        except Exception as e:
            self.logger.error(f"Error cerrando: {e}")
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


def main():
    """CLI para Pi 3B+ Commander."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Pi 3B+ UART Commander - foto-uart-dropin")
    parser.add_argument("--width", type=int, help="Ancho imagen")
    parser.add_argument("--quality", type=int, help="Calidad 1-10")
    parser.add_argument("--continuous", action="store_true", help="Modo continuo")
    parser.add_argument("--interval", type=int, default=30, help="Intervalo en segundos")
    parser.add_argument("--info", action="store_true", help="Info almacenamiento")
    
    args = parser.parse_args()
    
    try:
        with Pi3BCommander() as commander:
            
            if args.info:
                info = commander.get_storage_info()
                print("📊 Almacenamiento Pi 3B+:")
                print(f"   📁 Directorio: {info['storage_dir']}")
                print(f"   📷 Imágenes: {info['total_images']}")
                print(f"   💾 Tamaño: {info['total_size_mb']} MB")
                if info.get('latest_image'):
                    print(f"   🕐 Última: {info['latest_image']}")
                return
            
            if args.continuous:
                print(f"🔄 Modo continuo: captura cada {args.interval}s")
                print("💡 Ctrl+C para detener")
                
                count = 0
                while True:
                    count += 1
                    print(f"\n📸 Captura #{count}")
                    
                    if commander.capture_and_store(args.width, args.quality):
                        print("✅ Éxito")
                    else:
                        print("❌ Error")
                    
                    time.sleep(args.interval)
            else:
                print("📸 Pi 3B+ → Pi Zero W (Captura única)")
                if commander.capture_and_store(args.width, args.quality):
                    print("✅ Imagen capturada y almacenada")
                else:
                    print("❌ Error en captura")
    
    except KeyboardInterrupt:
        print("\n👋 Detenido")
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    main()
