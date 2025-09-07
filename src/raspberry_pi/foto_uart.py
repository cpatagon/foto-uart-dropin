#!/usr/bin/env python3
"""
Sistema de Captura y Transmisión de Imágenes via UART
====================================================
Versión mejorada del sistema original con documentación Google Style,
configuración flexible, logging avanzado y manejo robusto de errores.

Este módulo implementa un sistema completo para capturar imágenes con Raspberry Pi
y transmitirlas via UART a un ESP32 usando un protocolo de handshake robusto.

Example:
    Uso básico del sistema:
    
        $ python3 -m src.raspberry_pi.foto_uart
        
    O para uso programático:
    
        >>> from src.raspberry_pi.foto_uart import FotoUART
        >>> with FotoUART("config/raspberry_pi/config.json") as foto:
        ...     foto.run()

Author:
    Basado en el proyecto original de Alejandro Rebolledo
    Mejorado con documentación Google Style y características avanzadas
"""

import json
import os
import logging
from datetime import datetime
from typing import Tuple, Optional, Dict, Any
import serial
import cv2
import numpy as np
from picamera2 import Picamera2


def clamp(val: float, min_val: float, max_val: float) -> float:
    """Limita un valor entre los límites especificados.
    
    Args:
        val (float): Valor a limitar
        min_val (float): Valor mínimo permitido
        max_val (float): Valor máximo permitido
        
    Returns:
        float: Valor limitado entre min_val y max_val
    """
    return max(min_val, min(max_val, val))


class FotoUARTError(Exception):
    """Excepción base para errores del sistema FotoUART."""
    pass


class CameraError(FotoUARTError):
    """Excepción específica para errores de cámara."""
    pass


class SerialError(FotoUARTError):
    """Excepción específica para errores de comunicación serie."""
    pass


class ImageProcessingError(FotoUARTError):
    """Excepción específica para errores de procesamiento de imagen."""
    pass


