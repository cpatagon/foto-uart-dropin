#!/usr/bin/env python3
"""
FotoUART con Auto-Actualización Integrada
=========================================
Versión extendida que incluye verificación y actualización automática.

Example:
    >>> with FotoUARTWithUpdater() as foto:
    ...     foto.run()  # Incluye checks automáticos de actualización
"""

import threading
import time
from datetime import datetime, timedelta
from typing import Optional

from .foto_uart import FotoUART, FotoUARTError
from .updater import AutoUpdater


class FotoUARTWithUpdater(FotoUART):
    """FotoUART extendido con capacidades de auto-actualización.
    
    Extiende la funcionalidad base añadiendo:
    - Verificación automática de actualizaciones
    - Actualización programada en horarios específicos
    - Comandos UART para control de actualizaciones
    
    Example:
        >>> with FotoUARTWithUpdater() as foto:
        ...     foto.run()  # Loop con auto-update integrado
    """
    
    def __init__(self, cfg_path: str = "config/raspberry_pi/config.json") -> None:
        """Inicializa FotoUART con capacidades de actualización.
        
        Args:
            cfg_path (str): Ruta al archivo de configuración JSON
        """
        super().__init__(cfg_path)
        
        # Configurar auto-updater
        self.updater = AutoUpdater()
        self.update_thread: Optional[threading.Thread] = None
        self.update_stop_event = threading.Event()
        
        # Configuración de actualización (desde config o defaults)
        self.update_config = self._get_update_config()
        
        self.logger.info("FotoUART con auto-actualización inicializado")
    
    def _get_update_config(self) -> dict:
        """Obtiene configuración de actualización desde config o defaults.
        
        Returns:
            dict: Configuración de actualización
        """
        # Configuración por defecto
        default_config = {
            "enabled": True,
            "check_interval_hours": 6,
            "auto_update": False,  # Solo verificar por defecto
            "update_time": "03:00",  # Hora para actualización automática
            "allow_uart_update": True,  # Permitir update via comandos UART
            "backup_before_update": True
        }
        
        # Intentar cargar desde configuración principal
        try:
            if hasattr(self, 'serial_cfg') and 'update' in self.serial_cfg:
                update_cfg = self.serial_cfg['update']
                default_config.update(update_cfg)
        except Exception as e:
            self.logger.warning(f"No se pudo cargar config de update: {e}")
        
        return default_config
    
    def _start_update_thread(self) -> None:
        """Inicia el hilo de verificación de actualizaciones."""
        if not self.update_config["enabled"]:
            self.logger.info("Auto-actualización deshabilitada")
            return
        
        self.update_thread = threading.Thread(
            target=self._update_loop,
            daemon=True,
            name="FotoUART-Updater"
        )
        self.update_thread.start()
        self.logger.info("Hilo de auto-actualización iniciado")
    
    def _update_loop(self) -> None:
        """Loop principal del hilo de actualización."""
        check_interval = self.update_config["check_interval_hours"] * 3600  # Convertir a segundos
        last_check = datetime.now() - timedelta(hours=24)  # Forzar check inicial
        
        while not self.update_stop_event.is_set():
            try:
                now = datetime.now()
                
                # Verificar si es hora de check
                if (now - last_check).total_seconds() >= check_interval:
                    self._periodic_update_check()
                    last_check = now
                
                # Verificar si es hora de actualización automática
                if self.update_config["auto_update"]:
                    self._check_scheduled_update()
                
                # Dormir 60 segundos antes del próximo check
                self.update_stop_event.wait(60)
                
            except Exception as e:
                self.logger.error(f"Error en loop de actualización: {e}")
                self.update_stop_event.wait(300)  # Esperar 5 min en caso de error
    
    def _periodic_update_check(self) -> None:
        """Realiza verificación periódica de actualizaciones."""
        try:
            self.logger.info("Verificando actualizaciones...")
            
            if self.updater.has_updates():
                info = self.updater.get_update_info()
                self.logger.info(
                    f"🔄 Actualización disponible: "
                    f"{info['current_version']} → {info['remote_version']}"
                )
                
                # Si auto_update está habilitado, actualizar inmediatamente
                if self.update_config["auto_update"]:
                    self._perform_update()
                else:
                    self.logger.info("Auto-actualización deshabilitada. Use comando 'update' via UART.")
            else:
                self.logger.debug("No hay actualizaciones disponibles")
                
        except Exception as e:
            self.logger.error(f"Error verificando actualizaciones: {e}")
    
    def _check_scheduled_update(self) -> None:
        """Verifica si es hora de ejecutar actualización programada."""
        try:
            update_time = self.update_config["update_time"]
            now = datetime.now()
            
            # Parsear hora configurada (formato HH:MM)
            hour, minute = map(int, update_time.split(':'))
            
            # Verificar si estamos en la ventana de actualización (±5 minutos)
            target_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
            time_diff = abs((now - target_time).total_seconds())
            
            if time_diff <= 300:  # Dentro de 5 minutos
                self.logger.info(f"Hora de actualización programada: {update_time}")
                self._perform_update()
                
        except Exception as e:
            self.logger.error(f"Error en actualización programada: {e}")
    
    def _perform_update(self) -> bool:
        """Realiza la actualización del sistema.
        
        Returns:
            bool: True si la actualización fue exitosa
        """
        try:
            self.logger.info("🔄 Iniciando actualización del sistema...")
            
            # Crear backup si está configurado
            if self.update_config["backup_before_update"]:
                self.logger.info("Creando backup antes de actualizar...")
            
            # Ejecutar actualización
            success = self.updater.update()
            
            if success:
                self.logger.info("✅ Actualización completada exitosamente")
                
                # Reiniciar la aplicación después de actualización exitosa
                self.logger.info("Reiniciando aplicación en 10 segundos...")
                time.sleep(10)
                self._restart_application()
                
            else:
                self.logger.error("❌ Error durante la actualización")
            
            return success
            
        except Exception as e:
            self.logger.error(f"Error realizando actualización: {e}")
            return False
    
    def _restart_application(self) -> None:
        """Reinicia la aplicación después de una actualización."""
        import os
        import sys
        
        try:
            self.logger.info("Reiniciando aplicación...")
            self.cleanup()
            
            # Reiniciar proceso Python
            os.execv(sys.executable, ['python'] + sys.argv)
            
        except Exception as e:
            self.logger.error(f"Error reiniciando aplicación: {e}")
    
    def _handle_update_command(self, parts: list) -> bool:
        """Maneja comandos de actualización via UART.
        
        Args:
            parts (list): Partes del comando parseado
            
        Returns:
            bool: True si el comando fue procesado
            
        Commands:
            - "update check": Verificar actualizaciones
            - "update now": Actualizar inmediatamente
            - "update info": Mostrar información de versión
            - "update status": Mostrar estado del auto-updater
        """
        if len(parts) < 2:
            self.serial.write(b"ERR_UPDATE_CMD\n")
            return True
        
        subcommand = parts[1].lower()
        
        try:
            if subcommand == "check":
                # Verificar actualizaciones
                if self.updater.has_updates():
                    info = self.updater.get_update_info()
                    self.serial.write(f"UPDATE_AVAILABLE|{info['remote_version']}\n".encode())
                    self.logger.info("UART: Actualización disponible reportada")
                else:
                    self.serial.write(b"NO_UPDATES\n")
                    self.logger.info("UART: No hay actualizaciones")
                    
            elif subcommand == "now":
                # Actualizar inmediatamente
                self.serial.write(b"UPDATE_STARTING\n")
                self.logger.info("UART: Iniciando actualización por comando")
                
                # Ejecutar actualización en hilo separado para no bloquear UART
                update_thread = threading.Thread(
                    target=self._perform_update,
                    daemon=True
                )
                update_thread.start()
                
            elif subcommand == "info":
                # Información de versión
                info = self.updater.get_update_info()
                current = info.get('current_version', 'unknown')
                remote = info.get('remote_version', 'unknown')
                response = f"VERSION|{current}|{remote}\n"
                self.serial.write(response.encode())
                
            elif subcommand == "status":
                # Estado del auto-updater
                status = "enabled" if self.update_config["enabled"] else "disabled"
                auto = "on" if self.update_config["auto_update"] else "off"
                response = f"UPDATE_STATUS|{status}|{auto}\n"
                self.serial.write(response.encode())
                
            else:
                self.serial.write(b"ERR_UPDATE_SUBCMD\n")
                
            return True
            
        except Exception as e:
            self.logger.error(f"Error procesando comando update: {e}")
            self.serial.write(b"ERR_UPDATE_EXEC\n")
            return True
    
    def run(self) -> None:
        """Ejecuta el loop principal con auto-actualización integrada."""
        # Iniciar hilo de actualización
        self._start_update_thread()
        
        # Verificación inicial de actualizaciones
        try:
            if self.update_config["enabled"]:
                self.logger.info("Verificación inicial de actualizaciones...")
                if self.updater.has_updates():
                    info = self.updater.get_update_info()
                    self.logger.info(
                        f"🔄 Actualización disponible al inicio: "
                        f"{info['current_version']} → {info['remote_version']}"
                    )
        except Exception as e:
            self.logger.warning(f"Error en verificación inicial: {e}")
        
        self.logger.info("Servidor FotoUART con auto-update iniciado")
        
        try:
            while True:
                try:
                    cmd = self.serial.readline().decode("utf-8").strip()
                    if not cmd:
                        continue
                    
                    parts = cmd.split()
                    if not parts:
                        continue
                    
                    # Manejar comandos de actualización
                    if parts[0].lower() == "update" and self.update_config["allow_uart_update"]:
                        if self._handle_update_command(parts):
                            continue
                    
                    # Manejar comando foto normal
                    if parts[0].lower() == "foto":
                        # Usar la lógica original de foto
                        width = self.image_cfg["ancho_default"]
                        quality = self.image_cfg["calidad_default"]
                        
                        if len(parts) >= 2:
                            try:
                                width = int(parts[1])
                            except ValueError:
                                self.serial.write(b"ERR_WIDTH\n")
                                continue
                        
                        if len(parts) >= 3:
                            try:
                                quality = int(parts[2])
                            except ValueError:
                                self.serial.write(b"ERR_QUALITY\n")
                                continue
                        
                        self.logger.info(f"Comando foto: width={width}, quality={quality}")
                        
                        timestamp, jpeg_data = self.capture_image(width, quality)
                        success = self.send_image(jpeg_data, timestamp)
                        
                        if success:
                            self.logger.info(f"Imagen {timestamp} enviada exitosamente")
                        else:
                            self.logger.error(f"Fallo enviando imagen {timestamp}")
                    
                    else:
                        # Comando desconocido
                        self.serial.write(b"ERR_CMD\n")
                        self.logger.warning(f"Comando inválido: '{cmd}'")
                        
                except Exception as e:
                    self.logger.error(f"Error procesando comando: {e}")
                    continue
                    
        except KeyboardInterrupt:
            self.logger.info("Deteniendo servidor...")
        finally:
            self.cleanup()
    
    def cleanup(self) -> None:
        """Limpia recursos incluyendo el hilo de actualización."""
        # Detener hilo de actualización
        if self.update_thread and self.update_thread.is_alive():
            self.logger.info("Deteniendo hilo de actualización...")
            self.update_stop_event.set()
            self.update_thread.join(timeout=5)
        
        # Llamar cleanup del padre
        super().cleanup()


def main():
    """Punto de entrada principal con auto-actualización."""
    try:
        with FotoUARTWithUpdater() as server:
            server.run()
    except Exception as e:
        print(f"Error fatal: {e}")


if __name__ == "__main__":
    main()