class FotoUART:
    """Sistema de captura y transmisión de imágenes via UART.
    
    Esta clase encapsula toda la funcionalidad necesaria para:
    - Configuración desde archivo JSON
    - Captura de imágenes con Picamera2  
    - Procesamiento avanzado (CLAHE, Unsharp Mask)
    - Transmisión robusta via UART con protocolo de handshake
    - Logging detallado de operaciones
    """
    
    def __init__(self, cfg_path: str = "config/raspberry_pi/config.json") -> None:
        """Inicializa el sistema FotoUART con configuración desde JSON."""
        self._load_config(cfg_path)
        self._setup_logging()
        self._setup_directories()
        self._setup_serial()
        self._setup_camera()
        
        self.logger.info("FotoUART inicializado correctamente")

    def _load_config(self, cfg_path: str) -> None:
        """Carga y valida la configuración desde archivo JSON."""
        try:
            with open(cfg_path) as f:
                cfg = json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Archivo de configuración no encontrado: {cfg_path}")
        except json.JSONDecodeError as e:
            raise json.JSONDecodeError(f"Error parseando JSON: {e}", e.doc, e.pos)
        
        # Validar secciones requeridas
        required_sections = ["serial", "imagen", "almacenamiento", "procesamiento", "limites"]
        missing = [section for section in required_sections if section not in cfg]
        if missing:
            raise ValueError(f"Secciones faltantes en configuración: {missing}")
        
        self.serial_cfg = cfg["serial"]
        self.image_cfg = cfg["imagen"]
        self.storage_cfg = cfg["almacenamiento"]
        self.proc_cfg = cfg["procesamiento"]
        self.limits_cfg = cfg["limites"]

    def _setup_logging(self) -> None:
        """Configura el sistema de logging con rotación diaria."""
        try:
            os.makedirs(self.storage_cfg["logs_dir"], exist_ok=True)
            log_file = os.path.join(
                self.storage_cfg["logs_dir"], 
                f"foto_uart_{datetime.now().strftime('%Y%m%d')}.log"
            )
            
            logging.basicConfig(
                level=logging.INFO,
                format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                handlers=[
                    logging.FileHandler(log_file, encoding='utf-8'),
                    logging.StreamHandler()
                ]
            )
            self.logger = logging.getLogger(__name__)
            
        except OSError as e:
            raise OSError(f"Error configurando logging: {e}")

    def _setup_directories(self) -> None:
        """Crea todos los directorios necesarios para el funcionamiento."""
        dirs = [
            self.storage_cfg["directorio_fullres"],
            self.storage_cfg["directorio_enhanced"],
            self.storage_cfg["logs_dir"]
        ]
        
        try:
            for directory in dirs:
                os.makedirs(directory, exist_ok=True)
                self.logger.debug(f"Directorio verificado: {directory}")
        except OSError as e:
            raise OSError(f"Error creando directorios: {e}")

    def _setup_serial(self) -> None:
        """Inicializa la comunicación serie."""
        try:
            self.serial = serial.Serial(
                self.serial_cfg["puerto"],
                self.serial_cfg["baudrate"],
                timeout=self.serial_cfg["timeout"]
            )
            self.logger.info(
                f"Puerto serie {self.serial_cfg['puerto']} "
                f"abierto a {self.serial_cfg['baudrate']} bps"
            )
        except serial.SerialException as e:
            raise SerialError(f"Error abriendo puerto serie: {e}")

    def _setup_camera(self) -> None:
        """Inicializa y configura la cámara Picamera2."""
        try:
            self.cam = Picamera2()
            config = self.cam.create_still_configuration()
            self.cam.configure(config)
            self.cam.start()
            self.logger.info("Cámara inicializada correctamente")
        except Exception as e:
            raise CameraError(f"Error inicializando cámara: {e}")

    def _validate_params(self, width: int, quality: int) -> Tuple[int, int]:
        """Valida y ajusta los parámetros de captura de imagen."""
        validated_width = int(clamp(width, 320, 4096))
        validated_quality = int(clamp(quality, 1, 10))
        
        if validated_width != width:
            self.logger.warning(f"Ancho ajustado de {width} a {validated_width}")
        if validated_quality != quality:
            self.logger.warning(f"Calidad ajustada de {quality} a {validated_quality}")
            
        return validated_width, validated_quality

    def _apply_image_enhancements(self, image: np.ndarray) -> np.ndarray:
        """Aplica mejoras configurables a la imagen."""
        if not self.proc_cfg["aplicar_mejoras"]:
            return image
        
        enhanced = image.copy()
        
        # CLAHE
        if self.proc_cfg["clahe_enabled"]:
            lab = cv2.cvtColor(enhanced, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
            cl = clahe.apply(l)
            lab = cv2.merge((cl, a, b))
            enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
            self.logger.debug("CLAHE aplicado")
        
        # Unsharp Mask
        if self.proc_cfg["unsharp_mask"]:
            gaussian = cv2.GaussianBlur(enhanced, (9,9), 10.0)
            enhanced = cv2.addWeighted(enhanced, 1.5, gaussian, -0.5, 0)
            self.logger.debug("Unsharp mask aplicado")
        
        return enhanced

    def _encode_with_size_limit(self, image: np.ndarray, base_quality: int) -> bytes:
        """Codifica imagen respetando límites de tamaño configurados."""
        max_bytes = self.limits_cfg["max_jpeg_bytes"]
        quality_drop = self.limits_cfg["fallback_quality_drop"]
        
        jpeg_quality = int(clamp(base_quality, 1, 10) * 10)
        encode_params = [int(cv2.IMWRITE_JPEG_QUALITY), jpeg_quality]
        
        if self.image_cfg.get("jpeg_progressive", False):
            encode_params.extend([int(cv2.IMWRITE_JPEG_PROGRESSIVE), 1])
        
        attempts = 0
        while jpeg_quality >= 10:
            attempts += 1
            success, encoded = cv2.imencode('.jpg', image, encode_params)
            if not success:
                raise ImageProcessingError("Error en codificación JPEG")
                
            data = encoded.tobytes()
            if len(data) <= max_bytes:
                self.logger.info(
                    f"Imagen codificada: {len(data)} bytes, calidad: {jpeg_quality}% "
                    f"(intento {attempts})"
                )
                return data
            else:
                jpeg_quality -= quality_drop
                encode_params[1] = int(jpeg_quality)
                self.logger.warning(
                    f"Imagen muy grande ({len(data)} bytes), "
                    f"reduciendo calidad a {jpeg_quality}%"
                )
        
        # Calidad mínima como último recurso
        encode_params[1] = 10
        success, encoded = cv2.imencode('.jpg', image, encode_params)
        if success:
            return encoded.tobytes()
        else:
            raise ImageProcessingError("Error codificando imagen JPEG con calidad mínima")

    def capture_image(self, width: int, quality: int) -> Tuple[str, bytes]:
        """Captura y procesa una imagen con los parámetros especificados."""
        width, quality = self._validate_params(width, quality)
        
        try:
            # Capturar imagen raw
            img = self.cam.capture_array()
            h, w = img.shape[:2]
            
            # Redimensionar manteniendo aspecto
            new_w = width
            new_h = int(h * width / w)
            resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
            
            # Aplicar mejoras
            enhanced = self._apply_image_enhancements(resized)
            
            # Generar timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Guardar full resolution si configurado
            if self.storage_cfg["mantener_originales"]:
                fullres_path = os.path.join(
                    self.storage_cfg["directorio_fullres"],
                    f"{timestamp}_fullres.jpg"
                )
                cv2.imwrite(fullres_path, img, [int(cv2.IMWRITE_JPEG_QUALITY), 100])
                self.logger.debug(f"Imagen full-res guardada: {fullres_path}")
            
            # Codificar imagen mejorada
            jpeg_data = self._encode_with_size_limit(enhanced, quality)
            
            # Guardar versión procesada
            enhanced_path = os.path.join(
                self.storage_cfg["directorio_enhanced"],
                f"{timestamp}_enhanced.jpg"
            )
            with open(enhanced_path, "wb") as f:
                f.write(jpeg_data)
            
            self.logger.info(
                f"Imagen capturada: {width}x{new_h}, {len(jpeg_data)} bytes"
            )
            return timestamp, jpeg_data
            
        except Exception as e:
            raise CameraError(f"Error capturando imagen: {e}")

    def send_image(self, data: bytes, timestamp: str) -> bool:
        """Envía imagen usando protocolo UART con handshake robusto."""
        try:
            # Enviar header
            header = f"{timestamp}|{len(data)}\n"
            self.serial.write(header.encode("utf-8"))
            self.logger.debug(f"Header enviado: {header.strip()}")
            
            # Esperar READY
            response = self.serial.readline()
            if response.strip() != b"READY":
                self.logger.error(f"No se recibió READY: {response}")
                return False
            
            # Transmisión en chunks
            chunk_size = self.image_cfg["chunk_size"]
            ack_timeout = self.image_cfg["ack_timeout"]
            offset = 0
            
            while offset < len(data):
                chunk = data[offset:offset + chunk_size]
                self.serial.write(chunk)
                
                # Esperar ACK con timeout
                old_timeout = self.serial.timeout
                self.serial.timeout = ack_timeout
                ack = self.serial.readline()
                self.serial.timeout = old_timeout
                
                if ack.strip() != b"ACK":
                    # Reintento
                    self.logger.warning(f"ACK no recibido en offset {offset}, reintentando...")
                    self.serial.write(chunk)
                    self.serial.timeout = ack_timeout
                    ack = self.serial.readline()
                    self.serial.timeout = old_timeout
                    
                    if ack.strip() != b"ACK":
                        self.logger.error(f"Fallo en reintento ACK en offset {offset}")
                        return False
                
                offset += chunk_size
                
                # Log de progreso
                if offset % (chunk_size * 10) == 0:
                    progress = min(100, (offset * 100) // len(data))
                    self.logger.debug(f"Progreso: {progress}%")
            
            # Esperar DONE final
            done_response = self.serial.readline()
            if done_response.strip() == b"DONE":
                self.logger.info(f"Transmisión completada: {len(data)} bytes")
                return True
            else:
                self.logger.error(f"No se recibió DONE final: {done_response}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error enviando imagen: {e}")
            return False

    def run(self) -> None:
        """Ejecuta el loop principal del servidor."""
        self.logger.info("Servidor FotoUART iniciado, esperando comandos...")
        
        try:
            while True:
                try:
                    cmd = self.serial.readline().decode("utf-8").strip()
                    if not cmd:
                        continue
                    
                    parts = cmd.split()
                    if not parts or parts[0].lower() != "foto":
                        self.serial.write(b"ERR_CMD\n")
                        self.logger.warning(f"Comando inválido: '{cmd}'")
                        continue
                    
                    # Parámetros por defecto
                    width = self.image_cfg["ancho_default"]
                    quality = self.image_cfg["calidad_default"]
                    
                    # Parsear ancho opcional
                    if len(parts) >= 2:
                        try:
                            width = int(parts[1])
                        except ValueError:
                            self.serial.write(b"ERR_WIDTH\n")
                            continue
                    
                    # Parsear calidad opcional
                    if len(parts) >= 3:
                        try:
                            quality = int(parts[2])
                        except ValueError:
                            self.serial.write(b"ERR_QUALITY\n")
                            continue
                    
                    self.logger.info(f"Comando foto: width={width}, quality={quality}")
                    
                    # Capturar y enviar
                    timestamp, jpeg_data = self.capture_image(width, quality)
                    success = self.send_image(jpeg_data, timestamp)
                    
                    if success:
                        self.logger.info(f"Imagen {timestamp} enviada exitosamente")
                    else:
                        self.logger.error(f"Fallo enviando imagen {timestamp}")
                        
                except Exception as e:
                    self.logger.error(f"Error procesando comando: {e}")
                    continue
                    
        except KeyboardInterrupt:
            self.logger.info("Deteniendo servidor...")
        finally:
            self.cleanup()

    def cleanup(self) -> None:
        """Libera todos los recursos del sistema de forma segura."""
        try:
            if hasattr(self, 'cam') and self.cam:
                self.cam.stop()
                self.logger.debug("Cámara detenida")
                
            if hasattr(self, 'serial') and self.serial.is_open:
                self.serial.close()
                self.logger.debug("Puerto serie cerrado")
                
            if hasattr(self, 'logger'):
                for handler in self.logger.handlers[:]:
                    handler.close()
                    self.logger.removeHandler(handler)
                
            print("Recursos liberados correctamente")
            
        except Exception as e:
            print(f"Error durante cleanup: {e}")

    def __enter__(self) -> 'FotoUART':
        """Context manager entry point."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit point."""
        self.cleanup()


def main():
    """Punto de entrada principal del programa."""
    try:
        with FotoUART() as server:
            server.run()
    except FileNotFoundError as e:
        print(f"Error de configuración: {e}")
    except json.JSONDecodeError as e:
        print(f"Error en formato JSON: {e}")
    except ValueError as e:
        print(f"Error en configuración: {e}")
    except SerialError as e:
        print(f"Error de puerto serie: {e}")
    except CameraError as e:
        print(f"Error de cámara: {e}")
    except Exception as e:
        print(f"Error fatal: {e}")


if __name__ == "__main__":
    main()
